import 'package:isar/isar.dart';

part 'product.g.dart';

enum SyncStatus { pending, synced }

@collection
class Product {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  late String name;
  late String category;
  late double purchasePrice;
  late double salesPrice;
  late String localImagePath;
  String? remoteImageUrl;
  late DateTime createdAt;
  late DateTime updatedAt;
  late String updatedBy; // user uid

  @enumerated
  late SyncStatus syncStatus;

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'uuid': uuid,
      'name': name,
      'category': category,
      'purchasePrice': purchasePrice,
      'salesPrice': salesPrice,
      'remoteImageUrl': remoteImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'updatedBy': updatedBy,
    };
  }

  // Create from Firestore Map
  static Product fromFirestore(Map<String, dynamic> json) {
    return Product()
      ..uuid = json['uuid'] as String
      ..name = json['name'] as String
      ..category = json['category'] as String
      ..purchasePrice = (json['purchasePrice'] as num).toDouble()
      ..salesPrice = (json['salesPrice'] as num).toDouble()
      ..remoteImageUrl = json['remoteImageUrl'] as String?
      ..createdAt = DateTime.parse(json['createdAt'] as String)
      ..updatedAt = DateTime.parse(json['updatedAt'] as String)
      ..updatedBy = json['updatedBy'] as String
      ..localImagePath = ''
      ..syncStatus = SyncStatus.synced;
  }
}
