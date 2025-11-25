import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_windows/data/local/db_helper.dart';
import 'package:pos_windows/data/local/schema/product_schema.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  List<Product> _products = [];
  bool _isLoading = true;
  bool _showLowStockOnly = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final products = await DbHelper().getAllProducts();
    setState(() {
      _products = products;
      _isLoading = false;
    });
  }

  List<Product> get _filteredProducts {
    if (_showLowStockOnly) {
      return _products.where((p) => p.stock < 10).toList(); // Threshold 10
    }
    return _products;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: ProgressRing());
    }

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Inventory Management'),
        commandBar: CommandBar(
          primaryItems: [
            CommandBarButton(
              icon: Icon(
                _showLowStockOnly
                    ? FluentIcons.filter_solid
                    : FluentIcons.filter,
                color: _showLowStockOnly ? Colors.red : null,
              ),
              label: const Text('Low Stock Only'),
              onPressed: () {
                setState(() {
                  _showLowStockOnly = !_showLowStockOnly;
                });
              },
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.refresh),
              label: const Text('Refresh'),
              onPressed: _loadProducts,
            ),
          ],
        ),
      ),
      content: ListView.builder(
        itemCount: _filteredProducts.length,
        itemBuilder: (context, index) {
          final product = _filteredProducts[index];
          final isLowStock = product.stock < 10;
          return ListTile(
            leading: Icon(
              FluentIcons.stock_up,
              color: isLowStock ? Colors.red : Colors.green,
            ),
            title: Text(product.name),
            subtitle: Text(
              'Barcode: ${product.barcode}',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Stock: ${product.stock}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isLowStock ? Colors.red : null,
                  ),
                ),
                const SizedBox(width: 10),
                if (isLowStock)
                  Tooltip(
                    message: 'Low Stock Warning',
                    child: Icon(FluentIcons.warning, color: Colors.red),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
