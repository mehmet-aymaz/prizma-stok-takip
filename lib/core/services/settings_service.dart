import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
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
  static const _keyCategories = 'custom_categories';
  static const List<String> _defaultCategories = [
    'Temizlik',
    'Gıda',
    'Kişisel Bakım',
    'Elektronik',
    'Diğer'
  ];

  CategoryNotifier(this._prefs) : super(_prefs.getStringList(_keyCategories) ?? _defaultCategories);

  Future<void> addCategory(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;
    if (state.any((c) => c.toLowerCase() == trimmedName.toLowerCase())) return; // No duplicates case-insensitive
    final newList = [...state, trimmedName];
    state = newList;
    await _prefs.setStringList(_keyCategories, newList);
  }

  Future<void> deleteCategory(String name) async {
    final newList = state.where((c) => c != name).toList();
    state = newList;
    await _prefs.setStringList(_keyCategories, newList);
  }
}

final categoryListProvider = StateNotifierProvider<CategoryNotifier, List<String>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CategoryNotifier(prefs);
});
