import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/product.dart';
import '../models/price_history.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  throw UnimplementedError(); // Will be overridden in main.dart
});

class DatabaseService {
  final Isar isar;

  DatabaseService(this.isar);

  static Future<Isar> init() async {
    final dir = await getApplicationDocumentsDirectory();
    return await Isar.open(
      [ProductSchema, PriceHistorySchema],
      directory: dir.path,
    );
  }

  // Get all products sorted by name
  Future<List<Product>> getAllProducts() async {
    return await isar.products.where().sortByName().findAll();
  }

  // Stream of all products
  Stream<List<Product>> watchAllProducts() {
    return isar.products.where().sortByName().watch(fireImmediately: true);
  }

  // Get a product by UUID
  Future<Product?> getProductByUuid(String uuid) async {
    return await isar.products.filter().uuidEqualTo(uuid).findFirst();
  }

  // Save/Update product
  Future<void> saveProduct(Product product) async {
    await isar.writeTxn(() async {
      await isar.products.put(product);
    });
  }

  // Save multiple products (e.g., from sync)
  Future<void> saveProducts(List<Product> products) async {
    await isar.writeTxn(() async {
      await isar.products.putAll(products);
    });
  }

  // Get price history for a product
  Future<List<PriceHistory>> getPriceHistory(String productUuid) async {
    return await isar.priceHistorys
        .filter()
        .productUuidEqualTo(productUuid)
        .sortByChangeDateDesc()
        .findAll();
  }

  // Stream price history
  Stream<List<PriceHistory>> watchPriceHistory(String productUuid) {
    return isar.priceHistorys
        .filter()
        .productUuidEqualTo(productUuid)
        .sortByChangeDateDesc()
        .watch(fireImmediately: true);
  }

  // Save price history record
  Future<void> savePriceHistory(PriceHistory history) async {
    await isar.writeTxn(() async {
      await isar.priceHistorys.put(history);
    });
  }

  // Save multiple price histories (e.g., from sync)
  Future<void> savePriceHistories(List<PriceHistory> histories) async {
    await isar.writeTxn(() async {
      await isar.priceHistorys.putAll(histories);
    });
  }

  // Get products that are pending sync
  Future<List<Product>> getPendingProducts() async {
    return await isar.products.filter().syncStatusEqualTo(SyncStatus.pending).findAll();
  }

  // Get price histories that are pending sync
  Future<List<PriceHistory>> getPendingPriceHistories() async {
    return await isar.priceHistorys.filter().syncStatusEqualTo(SyncStatus.pending).findAll();
  }

  // Get total count of products
  Future<int> getProductsCount() async {
    return await isar.products.count();
  }

  // Get total count of price histories
  Future<int> getPriceHistoriesCount() async {
    return await isar.priceHistorys.count();
  }
}
