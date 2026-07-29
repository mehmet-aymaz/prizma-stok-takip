import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  static const String _repoOwner = 'mehmet-aymaz';
  static const String _repoName = 'prizma-stok-takip';
  static const String _apiUrl = 'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest';

  static Future<Map<String, dynamic>?> fetchLatestRelease() async {
    try {
      final client = HttpClient();
      final uri = Uri.parse(_apiUrl);
      final request = await client.getUrl(uri);
      // GitHub API requires a User-Agent header
      request.headers.set('User-Agent', 'PrizmaStokTakipApp');
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        return json.decode(body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error fetching latest release: $e');
    }
    return null;
  }

  static bool isNewerVersion(String current, String latest) {
    final cleanCurrent = current.replaceAll(RegExp(r'^[vV]'), '');
    final cleanLatest = latest.replaceAll(RegExp(r'^[vV]'), '');

    final currentParts = cleanCurrent.split('+').first.split('.');
    final latestParts = cleanLatest.split('+').first.split('.');

    for (int i = 0; i < 3; i++) {
      final currentNum = i < currentParts.length ? int.tryParse(currentParts[i]) ?? 0 : 0;
      final latestNum = i < latestParts.length ? int.tryParse(latestParts[i]) ?? 0 : 0;
      if (latestNum > currentNum) return true;
      if (currentNum > latestNum) return false;
    }
    return false;
  }

  static Future<void> checkForUpdates(BuildContext context, {bool showNoUpdateDialog = false}) async {
    // Show loading if requested manually
    if (showNoUpdateDialog) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final latestRelease = await fetchLatestRelease();
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    if (showNoUpdateDialog && Navigator.canPop(context)) {
      Navigator.of(context).pop(); // Dismiss loading
    }

    if (latestRelease == null) {
      if (showNoUpdateDialog) {
        _showNoConnectionDialog(context);
      }
      return;
    }

    final latestVersion = latestRelease['tag_name'] as String? ?? '';
    final hasUpdate = isNewerVersion(currentVersion, latestVersion);

    if (hasUpdate) {
      if (context.mounted) {
        _showUpdateDialog(context, latestVersion, latestRelease);
      }
    } else {
      if (showNoUpdateDialog && context.mounted) {
        _showUpToDateDialog(context, currentVersion);
      }
    }
  }

  static void _showUpdateDialog(BuildContext context, String version, Map<String, dynamic> release) {
    final htmlUrl = release['html_url'] as String? ?? '';
    final assets = release['assets'] as List<dynamic>? ?? [];
    
    // Try to find the APK download link
    String? apkDownloadUrl;
    for (var asset in assets) {
      final name = asset['name'] as String? ?? '';
      if (name.endsWith('.apk')) {
        apkDownloadUrl = asset['browser_download_url'] as String?;
        break;
      }
    }
    
    final finalDownloadUrl = apkDownloadUrl ?? htmlUrl;
    final changelog = release['body'] as String? ?? 'Bu güncelleme için detaylı açıklama bulunmuyor.';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(Icons.system_update_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              const Text('Yeni Sürüm Mevcut!'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Yeni sürüm $version indirilmeye hazır.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Yenilikler:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  changelog,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Daha Sonra'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final uri = Uri.parse(finalDownloadUrl);
                if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                  // Launched download
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tarayıcı açılamadı.')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              child: const Text('Güncelle'),
            ),
          ],
        );
      },
    );
  }

  static void _showUpToDateDialog(BuildContext context, String currentVersion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green),
            const SizedBox(width: 12),
            const Text('Uygulamanız Güncel'),
          ],
        ),
        content: Text('Prizma en son sürümde (v$currentVersion). Yeni bir güncelleme bulunmuyor.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  static void _showNoConnectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.red),
            const SizedBox(width: 12),
            const Text('Bağlantı Hatası'),
          ],
        ),
        content: const Text('Güncellemeler denetlenirken bir hata oluştu. Lütfen internet bağlantınızı kontrol edin.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}
