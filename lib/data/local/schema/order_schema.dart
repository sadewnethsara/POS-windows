import 'package:isar/isar.dart';

part 'order_schema.g.dart';

@collection
class Order {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String orderId; // UUID

  late List<OrderItem> items;

  late double total;
  late double subtotal;
  late double tax;
  late double discount;

  @Index()
  late DateTime createdAt;

  @Index()
  late String status; // 'completed', 'refunded'

  @Index()
  late String syncStatus; // 'pending', 'synced'

  late String paymentMethod; // 'cash', 'card'
  String? cashierId;
  String? customerId;
}

@embedded
class OrderItem {
  late String productId;
  late String name;
  late double price;
  late int quantity;
}
