import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_windows/core/services/barcode_listener.dart';
import 'package:pos_windows/data/local/db_helper.dart';
import 'package:pos_windows/features/checkout/presentation/providers/cart_provider.dart';
import 'package:pos_windows/features/checkout/presentation/widgets/cart_view.dart';
import 'package:pos_windows/features/checkout/presentation/widgets/product_grid.dart';
import 'package:pos_windows/features/checkout/presentation/widgets/payment_dialog.dart';
import 'package:pos_windows/data/local/schema/order_schema.dart';
import 'package:uuid/uuid.dart';

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  Future<void> _handleBarcodeScan(WidgetRef ref, String barcode) async {
    final product = await DbHelper().getProductByBarcode(barcode);
    if (product != null) {
      ref.read(cartProvider.notifier).addItem(product);
    } else {
      debugPrint('Product not found for barcode: $barcode');
    }
  }

  void _processCheckout(BuildContext context, WidgetRef ref) {
    final cartState = ref.read(cartProvider);
    final cartItems = cartState.items;
    if (cartItems.isEmpty) return;

    final totalAmount = ref.read(cartProvider.notifier).total;

    showDialog(
      context: context,
      builder: (context) => PaymentDialog(
        totalAmount: totalAmount,
        onPaymentConfirmed: (method, tendered) async {
          // 1. Create Order
          final order = Order()
            ..orderId = const Uuid().v4()
            ..items = cartItems
                .map((item) => OrderItem()
                  ..productId =
                      item.product.barcode // Using barcode as ID for now
                  ..name = item.product.name
                  ..price = item.product.price
                  ..quantity = item.quantity)
                .toList()
            ..total = totalAmount
            ..subtotal = totalAmount // Assuming no tax/discount for now
            ..tax = 0
            ..discount = 0
            ..createdAt = DateTime.now()
            ..status = 'completed'
            ..syncStatus = 'pending'
            ..paymentMethod = method;

          // 2. Save Order & Update Stock
          await DbHelper().saveOrder(order);
          for (final item in cartItems) {
            await DbHelper()
                .updateProductStock(item.product.barcode, item.quantity);
          }

          // 3. Clear Cart
          ref.read(cartProvider.notifier).clearCart();

          // 4. Show Success
          if (context.mounted) {
            displayInfoBar(context, builder: (context, close) {
              return InfoBar(
                title: const Text('Order Completed'),
                content: Text('Order ${order.orderId} saved successfully.'),
                severity: InfoBarSeverity.success,
                action: IconButton(
                  icon: const Icon(FluentIcons.clear),
                  onPressed: close,
                ),
              );
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BarcodeListener(
      onBarcodeScanned: (barcode) => _handleBarcodeScan(ref, barcode),
      child: Row(
        children: [
          const Expanded(flex: 3, child: ProductGrid()),
          const Divider(direction: Axis.vertical),
          Expanded(
            flex: 2,
            child: CartView(
              onCheckout: () => _processCheckout(context, ref),
            ),
          ),
        ],
      ),
    );
  }
}
