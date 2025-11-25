import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_windows/core/presentation/providers/touch_mode_provider.dart';
import 'package:pos_windows/features/checkout/presentation/providers/cart_provider.dart';

class CartView extends ConsumerWidget {
  final VoidCallback? onCheckout;

  const CartView({super.key, this.onCheckout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final isTouchMode = ref.watch(touchModeProvider);

    return Container(
      color: FluentTheme.of(context).cardColor,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Order',
                  style: FluentTheme.of(context).typography.subtitle,
                ),
                IconButton(
                  icon: const Icon(FluentIcons.delete),
                  onPressed: () => ref.read(cartProvider.notifier).clearCart(),
                ),
              ],
            ),
          ),
          const Divider(),

          // Cart Items List
          Expanded(
            child: cartState.items.isEmpty
                ? const Center(child: Text('Cart is empty'))
                : ListView.builder(
                    itemCount: cartState.items.length,
                    itemBuilder: (context, index) {
                      final item = cartState.items[index];
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          color: Colors.grey[30],
                          child: const Icon(FluentIcons.shopping_cart),
                        ),
                        title: Text(item.product.name),
                        subtitle: Text(
                            '\$${item.price.toStringAsFixed(2)} x ${item.quantity}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '\$${item.total.toStringAsFixed(2)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(FluentIcons.remove,
                                  size: isTouchMode ? 20 : 14),
                              onPressed: () {
                                ref.read(cartProvider.notifier).updateQuantity(
                                    item.product, item.quantity - 1);
                              },
                            ),
                            Text(
                              '${item.quantity}',
                              style: TextStyle(fontSize: isTouchMode ? 18 : 14),
                            ),
                            IconButton(
                              icon: Icon(FluentIcons.add,
                                  size: isTouchMode ? 20 : 14),
                              onPressed: () {
                                ref.read(cartProvider.notifier).updateQuantity(
                                    item.product, item.quantity + 1);
                              },
                            ),
                            IconButton(
                              icon: Icon(FluentIcons.delete,
                                  color: Colors.red,
                                  size: isTouchMode ? 20 : 14),
                              onPressed: () {
                                ref
                                    .read(cartProvider.notifier)
                                    .removeItem(item.product);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          const Divider(),

          // Totals Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildSummaryRow(context, 'Subtotal', cartState.subtotal),
                _buildSummaryRow(context, 'Tax', cartState.tax),

                // Discount Row with Action
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text('Discount'),
                          const SizedBox(width: 8),
                          if (cartState.discountPercentage > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${cartState.discountPercentage.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.green),
                              ),
                            ),
                          IconButton(
                            icon: const Icon(FluentIcons.edit, size: 14),
                            onPressed: () => _showDiscountDialog(context, ref),
                          ),
                        ],
                      ),
                      Text(
                        '-\$${(cartState.subtotal + cartState.tax - cartState.total).toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
                _buildSummaryRow(context, 'Total', cartState.total,
                    isBold: true, fontSize: 24),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: isTouchMode ? 60 : 40,
                  child: FilledButton(
                    onPressed: cartState.items.isEmpty ? null : onCheckout,
                    child: const Text('Pay Now'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, double amount,
      {bool isBold = false, double? fontSize}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: FluentTheme.of(context).typography.body?.copyWith(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontSize: fontSize,
                ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: FluentTheme.of(context).typography.body?.copyWith(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontSize: fontSize,
                ),
          ),
        ],
      ),
    );
  }

  void _showDiscountDialog(BuildContext context, WidgetRef ref) {
    final TextEditingController controller = TextEditingController();
    bool isPercentage = true;

    showDialog(
      context: context,
      builder: (context) {
        return ContentDialog(
          title: const Text('Apply Discount'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      RadioButton(
                        checked: isPercentage,
                        content: const Text('Percentage (%)'),
                        onChanged: (v) => setState(() => isPercentage = true),
                      ),
                      const SizedBox(width: 16),
                      RadioButton(
                        checked: !isPercentage,
                        content: const Text('Fixed Amount (\$)'),
                        onChanged: (v) => setState(() => isPercentage = false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextBox(
                    controller: controller,
                    placeholder: isPercentage
                        ? 'Enter percentage (e.g. 10)'
                        : 'Enter amount (e.g. 5.00)',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
              );
            },
          ),
          actions: [
            Button(
              child: const Text('Remove Discount'),
              onPressed: () {
                ref.read(cartProvider.notifier).removeDiscount();
                Navigator.pop(context);
              },
            ),
            Button(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            FilledButton(
              child: const Text('Apply'),
              onPressed: () {
                final value = double.tryParse(controller.text) ?? 0;
                if (value > 0) {
                  if (isPercentage) {
                    ref
                        .read(cartProvider.notifier)
                        .applyPercentageDiscount(value);
                  } else {
                    ref.read(cartProvider.notifier).applyFixedDiscount(value);
                  }
                }
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
