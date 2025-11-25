import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_windows/data/local/schema/order_schema.dart';
import 'package:pos_windows/data/local/schema/product_schema.dart';
import 'package:pos_windows/data/local/schema/user_schema.dart';

class DbHelper {
  static final DbHelper _instance = DbHelper._internal();
  late Isar _isar;

  factory DbHelper() {
    return _instance;
  }

  DbHelper._internal();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    final dir = await getApplicationDocumentsDirectory();
    if (Isar.instanceNames.isEmpty) {
      _isar = await Isar.open(
        [ProductSchema, OrderSchema, UserSchema],
        directory: dir.path,
      );
    } else {
      _isar = Isar.getInstance()!;
    }
    _isInitialized = true;
  }

  Isar get db {
    if (!_isInitialized) {
      throw Exception('DbHelper not initialized. Call init() first.');
    }
    return _isar;
  }

  // Product Methods
  Future<Product?> getProductByBarcode(String barcode) async {
    return await _isar.products.filter().barcodeEqualTo(barcode).findFirst();
  }

  Future<void> saveProducts(List<Product> products) async {
    await _isar.writeTxn(() async {
      await _isar.products.putAll(products);
    });
  }

  Future<void> saveProduct(Product product) async {
    await _isar.writeTxn(() async {
      await _isar.products.put(product);
    });
  }

  Future<List<Product>> getAllProducts() async {
    return await _isar.products.where().findAll();
  }

  // Order Methods
  Future<void> saveOrder(Order order) async {
    await _isar.writeTxn(() async {
      await _isar.orders.put(order);
    });
  }

  Future<List<Order>> getPendingOrders() async {
    return await _isar.orders.filter().syncStatusEqualTo('pending').findAll();
  }

  // User Methods
  Future<void> saveUser(User user) async {
    await _isar.writeTxn(() async {
      await _isar.users.put(user);
    });
  }

  Future<void> saveUsers(List<User> users) async {
    await _isar.writeTxn(() async {
      await _isar.users.putAll(users);
    });
  }

  Future<User?> getUserByUid(String uid) async {
    return await _isar.users.filter().uidEqualTo(uid).findFirst();
  }

  Future<List<User>> getAllUsers() async {
    return await _isar.users.where().findAll();
  }

  Future<void> markOrderAsSynced(int id) async {
    await _isar.writeTxn(() async {
      final order = await _isar.orders.get(id);
      if (order != null) {
        order.syncStatus = 'synced';
        await _isar.orders.put(order);
      }
    });
  }

  Future<void> updateProductStock(String barcode, int quantityChange) async {
    await _isar.writeTxn(() async {
      final product =
          await _isar.products.filter().barcodeEqualTo(barcode).findFirst();
      if (product != null) {
        product.stock -= quantityChange;
        product.syncStatus = 'pending'; // Mark for sync
        await _isar.products.put(product);
      }
    });
  }
}
