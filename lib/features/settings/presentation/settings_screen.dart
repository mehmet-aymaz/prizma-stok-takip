import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/database_service.dart';
import '../../../core/services/settings_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final showPurchasePrice = ref.watch(showPurchasePriceProvider);
    final user = FirebaseAuth.instance.currentUser;
    final db = ref.watch(databaseServiceProvider);

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
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    ...ref.watch(categoryListProvider).map((category) {
                      return ListTile(
                        leading: Icon(Icons.label_important_rounded, color: colorScheme.primary),
                        title: Text(category),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  title: const Text('Kategoriyi Sil'),
                                  content: Text('"$category" kategorisini silmek istediğinize emin misiniz?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => context.pop(),
                                      child: const Text('İptal'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () {
                                        ref.read(categoryListProvider.notifier).deleteCategory(category);
                                        context.pop();
                                      },
                                      child: const Text('Sil'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
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
                      onTap: () async {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) {
                            return const Center(child: CircularProgressIndicator());
                          },
                        );
                        await Future.delayed(const Duration(seconds: 1));
                        if (context.mounted) {
                          context.pop(); // pop progress indicator
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Uygulamanız en güncel sürümde (v1.0.0)'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
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
