import 'package:isar/isar.dart';

part 'user_schema.g.dart';

@collection
class User {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uid; // Firebase UID

  late String email;
  late String name;
  late String role; // 'admin' or 'cashier'

  String? pin; // Encrypted or hashed PIN for offline login
  bool forcePasswordChange = false;

  @Index()
  DateTime? lastLoginAt;
}
