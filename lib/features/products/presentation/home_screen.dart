import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/product.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/services/settings_service.dart';

enum ProductSortType {
  nameAZ,
  nameZA,
  priceHighest,
  priceLowest,
  latestAdded,
  oldestAdded,
}

final selectedCategoryProvider = StateProvider<String?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');
final sortByProvider = StateProvider<ProductSortType>((ref) => ProductSortType.latestAdded);

final filteredProductsProvider = StreamProvider<List<Product>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
  final sortBy = ref.watch(sortByProvider);

  return db.watchAllProducts().map((products) {
    final list = products.where((p) {
      final matchesCategory = selectedCategory == null || p.category == selectedCategory;
      final matchesSearch = p.name.toLowerCase().contains(searchQuery);
      return matchesCategory && matchesSearch;
    }).toList();

    switch (sortBy) {
      case ProductSortType.nameAZ:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case ProductSortType.nameZA:
        list.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case ProductSortType.priceHighest:
        list.sort((a, b) => b.salesPrice.compareTo(a.salesPrice));
        break;
      case ProductSortType.priceLowest:
        list.sort((a, b) => a.salesPrice.compareTo(b.salesPrice));
        break;
      case ProductSortType.latestAdded:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case ProductSortType.oldestAdded:
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
    }
    return list;
  });
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDisplayName();
    });
  }

  void _checkDisplayName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && (user.displayName == null || user.displayName!.trim().isEmpty)) {
      _showDisplayNameDialog(user);
    }
  }

  void _showDisplayNameDialog(User user) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Profilini Tamamla'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Lütfen adınızı ve soyadınızı giriniz. Kayıt güncellemelerinde bu isim görünecektir.'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Ad Soyad',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Ad soyad girilmesi zorunludur.' : null,
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                await user.updateDisplayName(controller.text.trim());
                // Force sync update
                ref.read(syncServiceProvider).syncData();
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final syncService = ref.watch(syncServiceProvider);

    final selectedCategory = ref.watch(selectedCategoryProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final sortBy = ref.watch(sortByProvider);
    final productsAsync = ref.watch(filteredProductsProvider);
    final categories = ref.watch(categoryListProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.dashboard_customize_rounded),
            const SizedBox(width: 8),
            Text(
              'Prizma',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          // Connection & Sync Status Indicator
          ValueListenableBuilder<bool>(
            valueListenable: syncService.isConnected,
            builder: (context, isConnected, child) {
              return ValueListenableBuilder<bool>(
                valueListenable: syncService.isSyncing,
                builder: (context, isSyncing, child) {
                  if (isSyncing) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  return Tooltip(
                    message: isConnected ? 'Çevrimiçi - Senkronize' : 'Çevrimdışı',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Icon(
                        isConnected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                        color: isConnected ? Colors.green : Colors.orange,
                      ),
                    ),
                  );
                },
              );
            },
          ),
          IconButton(
            tooltip: 'Ayarlar',
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar (XUI Style)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Ürün ara...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () => ref.read(searchQueryProvider.notifier).state = '',
                        )
                      : null,
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                onChanged: (val) => ref.read(searchQueryProvider.notifier).state = val,
              ),
            ),
          ),
          // Category & Sorting Dropdowns (XUI Style)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                // Category Dropdown
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: DropdownButtonFormField<String?>(
                      initialValue: selectedCategory,
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(20),
                      dropdownColor: theme.cardColor,
                      decoration: InputDecoration(
                        labelText: 'Kategori',
                        filled: true,
                        fillColor: theme.cardColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5), width: 1.5),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            'Tüm Kategoriler',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ...categories.map((c) {
                          return DropdownMenuItem<String?>(
                            value: c,
                            child: Text(
                              c,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        ref.read(selectedCategoryProvider.notifier).state = val;
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Sorting Dropdown
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: DropdownButtonFormField<ProductSortType>(
                      initialValue: sortBy,
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(20),
                      dropdownColor: theme.cardColor,
                      decoration: InputDecoration(
                        labelText: 'Sıralama',
                        filled: true,
                        fillColor: theme.cardColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5), width: 1.5),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: ProductSortType.latestAdded,
                          child: Text('En Son Eklenen', overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: ProductSortType.oldestAdded,
                          child: Text('İlk Eklenen', overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: ProductSortType.nameAZ,
                          child: Text('A-Z (İsim)', overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: ProductSortType.nameZA,
                          child: Text('Z-A (İsim)', overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: ProductSortType.priceHighest,
                          child: Text('En Yüksek Fiyat', overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: ProductSortType.priceLowest,
                          child: Text('En Düşük Fiyat', overflow: TextOverflow.ellipsis),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(sortByProvider.notifier).state = val;
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Product List/Grid
          Expanded(
            child: productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: colorScheme.outline),
                        const SizedBox(height: 16),
                        Text(
                          'Ürün bulunamadı.',
                          style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.outline),
                        ),
                      ],
                    ),
                  );
                }

                // Responsive layout (Desktop vs Mobile)
                final double screenWidth = MediaQuery.of(context).size.width;
                int crossAxisCount = 2;
                if (screenWidth > 1200) {
                  crossAxisCount = 5;
                } else if (screenWidth > 800) {
                  crossAxisCount = 3;
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ProductCard(product: product);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Hata: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-product'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ürün Ekle'),
      ),
    );
  }
}

class ProductCard extends ConsumerWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final showPurchasePrice = ref.watch(showPurchasePriceProvider);

    Widget buildImage() {
      if (product.localImagePath.isNotEmpty) {
        final file = File(product.localImagePath);
        if (file.existsSync()) {
          return Image.file(file, fit: BoxFit.cover);
        }
      }
      if (product.remoteImageUrl != null && product.remoteImageUrl!.isNotEmpty) {
        return Image.network(
          product.remoteImageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Center(child: Icon(Icons.broken_image_rounded, size: 40)),
        );
      }
      return Container(
        color: colorScheme.surfaceContainerHighest,
        child: Icon(Icons.image_rounded, size: 48, color: colorScheme.onSurfaceVariant),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => context.push('/product-detail/${product.uuid}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  buildImage(),
                  // Sync Status Badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        product.syncStatus == SyncStatus.synced
                            ? Icons.cloud_done_rounded
                            : Icons.cloud_upload_rounded,
                        color: product.syncStatus == SyncStatus.synced ? Colors.green : Colors.orange,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    product.category,
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: showPurchasePrice
                        ? MainAxisAlignment.spaceBetween
                        : MainAxisAlignment.center,
                    children: [
                      if (showPurchasePrice)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Alış',
                              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                            ),
                            Text(
                              '₺${product.purchasePrice.toStringAsFixed(2)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      Column(
                        crossAxisAlignment: showPurchasePrice ? CrossAxisAlignment.end : CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Satış',
                            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                          ),
                          Text(
                            '₺${product.salesPrice.toStringAsFixed(2)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
