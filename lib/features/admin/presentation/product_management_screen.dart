import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_windows/data/local/db_helper.dart';
import 'package:pos_windows/data/local/schema/product_schema.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProductManagementScreen extends ConsumerStatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  ConsumerState<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState
    extends ConsumerState<ProductManagementScreen> {
  List<Product> _products = [];
  bool _isLoading = true;

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

  Future<String?> _uploadImage(File imageFile, String barcode) async {
    try {
      debugPrint('Starting image upload for barcode: $barcode');

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('products')
          .child('$barcode.jpg');

      debugPrint('Uploading to: ${storageRef.fullPath}');
      final uploadTask = await storageRef.putFile(imageFile);

      debugPrint('Upload state: ${uploadTask.state}');

      if (uploadTask.state == TaskState.success) {
        final downloadUrl = await storageRef.getDownloadURL();
        debugPrint('Upload successful! URL: $downloadUrl');
        return downloadUrl;
      } else {
        debugPrint('Upload failed with state: ${uploadTask.state}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error uploading image: $e');
      debugPrint('Stack trace: $stackTrace');

      // Show error to user
      if (mounted) {
        displayInfoBar(context, builder: (context, close) {
          return InfoBar(
            title: const Text('Upload Failed'),
            content: Text('Error: ${e.toString()}'),
            severity: InfoBarSeverity.error,
            action: IconButton(
              icon: const Icon(FluentIcons.clear),
              onPressed: close,
            ),
          );
        });
      }
      return null;
    }
  }

  Future<void> _showProductDialog([Product? product]) async {
    final nameController = TextEditingController(text: product?.name ?? '');
    final barcodeController =
        TextEditingController(text: product?.barcode ?? '');
    final priceController =
        TextEditingController(text: product?.price.toString() ?? '');
    final stockController =
        TextEditingController(text: product?.stock.toString() ?? '0');

    String? imageUrl = product?.imageUrl;
    File? selectedImage;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return ContentDialog(
              title: Text(product == null ? 'Add Product' : 'Edit Product'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Image Preview/Upload
                    GestureDetector(
                      onTap: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.image,
                        );

                        if (result != null &&
                            result.files.single.path != null) {
                          setDialogState(() {
                            selectedImage = File(result.files.single.path!);
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[60]),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[20],
                        ),
                        child: selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : imageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(FluentIcons.photo2,
                                                  size: 48),
                                              Text('Tap to select image'),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(FluentIcons.photo2, size: 48),
                                        SizedBox(height: 8),
                                        Text('Tap to select image'),
                                      ],
                                    ),
                                  ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextBox(
                      controller: nameController,
                      placeholder: 'Product Name',
                    ),
                    const SizedBox(height: 10),
                    TextBox(
                      controller: barcodeController,
                      placeholder: 'Barcode',
                    ),
                    const SizedBox(height: 10),
                    TextBox(
                      controller: priceController,
                      placeholder: 'Price',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 10),
                    TextBox(
                      controller: stockController,
                      placeholder: 'Initial Stock',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                Button(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
                FilledButton(
                  child: const Text('Save'),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final barcode = barcodeController.text.trim();
                    final price = double.tryParse(priceController.text) ?? 0.0;
                    final stock = int.tryParse(stockController.text) ?? 0;

                    if (name.isEmpty || barcode.isEmpty) return;

                    // Show loading
                    if (context.mounted) {
                      displayInfoBar(context, builder: (context, close) {
                        return const InfoBar(
                          title: Text('Uploading...'),
                          content:
                              Text('Please wait while we upload the image'),
                        );
                      });
                    }

                    // Upload image if selected
                    String? uploadedImageUrl = imageUrl;
                    if (selectedImage != null) {
                      uploadedImageUrl =
                          await _uploadImage(selectedImage!, barcode);
                    }

                    final newProduct = Product()
                      ..name = name
                      ..barcode = barcode
                      ..price = price
                      ..stock = stock
                      ..imageUrl = uploadedImageUrl
                      ..syncStatus = 'pending'
                      ..updatedAt = DateTime.now();

                    if (product != null) {
                      newProduct.id = product.id;
                    }

                    // Save to local DB
                    await DbHelper().saveProduct(newProduct);

                    if (context.mounted) {
                      Navigator.pop(context);
                      _loadProducts();

                      displayInfoBar(context, builder: (context, close) {
                        return InfoBar(
                          title: const Text('Success'),
                          content: const Text('Product saved successfully'),
                          severity: InfoBarSeverity.success,
                        );
                      });
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: ProgressRing());
    }

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Product Management'),
        commandBar: CommandBar(
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.add),
              label: const Text('Add Product'),
              onPressed: () => _showProductDialog(),
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
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return ListTile(
            leading: product.imageUrl != null
                ? SizedBox(
                    width: 50,
                    height: 50,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(FluentIcons.product);
                        },
                      ),
                    ),
                  )
                : const Icon(FluentIcons.product),
            title: Text(product.name),
            subtitle:
                Text('Barcode: ${product.barcode} | Stock: ${product.stock}'),
            trailing: Text('\$${product.price.toStringAsFixed(2)}'),
            onPressed: () => _showProductDialog(product),
          );
        },
      ),
    );
  }
}
