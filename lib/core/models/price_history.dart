import 'package:isar/isar.dart';
import 'product.dart';

part 'price_history.g.dart';

@collection
class PriceHistory {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  late String productUuid;
  late double oldPurchasePrice;
  late double oldSalesPrice;
  late double newPurchasePrice;
  late double newSalesPrice;
  late DateTime changeDate;
  late String changedBy; // user uid

  @enumerated
  late SyncStatus syncStatus;

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'uuid': uuid,
      'productUuid': productUuid,
      'oldPurchasePrice': oldPurchasePrice,
      'oldSalesPrice': oldSalesPrice,
      'newPurchasePrice': newPurchasePrice,
      'newSalesPrice': newSalesPrice,
      'changeDate': changeDate.toIso8601String(),
      'changedBy': changedBy,
    };
  }

  // Create from Firestore Map
  static PriceHistory fromFirestore(Map<String, dynamic> json) {
    return PriceHistory()
      ..uuid = json['uuid'] as String
      ..productUuid = json['productUuid'] as String
      ..oldPurchasePrice = (json['oldPurchasePrice'] as num).toDouble()
      ..oldSalesPrice = (json['oldSalesPrice'] as num).toDouble()
      ..newPurchasePrice = (json['newPurchasePrice'] as num).toDouble()
      ..newSalesPrice = (json['newSalesPrice'] as num).toDouble()
      ..changeDate = DateTime.parse(json['changeDate'] as String)
      ..changedBy = json['changedBy'] as String
      ..syncStatus = SyncStatus.synced;
  }
}
