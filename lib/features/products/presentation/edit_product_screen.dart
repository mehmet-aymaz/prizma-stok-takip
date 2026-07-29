import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/product.dart';
import '../../../core/models/price_history.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/services/settings_service.dart';
import 'product_detail_screen.dart'; // import productProvider

class EditProductScreen extends ConsumerStatefulWidget {
  final String productUuid;

  const EditProductScreen({super.key, required this.productUuid});

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _salesPriceController;

  String? _selectedCategory;
  File? _newImageFile;
  bool _isLoading = false;
  bool _initialized = false;
  Product? _originalProduct;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _purchasePriceController = TextEditingController();
    _salesPriceController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _purchasePriceController.dispose();
    _salesPriceController.dispose();
    super.dispose();
  }

  void _initializeValues(Product product) {
    if (_initialized) return;
    _originalProduct = product;
    _nameController.text = product.name;
    _purchasePriceController.text = product.purchasePrice.toString();
    _salesPriceController.text = product.salesPrice.toString();
    _selectedCategory = product.category;
    _initialized = true;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 800,
      );

      if (pickedFile != null) {
        setState(() {
          _newImageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fotoğraf seçilirken hata oluştu: $e')),
        );
      }
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    if (Platform.isWindows) {
      _pickImage(ImageSource.gallery);
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded),
                title: const Text('Kamera ile Çek'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Galeriden Seç'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate() || _originalProduct == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final db = ref.read(databaseServiceProvider);
      final syncService = ref.read(syncServiceProvider);
      final user = FirebaseAuth.instance.currentUser;

      final newPurchasePrice = double.parse(_purchasePriceController.text);
      final newSalesPrice = double.parse(_salesPriceController.text);
      final pricesChanged = newPurchasePrice != _originalProduct!.purchasePrice || newSalesPrice != _originalProduct!.salesPrice;

      // 1. Process image if changed
      String localImagePath = _originalProduct!.localImagePath;
      String? remoteImageUrl = _originalProduct!.remoteImageUrl;

      if (_newImageFile != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final imagesDir = Directory('${appDir.path}/images');
        if (!await imagesDir.exists()) {
          await imagesDir.create(recursive: true);
        }

        final fileExtension = _newImageFile!.path.split('.').last;
        localImagePath = '${imagesDir.path}/${_originalProduct!.uuid}.$fileExtension';
        await _newImageFile!.copy(localImagePath);
        // Reset remote URL so SyncService knows to upload this new image
        remoteImageUrl = null;
      }

      // 2. Capture old prices for history
      final double oldPurchase = _originalProduct!.purchasePrice;
      final double oldSales = _originalProduct!.salesPrice;

      // 3. Update Product
      _originalProduct!.name = _nameController.text.trim();
      _originalProduct!.category = _selectedCategory!;
      _originalProduct!.purchasePrice = newPurchasePrice;
      _originalProduct!.salesPrice = newSalesPrice;
      _originalProduct!.localImagePath = localImagePath;
      _originalProduct!.remoteImageUrl = remoteImageUrl;
      _originalProduct!.updatedAt = DateTime.now();
      _originalProduct!.updatedBy = user?.displayName ?? user?.email ?? 'Bilinmeyen Kullanıcı';
      _originalProduct!.syncStatus = SyncStatus.pending;

      await db.saveProduct(_originalProduct!);

      // 4. Create PriceHistory if prices changed
      if (pricesChanged) {
        final history = PriceHistory()
          ..uuid = const Uuid().v4()
          ..productUuid = _originalProduct!.uuid
          ..oldPurchasePrice = oldPurchase
          ..oldSalesPrice = oldSales
          ..newPurchasePrice = newPurchasePrice
          ..newSalesPrice = newSalesPrice
          ..changeDate = DateTime.now()
          ..changedBy = user?.displayName ?? user?.email ?? 'Bilinmeyen Kullanıcı'
          ..syncStatus = SyncStatus.pending;

        await db.savePriceHistory(history);
      }

      // 5. Trigger Sync
      syncService.syncData();

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ürün güncellenirken hata oluştu: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productProvider(widget.productUuid));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categories = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürünü Düzenle'),
      ),
      body: productAsync.when(
        data: (product) {
          if (product == null) {
            return const Center(child: Text('Ürün bulunamadı.'));
          }

          _initializeValues(product);

          Widget buildImageArea() {
            if (_newImageFile != null) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.file(_newImageFile!, fit: BoxFit.cover),
              );
            }
            if (product.localImagePath.isNotEmpty && File(product.localImagePath).existsSync()) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.file(File(product.localImagePath), fit: BoxFit.cover),
              );
            }
            if (product.remoteImageUrl != null && product.remoteImageUrl!.isNotEmpty) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  product.remoteImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const Center(child: Icon(Icons.broken_image_rounded, size: 48)),
                ),
              );
            }
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Platform.isWindows ? Icons.add_photo_alternate_rounded : Icons.photo_camera_rounded,
                  size: 48,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  'Fotoğraf Değiştirmek İçin Tıklayın',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            );
          }

          return _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Image Editor Area
                        GestureDetector(
                          onTap: () => _showImageSourceActionSheet(context),
                          child: Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: colorScheme.outlineVariant),
                            ),
                            child: buildImageArea(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Product Name
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Ürün Adı',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ürün adı boş bırakılamaz.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Category Dropdown
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          decoration: InputDecoration(
                            labelText: 'Kategori',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: categories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Kategori seçimi zorunludur.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Purchase Price
                        TextFormField(
                          controller: _purchasePriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Alış Fiyatı (₺)',
                            prefixText: '₺ ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Alış fiyatı boş bırakılamaz.';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Lütfen geçerli bir sayı girin.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Sales Price
                        TextFormField(
                          controller: _salesPriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Satış Fiyatı (₺)',
                            prefixText: '₺ ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Satış fiyatı boş bırakılamaz.';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Lütfen geçerli bir sayı girin.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        // Save Button
                        ElevatedButton(
                          onPressed: _updateProduct,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Değişiklikleri Kaydet',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Hata: $err')),
      ),
    );
  }
}
