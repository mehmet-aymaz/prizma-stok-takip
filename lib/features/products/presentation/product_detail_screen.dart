import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/product.dart';
import '../../../core/models/price_history.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/services/settings_service.dart';

final productProvider = StreamProvider.family<Product?, String>((ref, uuid) {
  final db = ref.watch(databaseServiceProvider);
  return db.isar.products
      .filter()
      .uuidEqualTo(uuid)
      .watch(fireImmediately: true)
      .map((list) => list.firstOrNull);
});

final priceHistoryProvider = StreamProvider.family<List<PriceHistory>, String>((ref, uuid) {
  final db = ref.watch(databaseServiceProvider);
  return db.watchPriceHistory(uuid);
});

class ProductDetailScreen extends ConsumerWidget {
  final String productUuid;

  const ProductDetailScreen({super.key, required this.productUuid});

  void _deleteProduct(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ürünü Sil'),
          content: const Text('Bu ürünü silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final db = ref.read(databaseServiceProvider);
                final syncService = ref.read(syncServiceProvider);

                // 1. Delete local image file if exists
                try {
                  final product = await db.getProductByUuid(productUuid);
                  if (product != null && product.localImagePath.isNotEmpty) {
                    final file = File(product.localImagePath);
                    if (await file.exists()) {
                      await file.delete();
                    }
                  }
                } catch (e) {
                  debugPrint("Local image file delete error: $e");
                }

                // 2. Delete from Isar DB
                await db.isar.writeTxn(() async {
                  await db.isar.products.filter().uuidEqualTo(productUuid).deleteAll();
                  await db.isar.priceHistorys.filter().productUuidEqualTo(productUuid).deleteAll();
                });

                // 3. Delete from Firebase (Firestore & Storage)
                try {
                  // Firestore will delete locally and queue for remote sync if offline
                  await FirebaseFirestore.instance.collection('products').doc(productUuid).delete();
                  
                  if (syncService.isConnected.value) {
                    try {
                      await FirebaseStorage.instance.ref().child('products/$productUuid.jpg').delete();
                    } catch (storageErr) {
                      debugPrint("Storage image delete error: $storageErr");
                    }
                  }
                } catch (e) {
                  debugPrint("Firestore/Storage delete error: $e");
                }

                if (context.mounted) {
                  context.go('/home');
                }
              },
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productProvider(productUuid));
    final historyAsync = ref.watch(priceHistoryProvider(productUuid));
    final showPurchasePrice = ref.watch(showPurchasePriceProvider);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return productAsync.when(
      data: (product) {
        if (product == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Ürün Detayı')),
            body: const Center(child: Text('Ürün bulunamadı.')),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text(product.name),
              actions: [
                IconButton(
                  tooltip: 'Sil',
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  onPressed: () => _deleteProduct(context, ref),
                ),
                IconButton(
                  tooltip: 'Düzenle',
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () => context.push('/edit-product/${product.uuid}'),
                ),
              ],
            ),
            body: Column(
              children: [
                // Product Header (Image & Main Pricing)
                Container(
                  padding: const EdgeInsets.all(16.0),
                  color: colorScheme.surfaceContainerHighest.withAlpha(80),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 120,
                          height: 120,
                          child: product.localImagePath.isNotEmpty && File(product.localImagePath).existsSync()
                              ? Image.file(File(product.localImagePath), fit: BoxFit.cover)
                              : product.remoteImageUrl != null
                                  ? Image.network(
                                      product.remoteImageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => const Icon(Icons.broken_image_rounded, size: 40),
                                    )
                                  : Container(
                                      color: colorScheme.surfaceContainerHighest,
                                      child: const Icon(Icons.image_rounded, size: 40),
                                    ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Current Prices
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Chip(
                              label: Text(product.category),
                              visualDensity: VisualDensity.compact,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (showPurchasePrice) ...[
                                  _PriceBox(
                                    title: 'Alış',
                                    price: product.purchasePrice,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 16),
                                ],
                                _PriceBox(
                                  title: 'Satış',
                                  price: product.salesPrice,
                                  color: Colors.green,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // TabBar
                const TabBar(
                  tabs: [
                    Tab(text: 'Detaylar', icon: Icon(Icons.info_outline_rounded)),
                    Tab(text: 'Fiyat Geçmişi', icon: Icon(Icons.history_rounded)),
                  ],
                ),
                // TabBarView
                Expanded(
                  child: TabBarView(
                    children: [
                      // Details Tab
                      ListView(
                        padding: const EdgeInsets.all(16.0),
                        children: [
                          _DetailRow(title: 'Kategori', value: product.category),
                          _DetailRow(
                            title: 'Eklenme Tarihi',
                            value: '${product.createdAt.day}.${product.createdAt.month}.${product.createdAt.year} ${product.createdAt.hour}:${product.createdAt.minute.toString().padLeft(2, '0')}',
                          ),
                          _DetailRow(
                            title: 'Son Güncelleme',
                            value: '${product.updatedAt.day}.${product.updatedAt.month}.${product.updatedAt.year} ${product.updatedAt.hour}:${product.updatedAt.minute.toString().padLeft(2, '0')}',
                          ),
                          _DetailRow(
                            title: 'Son Güncelleyen (UID)',
                            value: product.updatedBy.isEmpty ? 'Bilinmiyor' : product.updatedBy,
                          ),
                          _DetailRow(
                            title: 'Senkronizasyon Durumu',
                            value: product.syncStatus == SyncStatus.synced ? 'Bulut ile Eşleşti' : 'Yerel (Senkronizasyon Bekliyor)',
                            valueColor: product.syncStatus == SyncStatus.synced ? Colors.green : Colors.orange,
                          ),
                        ],
                      ),
                      // Price History Tab
                      historyAsync.when(
                        data: (histories) {
                          if (histories.isEmpty) {
                            return const Center(child: Text('Fiyat geçmişi bulunmuyor.'));
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: histories.length,
                            itemBuilder: (context, index) {
                              final history = histories[index];
                              return _HistoryItem(history: history);
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, stack) => Center(child: Text('Geçmiş yüklenirken hata: $err')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Hata: $err'))),
    );
  }
}

class _PriceBox extends StatelessWidget {
  final String title;
  final double price;
  final Color color;

  const _PriceBox({required this.title, required this.price, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.bodySmall),
        Text(
          '₺${price.toStringAsFixed(2)}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String title;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.title, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
          const Divider(height: 24),
        ],
      ),
    );
  }
}

class _HistoryItem extends ConsumerWidget {
  final PriceHistory history;

  const _HistoryItem({required this.history});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final showPurchasePrice = ref.watch(showPurchasePriceProvider);

    String formatDateTime(DateTime dt) {
      return '${dt.day}.${dt.month}.${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatDateTime(history.changeDate),
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                ),
                Icon(
                  history.syncStatus == SyncStatus.synced ? Icons.cloud_done_rounded : Icons.cloud_upload_rounded,
                  color: history.syncStatus == SyncStatus.synced ? Colors.green : Colors.orange,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (showPurchasePrice)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Alış Fiyat Değişimi', style: TextStyle(fontSize: 12)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text('₺${history.oldPurchasePrice.toStringAsFixed(2)}', style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)),
                            const Icon(Icons.arrow_right_alt_rounded, color: Colors.blue),
                            Text('₺${history.newPurchasePrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                          ],
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Satış Fiyat Değişimi', style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('₺${history.oldSalesPrice.toStringAsFixed(2)}', style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)),
                          const Icon(Icons.arrow_right_alt_rounded, color: Colors.green),
                          Text('₺${history.newSalesPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
