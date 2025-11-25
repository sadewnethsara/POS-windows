import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:pos_windows/data/local/db_helper.dart';
import 'package:pos_windows/data/local/schema/product_schema.dart';
import 'package:pos_windows/data/local/schema/user_schema.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DbHelper _dbHelper = DbHelper();

  // Fetch all products from Firestore and update local DB
  Future<void> fetchProducts() async {
    try {
      final snapshot = await _firestore.collection('products').get();
      final products = snapshot.docs.map((doc) {
        final data = doc.data();
        return Product()
          ..barcode = data['barcode'] ?? ''
          ..name = data['name'] ?? 'Unknown'
          ..price = (data['price'] as num).toDouble()
          ..stock = data['stock'] ?? 0
          ..imageUrl = data['imageUrl']
          ..syncStatus = 'synced' // Mark as synced since we just fetched it
          ..updatedAt = DateTime.now();
      }).toList();

      await _dbHelper.saveProducts(products);
      if (kDebugMode) {
        print('Synced ${products.length} products');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching products: $e');
      }
    }
  }

  // Fetch all users from Firestore and update local DB
  Future<void> fetchUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      final users = snapshot.docs.map((doc) {
        final data = doc.data();
        return User()
          ..uid = doc.id
          ..email = data['email'] ?? ''
          ..name = data['name'] ?? 'Unknown'
          ..role = data['role'] ?? 'cashier'
          ..pin = data['pin'] ?? ''
          ..forcePasswordChange = data['forcePasswordChange'] ?? false;
      }).toList();

      await _dbHelper.saveUsers(users);
      if (kDebugMode) {
        print('Synced ${users.length} users');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching users: $e');
      }
    }
  }

  // Upload pending orders to Firestore
  Future<void> uploadPendingOrders() async {
    final pendingOrders = await _dbHelper.getPendingOrders();
    for (var order in pendingOrders) {
      try {
        await _firestore.collection('orders').add({
          'orderId': order.orderId,
          'total': order.total,
          'createdAt': FieldValue.serverTimestamp(),
          'items': order.items
              .map(
                (item) => {
                  'productId': item.productId,
                  'name': item.name,
                  'price': item.price,
                  'quantity': item.quantity,
                },
              )
              .toList(),
        });

        await _dbHelper.markOrderAsSynced(order.id);
        if (kDebugMode) {
          print('Uploaded order ${order.orderId}');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error uploading order ${order.orderId}: $e');
        }
      }
    }
  }
}
