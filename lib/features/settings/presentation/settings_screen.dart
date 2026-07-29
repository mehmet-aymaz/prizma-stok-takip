import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:isar/isar.dart';

import '../../../core/services/database_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/services/update_service.dart';
import '../../../core/models/product.dart';
import '../../../core/models/price_history.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {

  Future<void> _exportBackup(BuildContext context, DatabaseService db) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final products = await db.getAllProducts();
      final histories = await db.isar.priceHistorys.where().findAll();

      final backupData = {
        'backupDate': DateTime.now().toIso8601String(),
        'products': products.map((p) => p.toFirestore()).toList(),
        'priceHistories': histories.map((h) => h.toFirestore()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      
      // ZIP Arsivi Olustur
      final archive = Archive();

      // backup.json dosyasini ekle
      final jsonBytes = utf8.encode(jsonString);
      archive.addFile(ArchiveFile('backup.json', jsonBytes.length, jsonBytes));

      // Resimleri ekle
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/images');
      if (await imagesDir.exists()) {
        final files = imagesDir.listSync();
        for (var file in files) {
          if (file is File) {
            final fileBytes = await file.readAsBytes();
            final fileName = file.path.split(Platform.pathSeparator).last;
            archive.addFile(ArchiveFile('images/$fileName', fileBytes.length, fileBytes));
          }
        }
      }

      // ZIP'i kodla
      final zipEncoder = ZipEncoder();
      final zipBytes = zipEncoder.encode(archive);

      if (zipBytes == null) {
        throw Exception('ZIP sikistirma hatasi.');
      }

      final tempDir = await getTemporaryDirectory();
      final backupFile = File('${tempDir.path}/prizma_yedek_${DateTime.now().millisecondsSinceEpoch}.zip');
      await backupFile.writeAsBytes(zipBytes);

      if (context.mounted) Navigator.of(context).pop();

      await Share.shareXFiles(
        [XFile(backupFile.path)],
        subject: 'Prizma Stok Takip Yedek Dosyasi (ZIP)',
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yedek aktarilirken hata olustu: $e')),
        );
      }
    }
  }

  Future<void> _importBackup(BuildContext context, DatabaseService db, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result == null || result.files.single.path == null) {
        return;
      }

      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      ArchiveFile? jsonFile;
      final List<ArchiveFile> imageFiles = [];

      for (var archiveFile in archive) {
        if (archiveFile.name == 'backup.json') {
          jsonFile = archiveFile;
        } else if (archiveFile.name.startsWith('images/')) {
          imageFiles.add(archiveFile);
        }
      }

      if (jsonFile == null) {
        throw const FormatException('Gecersiz yedek dosyasi (backup.json bulunamadi).');
      }

      final content = utf8.decode(jsonFile.content as List<int>);
      final Map<String, dynamic> data = jsonDecode(content);

      if (!data.containsKey('products') || !data.containsKey('priceHistories')) {
        throw const FormatException('Gecersiz yedek dosyasi formati.');
      }

      if (context.mounted) Navigator.of(context).pop(); // Kapat spinner

      if (!context.mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Yedegi Geri Yukle'),
          content: Text(
            'Bu islem veritabaninizdaki mevcut verilerle cakisan kayitlari guncelleyecek ve yedekteki tum resimleri cihaziniza yukleyecektir.\n\n'
            'Eklenen/Guncellenen Urun: ${(data['products'] as List).length}\n'
            'Eklenen Resim Sayisi: ${imageFiles.length}\n'
            'Eklenen Fiyat Gecmisi: ${(data['priceHistories'] as List).length}\n\n'
            'Devam etmek istiyor musunuz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Iptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Geri Yukle'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Resimleri kaydet
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      for (var imgFile in imageFiles) {
        final fileName = imgFile.name.split('/').last;
        final fileData = imgFile.content as List<int>;
        final localFile = File('${imagesDir.path}/$fileName');
        await localFile.writeAsBytes(fileData);
      }

      final List<dynamic> productsJson = data['products'];
      final List<dynamic> historiesJson = data['priceHistories'];

      await db.isar.writeTxn(() async {
        for (var pJson in productsJson) {
          final Map<String, dynamic> productMap = Map<String, dynamic>.from(pJson);
          final String uuid = productMap['uuid'];
          
          final existing = await db.getProductByUuid(uuid);
          final localImagePath = '${imagesDir.path}/$uuid.jpg';
          final localImageExists = await File(localImagePath).exists();

          if (existing == null) {
            final newProduct = Product.fromFirestore(productMap);
            newProduct.localImagePath = localImageExists ? localImagePath : '';
            newProduct.syncStatus = SyncStatus.pending;
            await db.isar.products.put(newProduct);
          } else {
            final DateTime backupUpdatedAt = DateTime.parse(productMap['updatedAt']);
            if (backupUpdatedAt.isAfter(existing.updatedAt)) {
              existing.name = productMap['name'];
              existing.category = productMap['category'];
              existing.purchasePrice = (productMap['purchasePrice'] as num).toDouble();
              existing.salesPrice = (productMap['salesPrice'] as num).toDouble();
              existing.remoteImageUrl = productMap['remoteImageUrl'];
              existing.localImagePath = localImageExists ? localImagePath : existing.localImagePath;
              existing.updatedAt = backupUpdatedAt;
              existing.updatedBy = productMap['updatedBy'];
              existing.syncStatus = SyncStatus.pending;
              await db.isar.products.put(existing);
            }
          }
        }

        for (var hJson in historiesJson) {
          final Map<String, dynamic> historyMap = Map<String, dynamic>.from(hJson);
          final String uuid = historyMap['uuid'];
          
          final existingHistory = await db.isar.priceHistorys.filter().uuidEqualTo(uuid).findFirst();
          if (existingHistory == null) {
            final newHistory = PriceHistory.fromFirestore(historyMap);
            newHistory.syncStatus = SyncStatus.pending;
            await db.isar.priceHistorys.put(newHistory);
          }
        }
      });

      if (context.mounted) Navigator.of(context).pop();

      ref.read(syncServiceProvider).syncData();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yedek (Resimler dahil) basariyla geri yuklendi! Bulut senkronizasyonu baslatildi.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yedek yuklenirken hata olustu: $e')),
        );
      }
    }
  }

  void _showEditNameDialog(BuildContext context, User? user) {
    if (user == null) return;
    final controller = TextEditingController(text: user.displayName);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Profil Adini Duzenle'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Ad Soyad',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Ad soyad bos birakilamaz.' : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Iptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                await user.updateDisplayName(controller.text.trim());
                if (context.mounted) {
                  Navigator.of(context).pop();
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profil adi basariyla guncellendi.')),
                  );
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
    final showPurchasePrice = ref.watch(showPurchasePriceProvider);
    final user = FirebaseAuth.instance.currentUser;
    final db = ref.watch(databaseServiceProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar & Profil'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Profile Card (XUI style)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: colorScheme.onPrimary.withValues(alpha: 0.2),
                    child: Icon(
                      Icons.person_rounded,
                      size: 36,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'Profil Tamamlanmamış',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onPrimary.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, color: Colors.white),
                    tooltip: 'Ad Soyad Duzenle',
                    onPressed: () => _showEditNameDialog(context, user),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Settings Header
            Text(
              'GÖRÜNÜM VE YETKİLER',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.outline,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            // Settings Options Card (XUI style)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: Icon(Icons.monetization_on_rounded, color: colorScheme.primary),
                      title: const Text('Alış Fiyatını Göster'),
                      subtitle: const Text('Ürün listesi ve detaylarında alış fiyatını görüntüler.'),
                      value: showPurchasePrice,
                      onChanged: (val) {
                        ref.read(showPurchasePriceProvider.notifier).toggleShowPurchasePrice(val);
                      },
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: Icon(Icons.palette_rounded, color: colorScheme.primary),
                      title: const Text('Tema Modu'),
                      subtitle: Text(
                        themeMode == ThemeMode.system
                            ? 'Sistem Varsayılanı'
                            : themeMode == ThemeMode.dark
                                ? 'Karanlık Tema'
                                : 'Aydınlık Tema',
                      ),
                      trailing: DropdownButton<ThemeMode>(
                        value: themeMode,
                        underline: const SizedBox(),
                        borderRadius: BorderRadius.circular(20),
                        onChanged: (ThemeMode? newMode) {
                          if (newMode != null) {
                            ref.read(themeModeProvider.notifier).setThemeMode(newMode);
                          }
                        },
                        items: const [
                          DropdownMenuItem(
                            value: ThemeMode.system,
                            child: Text('Sistem'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.light,
                            child: Text('Aydınlık'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.dark,
                            child: Text('Karanlık'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Category Management Header
            Text(
              'KATEGORİ YÖNETİMİ',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.outline,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            // Category Management Card (XUI style)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  leading: Icon(Icons.category_rounded, color: colorScheme.primary),
                  title: const Text(
                    'Kategorileri Yönet',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Kategori ekleyin, düzenleyin veya silin.'),
                  childrenPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  children: [
                    const Divider(height: 1),
                    ...ref.watch(categoryListProvider).map((category) {
                      return ListTile(
                        leading: Icon(Icons.label_important_rounded, color: colorScheme.primary),
                        title: Text(category),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, color: Colors.blue),
                              onPressed: () {
                                final editController = TextEditingController(text: category);
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      title: const Text('Kategoriyi Duzenle'),
                                      content: TextField(
                                        controller: editController,
                                        decoration: const InputDecoration(
                                          labelText: 'Yeni Kategori Adi',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text('Iptal'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            final newName = editController.text.trim();
                                            if (newName.isNotEmpty && newName != category) {
                                              ref.read(categoryListProvider.notifier).renameCategory(category, newName);
                                            }
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('Kaydet'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      title: const Text('Kategoriyi Sil'),
                                      content: Text('"$category" kategorisini silmek istediginize emin misiniz?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text('Iptal'),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () {
                                            ref.read(categoryListProvider.notifier).deleteCategory(category);
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('Sil'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(),
                    ListTile(
                      leading: Icon(Icons.add_circle_outline_rounded, color: colorScheme.primary),
                      title: const Text('Yeni Kategori Ekle'),
                      onTap: () {
                        final categoryController = TextEditingController();
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              title: const Text('Yeni Kategori'),
                              content: TextField(
                                controller: categoryController,
                                decoration: const InputDecoration(
                                  labelText: 'Kategori Adı',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => context.pop(),
                                  child: const Text('İptal'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    final name = categoryController.text.trim();
                                    if (name.isNotEmpty) {
                                      ref.read(categoryListProvider.notifier).addCategory(name);
                                    }
                                    context.pop();
                                  },
                                  child: const Text('Ekle'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // System Header
            Text(
              'SİSTEM VE GÜNCELLEME',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.outline,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            // System Options Card (XUI style)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    // Check for Updates
                    ListTile(
                      leading: Icon(Icons.system_update_rounded, color: colorScheme.primary),
                      title: const Text('Güncellemeleri Denetle'),
                      subtitle: const Text('Son uygulama sürümünü denetleyin.'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        UpdateService.checkForUpdates(context, showNoUpdateDialog: true);
                      },
                    ),
                    const Divider(height: 1, indent: 56),
                    // Database Status
                    ListTile(
                      leading: Icon(Icons.storage_rounded, color: colorScheme.primary),
                      title: const Text('Veritabanı Durumu'),
                      subtitle: const Text('Yerel veritabanı istatistiklerini görün.'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                       onTap: () async {
                        final productCount = await db.getProductsCount();
                        final historyCount = await db.getPriceHistoriesCount();
                        if (context.mounted) {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                title: const Text('Veritabanı İstatistikleri'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Toplam Kayıtlı Ürün: $productCount'),
                                    const SizedBox(height: 8),
                                    Text('Toplam Fiyat Geçmişi Kaydı: $historyCount'),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => context.pop(),
                                    child: const Text('Kapat'),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      },
                    ),
                    const Divider(height: 1, indent: 56),
                    // About
                    ListTile(
                      leading: Icon(Icons.info_outline_rounded, color: colorScheme.primary),
                      title: const Text('Hakkında'),
                      subtitle: const Text('Prizma Fiyat Takip Uygulaması v1.0.0'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: 'Prizma',
                          applicationVersion: '1.0.0',
                          applicationIcon: const Icon(Icons.dashboard_customize_rounded, size: 40),
                          children: [
                            const Text('Prizma, gelişmiş offline-first mimarili fiyat takip uygulamasıdır.'),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Yedekleme ve Kurtarma Header
            Text(
              'YEDEKLEME VE VERİ YÖNETİMİ',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.outline,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            // Yedekleme ve Kurtarma Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.backup_rounded, color: colorScheme.primary),
                      title: const Text('Verileri Yedekle (Dışa Aktar)'),
                      subtitle: const Text('Ürün ve fiyat geçmişini JSON dosyası olarak paylaşın veya kaydedin.'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _exportBackup(context, db),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: Icon(Icons.settings_backup_restore_rounded, color: colorScheme.primary),
                      title: const Text('Verileri Geri Yükle (İçe Aktar)'),
                      subtitle: const Text('JSON yedek dosyasından verileri geri yükleyin.'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _importBackup(context, db, ref),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Logout Button (XUI style)
            ElevatedButton.icon(
              onPressed: () async {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text('Çıkış Yap'),
                      content: const Text('Oturumu kapatmak istediğinize emin misiniz?'),
                      actions: [
                        TextButton(
                          onPressed: () => context.pop(),
                          child: const Text('İptal'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                            if (context.mounted) {
                              context.pop(); // close dialog
                              context.go('/login'); // go to login screen
                            }
                          },
                          child: const Text('Çıkış Yap'),
                        ),
                      ],
                    );
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50.darkenOrLighten(theme),
                foregroundColor: Colors.red,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.red.shade100),
                ),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text(
                'Oturumu Kapat',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension ColorExtension on Color {
  Color darkenOrLighten(ThemeData theme) {
    return theme.brightness == Brightness.dark ? Colors.red.withValues(alpha: 0.15) : this;
  }
}
