import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar/isar.dart';
import 'database_service.dart';
import 'sync_service.dart';
import '../models/product.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

// Theme Mode Notifier
class ThemeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences _prefs;
  static const _keyThemeMode = 'settings_theme_mode';

  ThemeNotifier(this._prefs) : super(_loadThemeMode(_prefs));

  static ThemeMode _loadThemeMode(SharedPreferences prefs) {
    final saved = prefs.getString(_keyThemeMode);
    if (saved == 'light') return ThemeMode.light;
    if (saved == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    String val = 'system';
    if (mode == ThemeMode.light) val = 'light';
    if (mode == ThemeMode.dark) val = 'dark';
    await _prefs.setString(_keyThemeMode, val);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeNotifier(prefs);
});

class SettingsNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  static const _keyShowPurchasePrice = 'show_purchase_price';

  SettingsNotifier(this._prefs) : super(_prefs.getBool(_keyShowPurchasePrice) ?? true);

  Future<void> toggleShowPurchasePrice(bool value) async {
    state = value;
    await _prefs.setBool(_keyShowPurchasePrice, value);
  }
}

final showPurchasePriceProvider = StateNotifierProvider<SettingsNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsNotifier(prefs);
});

class CategoryNotifier extends StateNotifier<List<String>> {
  final SharedPreferences _prefs;
  final Ref _ref;
  static const _keyCategories = 'custom_categories';
  static const List<String> _defaultCategories = [
    'Görüntü & Yayın Sistemleri',
    'Aydınlatma & Dekoratif Işık',
    'Kablo & Uzatma Ekipmanları',
    'Elektrik Tesisat & Donanım',
    'Küçük Ev Aletleri',
    'Mobil Aksesuar & Kişisel Bakım',
    'Yapı Malzemeleri & Kimyasallar',
    'Diğer Elektrik Malzemeleri'
  ];

  CategoryNotifier(this._prefs, this._ref) : super([]) {
    _initCategories();
  }

  void _initCategories() {
    final saved = _prefs.getStringList(_keyCategories);
    // Eski veya emojili kategorileri kullanan cihazlarda yeni temiz listeye migrasyon yapıyoruz
    if (saved == null || 
        saved.contains('Temizlik') || 
        saved.contains('Gıda') || 
        saved.isEmpty || 
        saved.any((c) => c.contains('📺') || c.contains('('))) {
      state = _defaultCategories;
      _prefs.setStringList(_keyCategories, _defaultCategories);
    } else {
      state = saved;
    }
  }

  Future<void> addCategory(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;
    if (state.any((c) => c.toLowerCase() == trimmedName.toLowerCase())) return; // No duplicates case-insensitive
    final newList = [...state, trimmedName];
    state = newList;
    await _prefs.setStringList(_keyCategories, newList);
  }

  Future<void> renameCategory(String oldName, String newName) async {
    final trimmedOld = oldName.trim();
    final trimmedNew = newName.trim();
    if (trimmedNew.isEmpty || trimmedOld == trimmedNew) return;
    if (state.any((c) => c.toLowerCase() == trimmedNew.toLowerCase() && c != trimmedOld)) return;

    final newList = state.map((c) => c == trimmedOld ? trimmedNew : c).toList();
    state = newList;
    await _prefs.setStringList(_keyCategories, newList);

    // Veritabanindaki urunlerin kategorisini guncelle
    final db = _ref.read(databaseServiceProvider);
    final syncService = _ref.read(syncServiceProvider);

    final products = await db.isar.products.filter().categoryEqualTo(trimmedOld).findAll();
    if (products.isNotEmpty) {
      await db.isar.writeTxn(() async {
        for (var p in products) {
          p.category = trimmedNew;
          p.syncStatus = SyncStatus.pending;
          p.updatedAt = DateTime.now();
          await db.isar.products.put(p);
        }
      });
      syncService.syncData();
    }
  }

  Future<void> deleteCategory(String name) async {
    final newList = state.where((c) => c != name).toList();
    state = newList;
    await _prefs.setStringList(_keyCategories, newList);
  }
}

final categoryListProvider = StateNotifierProvider<CategoryNotifier, List<String>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CategoryNotifier(prefs, ref);
});
