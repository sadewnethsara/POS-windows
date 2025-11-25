import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_windows/data/local/db_helper.dart';
import 'package:pos_windows/data/local/schema/product_schema.dart';
import 'package:pos_windows/features/checkout/presentation/providers/cart_provider.dart';
import 'package:isar/isar.dart';

class ProductGrid extends ConsumerStatefulWidget {
  const ProductGrid({super.key});

  @override
  ConsumerState<ProductGrid> createState() => _ProductGridState();
}

class _ProductGridState extends ConsumerState<ProductGrid> {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await DbHelper().db.products.where().findAll();
    setState(() {
      _products = products;
      _filteredProducts = products;
      _isLoading = false;
    });
  }

  void _filterProducts(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredProducts = _products;
      });
    } else {
      setState(() {
        _filteredProducts = _products
            .where((p) =>
                p.name.toLowerCase().contains(query.toLowerCase()) ||
                p.barcode.contains(query))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: ProgressRing());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextBox(
            controller: _searchController,
            placeholder: 'Search products...',
            prefix: const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Icon(FluentIcons.search),
            ),
            onChanged: _filterProducts,
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              childAspectRatio: 0.8,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _filteredProducts.length,
            itemBuilder: (context, index) {
              final product = _filteredProducts[index];
              return HoverButton(
                onPressed: () {
                  ref.read(cartProvider.notifier).addItem(product);
                },
                builder: (context, states) {
                  return Card(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            color: Colors.grey[30],
                            width: double.infinity,
                            child: product.imageUrl != null &&
                                    product.imageUrl!.isNotEmpty
                                ? Image.network(
                                    product.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error,
                                            stackTrace) =>
                                        const Icon(FluentIcons.shopping_cart,
                                            size: 40),
                                  )
                                : const Icon(FluentIcons.shopping_cart,
                                    size: 40),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: FluentTheme.of(context)
                                    .typography
                                    .bodyStrong,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${product.price.toStringAsFixed(2)}',
                                style:
                                    FluentTheme.of(context).typography.caption,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
