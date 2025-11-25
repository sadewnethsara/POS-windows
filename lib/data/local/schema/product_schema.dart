import 'package:isar/isar.dart';

part 'product_schema.g.dart';

@collection
class Product {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String barcode;

  @Index(type: IndexType.value)
  late String name;

  late double price;
  late int stock;
  String? imageUrl;

  @Index()
  late String syncStatus; // 'pending', 'synced'

  // Sync metadata
  @Index()
  DateTime? updatedAt;
}
