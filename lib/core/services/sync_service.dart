import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
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
    } else {
      // Conflict resolution: Last-Write-Wins
      if (remoteUpdatedAt.isAfter(localProduct.updatedAt)) {
        localProduct.name = remoteData['name'];
        localProduct.category = remoteData['category'];
        localProduct.purchasePrice = (remoteData['purchasePrice'] as num).toDouble();
        localProduct.salesPrice = (remoteData['salesPrice'] as num).toDouble();
        localProduct.remoteImageUrl = remoteData['remoteImageUrl'];
        localProduct.updatedAt = remoteUpdatedAt;
        localProduct.updatedBy = remoteData['updatedBy'];
        localProduct.syncStatus = SyncStatus.synced;
        await db.saveProduct(localProduct);
      }
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
          product.updatedBy = _auth.currentUser!.uid;
          product.updatedAt = DateTime.now();
          await _firestore
              .collection('products')
              .doc(product.uuid)
              .set(product.toFirestore())
              .timeout(const Duration(seconds: 5));

          // Update local sync status
          product.syncStatus = SyncStatus.synced;
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
