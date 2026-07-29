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

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _salesPriceController = TextEditingController();
  
  String? _selectedCategory;
  File? _imageFile;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _purchasePriceController.dispose();
    _salesPriceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70, // Compress image
        maxWidth: 800,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
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
      // Windows doesn't typically support camera well, fallback to file selection directly
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

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen ürün fotoğrafı ekleyin.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final db = ref.read(databaseServiceProvider);
      final syncService = ref.read(syncServiceProvider);
      final user = FirebaseAuth.instance.currentUser;

      // 1. Copy image to app directory for permanent offline access
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final productUuid = const Uuid().v4();
      final fileExtension = _imageFile!.path.split('.').last;
      final localImagePath = '${imagesDir.path}/$productUuid.$fileExtension';
      await _imageFile!.copy(localImagePath);

      // 2. Create Product
      final product = Product()
        ..uuid = productUuid
        ..name = _nameController.text.trim()
        ..category = _selectedCategory!
        ..purchasePrice = double.parse(_purchasePriceController.text)
        ..salesPrice = double.parse(_salesPriceController.text)
        ..localImagePath = localImagePath
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now()
        ..updatedBy = user?.displayName ?? user?.email ?? 'Bilinmeyen Kullanıcı'
        ..syncStatus = SyncStatus.pending;

      // 3. Create initial PriceHistory
      final history = PriceHistory()
        ..uuid = const Uuid().v4()
        ..productUuid = productUuid
        ..oldPurchasePrice = 0.0
        ..oldSalesPrice = 0.0
        ..newPurchasePrice = product.purchasePrice
        ..newSalesPrice = product.salesPrice
        ..changeDate = DateTime.now()
        ..changedBy = user?.displayName ?? user?.email ?? 'Bilinmeyen Kullanıcı'
        ..syncStatus = SyncStatus.pending;

      // 4. Save locally
      await db.saveProduct(product);
      await db.savePriceHistory(history);

      // 5. Trigger Sync
      syncService.syncData();

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ürün kaydedilirken hata oluştu: $e')),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categories = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Ürün Ekle'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image Picker Area
                    GestureDetector(
                      onTap: () => _showImageSourceActionSheet(context),
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: _imageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.file(_imageFile!, fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Platform.isWindows
                                        ? Icons.add_photo_alternate_rounded
                                        : Icons.photo_camera_rounded,
                                    size: 48,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    Platform.isWindows
                                        ? 'Fotoğraf Seçmek İçin Tıklayın'
                                        : 'Fotoğraf Çekmek / Seçmek İçin Tıklayın',
                                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
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
                      onPressed: _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Ürünü Kaydet',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
