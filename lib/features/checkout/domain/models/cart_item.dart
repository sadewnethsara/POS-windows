import 'package:pos_windows/data/local/schema/product_schema.dart';

class CartItem {
  final Product product;
  int quantity;
  double
      discount; // Percentage (0.0 - 1.0) or Fixed Amount? Let's assume Fixed Amount for now or handle both later.
  // For simplicity in this phase: Fixed Amount per unit.

  CartItem({
    required this.product,
    this.quantity = 1,
    this.discount = 0.0,
  });

  double get price => product.price;

  double get total => (price * quantity) - (discount * quantity);

  CartItem copyWith({
    Product? product,
    int? quantity,
    double? discount,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      discount: discount ?? this.discount,
    );
  }
}
