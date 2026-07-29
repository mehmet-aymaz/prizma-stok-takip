import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'database_service.dart';
import '../models/product.dart';
import '../models/price_history.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return SyncService(dbService);
});

class SyncService {
  final DatabaseService db;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription? _connectivitySubscription;
  StreamSubscription? _productsSubscription;
  StreamSubscription? _historySubscription;

  final ValueNotifier<bool> isSyncing = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isConnected = ValueNotifier<bool>(false);

  SyncService(this.db);

  void initialize() {
    // Monitor connectivity
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      final connected = result.isNotEmpty && result.first != ConnectivityResult.none;
      isConnected.value = connected;
      if (connected) {
        syncData();
        _startRemoteListeners();
      } else {
        _stopRemoteListeners();
      }
    });

    // Initial check
    Connectivity().checkConnectivity().then((result) {
      final connected = result.isNotEmpty && result.first != ConnectivityResult.none;
      isConnected.value = connected;
      if (connected) {
        syncData();
        _startRemoteListeners();
      }
    });

    // Listen to auth changes to start/stop listeners accordingly
    _auth.authStateChanges().listen((user) {
      if (user != null && isConnected.value) {
        syncData();
        _startRemoteListeners();
      } else {
        _stopRemoteListeners();
      }
    });
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _stopRemoteListeners();
  }

  void _startRemoteListeners() {
    _stopRemoteListeners();

    if (_auth.currentUser == null) return;

    // Listen remote products
    _productsSubscription = _firestore.collection('products').snapshots().listen((snapshot) async {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
          final remoteData = change.doc.data();
          if (remoteData != null) {
            await _syncRemoteProduct(remoteData);
          }
        } else if (change.type == DocumentChangeType.removed) {
          final remoteData = change.doc.data();
          if (remoteData != null) {
            final String uuid = remoteData['uuid'];
            // Clean up local image file if it exists
            try {
              final localProduct = await db.getProductByUuid(uuid);
              if (localProduct != null && localProduct.localImagePath.isNotEmpty) {
                final file = File(localProduct.localImagePath);
                if (await file.exists()) {
                  await file.delete();
                }
              }
            } catch (e) {
              debugPrint("Error deleting local image: $e");
            }
            await db.isar.writeTxn(() async {
              await db.isar.products.filter().uuidEqualTo(uuid).deleteAll();
              await db.isar.priceHistorys.filter().productUuidEqualTo(uuid).deleteAll();
            });
          }
        }
      }
    }, onError: (error) {
      debugPrint("Remote Products Subscription Error: $error");
    });

    // Listen remote price history
    _historySubscription = _firestore.collection('price_histories').snapshots().listen((snapshot) async {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final remoteData = change.doc.data();
          if (remoteData != null) {
            await _syncRemotePriceHistory(remoteData);
          }
        }
      }
    }, onError: (error) {
      debugPrint("Remote History Subscription Error: $error");
    });
  }

  void _stopRemoteListeners() {
    _productsSubscription?.cancel();
    _historySubscription?.cancel();
  }

  Future<void> _syncRemoteProduct(Map<String, dynamic> remoteData) async {
    final String uuid = remoteData['uuid'];
    final DateTime remoteUpdatedAt = DateTime.parse(remoteData['updatedAt']);

    final localProduct = await db.getProductByUuid(uuid);

    if (localProduct == null) {
      // Create local product
      final newProduct = Product.fromFirestore(remoteData);
      await db.saveProduct(newProduct);

      // Download remote image if available
      if (newProduct.remoteImageUrl != null && newProduct.remoteImageUrl!.isNotEmpty) {
        _downloadAndSetLocalImage(newProduct);
      }
    } else {
      // Conflict resolution: Last-Write-Wins
      if (remoteUpdatedAt.isAfter(localProduct.updatedAt)) {
        final oldRemoteUrl = localProduct.remoteImageUrl;
        localProduct.name = remoteData['name'];
        localProduct.category = remoteData['category'];
        localProduct.purchasePrice = (remoteData['purchasePrice'] as num).toDouble();
        localProduct.salesPrice = (remoteData['salesPrice'] as num).toDouble();
        localProduct.remoteImageUrl = remoteData['remoteImageUrl'];
        localProduct.updatedAt = remoteUpdatedAt;
        localProduct.updatedBy = remoteData['updatedBy'];
        localProduct.syncStatus = SyncStatus.synced;
        await db.saveProduct(localProduct);

        // Download remote image if it has changed or local file is missing
        if (localProduct.remoteImageUrl != null &&
            localProduct.remoteImageUrl!.isNotEmpty &&
            (localProduct.remoteImageUrl != oldRemoteUrl ||
             localProduct.localImagePath.isEmpty ||
             !File(localProduct.localImagePath).existsSync())) {
          _downloadAndSetLocalImage(localProduct);
        }
      } else {
        // Even if local product is newer, if localImagePath is empty/invalid but remoteImageUrl is available, download it.
        if (localProduct.remoteImageUrl != null &&
            localProduct.remoteImageUrl!.isNotEmpty &&
            (localProduct.localImagePath.isEmpty || !File(localProduct.localImagePath).existsSync())) {
          _downloadAndSetLocalImage(localProduct);
        }
      }
    }
  }

  Future<void> _downloadAndSetLocalImage(Product product) async {
    if (product.remoteImageUrl == null || product.remoteImageUrl!.isEmpty) return;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // Determine local path
      final localPath = '${imagesDir.path}/${product.uuid}.jpg';

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      
      final request = await client.getUrl(Uri.parse(product.remoteImageUrl!));
      final response = await request.close().timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final file = File(localPath);
        await response.pipe(file.openWrite());

        // Get fresh instance from DB to write the local path
        final dbProduct = await db.getProductByUuid(product.uuid);
        if (dbProduct != null) {
          dbProduct.localImagePath = localPath;
          await db.saveProduct(dbProduct);
          debugPrint("Resim basariyla indirildi ve yerel yol guncellendi: $localPath");
        }
      } else {
        debugPrint("Resim indirme basarisiz. Kod: ${response.statusCode}");
      }
      client.close();
    } catch (e) {
      debugPrint("Resim indirilirken hata: $e");
    }
  }

  Future<void> _syncRemotePriceHistory(Map<String, dynamic> remoteData) async {
    final String uuid = remoteData['uuid'];
    final histories = await db.isar.priceHistorys.filter().uuidEqualTo(uuid).findAll();

    if (histories.isEmpty) {
      final newHistory = PriceHistory.fromFirestore(remoteData);
      await db.savePriceHistory(newHistory);
    }
  }

  Future<void> syncData() async {
    if (_auth.currentUser == null || isSyncing.value || !isConnected.value) return;

    isSyncing.value = true;
    try {
      // 0. Upload missing images for already synced products (e.g. if Storage was not configured before)
      final missingImageProducts = await db.isar.products
          .filter()
          .localImagePathIsNotEmpty()
          .and()
          .remoteImageUrlIsNull()
          .findAll();

      for (var product in missingImageProducts) {
        final file = File(product.localImagePath);
        if (await file.exists()) {
          try {
            final storageRef = _storage.ref().child('products/${product.uuid}.jpg');
            await storageRef.putFile(file).timeout(const Duration(seconds: 15));
            final downloadUrl = await storageRef.getDownloadURL().timeout(const Duration(seconds: 5));

            product.remoteImageUrl = downloadUrl;
            await db.saveProduct(product);

            // Update remoteImageUrl in Firestore
            await _firestore
                .collection('products')
                .doc(product.uuid)
                .update({'remoteImageUrl': downloadUrl})
                .timeout(const Duration(seconds: 5));
            debugPrint("Successfully uploaded missing image for product: ${product.uuid}");
          } catch (storageError) {
            debugPrint("Failed to upload missing image for ${product.uuid}: $storageError");
          }
        }
      }

      // 1. Sync pending products (Local to Remote)
      final pendingProducts = await db.getPendingProducts();
      for (var product in pendingProducts) {
        try {
          // Upload image if it exists locally and not uploaded yet
          if (product.localImagePath.isNotEmpty && product.remoteImageUrl == null) {
            final file = File(product.localImagePath);
            if (await file.exists()) {
              try {
                final storageRef = _storage.ref().child('products/${product.uuid}.jpg');
                await storageRef.putFile(file).timeout(const Duration(seconds: 15));
                product.remoteImageUrl = await storageRef.getDownloadURL().timeout(const Duration(seconds: 5));
              } catch (storageError) {
                debugPrint("Image Upload Error for ${product.uuid}: $storageError");
              }
            }
          }

          // Save to Firestore
          if (product.updatedBy.isEmpty || product.updatedBy == _auth.currentUser!.uid) {
            product.updatedBy = _auth.currentUser!.displayName ?? _auth.currentUser!.email ?? 'Bilinmeyen Kullanıcı';
          }
          await _firestore
              .collection('products')
              .doc(product.uuid)
              .set(product.toFirestore())
              .timeout(const Duration(seconds: 5));

          // Update local sync status
          // If we had a local image to upload, but remoteImageUrl is still null, we keep it as pending so it retries.
          if (product.localImagePath.isNotEmpty && product.remoteImageUrl == null) {
            product.syncStatus = SyncStatus.pending;
          } else {
            product.syncStatus = SyncStatus.synced;
          }
          await db.saveProduct(product);
        } catch (productError) {
          debugPrint("Product Sync Error for ${product.uuid}: $productError");
        }
      }

      // 2. Sync pending price histories (Local to Remote)
      final pendingHistories = await db.getPendingPriceHistories();
      for (var history in pendingHistories) {
        try {
          await _firestore
              .collection('price_histories')
              .doc(history.uuid)
              .set(history.toFirestore())
              .timeout(const Duration(seconds: 5));
          history.syncStatus = SyncStatus.synced;
          await db.savePriceHistory(history);
        } catch (historyError) {
          debugPrint("History Sync Error for ${history.uuid}: $historyError");
        }
      }
    } catch (e) {
      debugPrint("Sync General Error: $e");
    } finally {
      isSyncing.value = false;
    }
  }
}
