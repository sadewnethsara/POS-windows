import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_windows/data/local/schema/product_schema.dart';
import 'package:pos_windows/features/checkout/domain/models/cart_item.dart';

class CartState {
  final List<CartItem> items;
  final double subtotal;
  final double tax;
  final double discountAmount;
  final double discountPercentage;
  final double total;

  const CartState({
    this.items = const [],
    this.subtotal = 0.0,
    this.tax = 0.0,
    this.discountAmount = 0.0,
    this.discountPercentage = 0.0,
    this.total = 0.0,
  });

  CartState copyWith({
    List<CartItem>? items,
    double? subtotal,
    double? tax,
    double? discountAmount,
    double? discountPercentage,
    double? total,
  }) {
    return CartState(
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      discountAmount: discountAmount ?? this.discountAmount,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      total: total ?? this.total,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  void addItem(Product product) {
    final existingIndex = state.items
        .indexWhere((item) => item.product.barcode == product.barcode);

    List<CartItem> newItems;
    if (existingIndex >= 0) {
      newItems = List.from(state.items);
      final existingItem = newItems[existingIndex];
      newItems[existingIndex] =
          existingItem.copyWith(quantity: existingItem.quantity + 1);
    } else {
      newItems = [...state.items, CartItem(product: product)];
    }

    _updateState(newItems);
  }

  void removeItem(Product product) {
    final newItems = state.items
        .where((item) => item.product.barcode != product.barcode)
        .toList();
    _updateState(newItems);
  }

  void updateQuantity(Product product, int quantity) {
    if (quantity <= 0) {
      removeItem(product);
      return;
    }

    final index = state.items
        .indexWhere((item) => item.product.barcode == product.barcode);
    if (index >= 0) {
      final newItems = List<CartItem>.from(state.items);
      newItems[index] = newItems[index].copyWith(quantity: quantity);
      _updateState(newItems);
    }
  }

  void clearCart() {
    state = const CartState();
  }

  void applyPercentageDiscount(double percentage) {
    state = state.copyWith(
      discountPercentage: percentage,
      discountAmount: 0, // Reset fixed discount
    );
    _updateState(state.items);
  }

  void applyFixedDiscount(double amount) {
    state = state.copyWith(
      discountAmount: amount,
      discountPercentage: 0, // Reset percentage discount
    );
    _updateState(state.items);
  }

  void removeDiscount() {
    state = state.copyWith(
      discountAmount: 0,
      discountPercentage: 0,
    );
    _updateState(state.items);
  }

  void _updateState(List<CartItem> items) {
    double subtotal = 0;
    for (var item in items) {
      subtotal += item.total;
    }

    double taxRate = 0.0;
    double tax = subtotal * taxRate;

    double discount = state.discountAmount;
    if (state.discountPercentage > 0) {
      discount = subtotal * (state.discountPercentage / 100);
    }

    double total = subtotal + tax - discount;
    if (total < 0) total = 0;

    state = state.copyWith(
      items: items,
      subtotal: subtotal,
      tax: tax,
      total: total,
    );
  }

  double get total => state.total;
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
