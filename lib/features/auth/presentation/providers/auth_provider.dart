import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:pos_windows/data/local/schema/user_schema.dart';

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<fb_auth.User?>>((ref) {
  return AuthNotifier(ref);
});

final userRoleProvider = StateProvider<String?>((ref) => null);
final forcePasswordChangeProvider = StateProvider<bool>((ref) => false);
final localUserProvider = StateProvider<User?>((ref) => null);

class AuthNotifier extends StateNotifier<AsyncValue<fb_auth.User?>> {
  final Ref ref;

  AuthNotifier(this.ref) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    fb_auth.FirebaseAuth.instance.authStateChanges().listen((user) async {
      state = AsyncValue.data(user);
      if (user != null) {
        await _fetchUserRole(user.uid);
      } else {
        // Only clear if no local user (offline mode)
        if (ref.read(localUserProvider) == null) {
          ref.read(userRoleProvider.notifier).state = null;
        }
        ref.read(forcePasswordChangeProvider.notifier).state = false;
      }
    });
  }

  Future<void> _fetchUserRole(String uid) async {
    try {
      // 1. Try Custom Claims
      final idTokenResult =
          await fb_auth.FirebaseAuth.instance.currentUser?.getIdTokenResult();
      final role = idTokenResult?.claims?['role'];

      if (role != null) {
        ref.read(userRoleProvider.notifier).state = role;
        // Check for forcePasswordChange in Firestore for cashiers
        if (role == 'cashier') {
          final doc = await FirebaseFirestore.instance
              .collection('cashiers')
              .doc(uid)
              .get();
          if (doc.exists && doc.data()?['forcePasswordChange'] == true) {
            ref.read(forcePasswordChangeProvider.notifier).state = true;
          }
        }
        return;
      }

      // 2. Fallback: Firestore 'cashiers' collection
      final cashierDoc = await FirebaseFirestore.instance
          .collection('cashiers')
          .doc(uid)
          .get();
      if (cashierDoc.exists) {
        ref.read(userRoleProvider.notifier).state = 'cashier';
        if (cashierDoc.data()?['forcePasswordChange'] == true) {
          ref.read(forcePasswordChangeProvider.notifier).state = true;
        }
        return;
      }

      // 3. Fallback: Firestore 'users' collection (Admins)
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null && data['role'] == 'admin') {
          ref.read(userRoleProvider.notifier).state = 'admin';
          return;
        }
      }
    } catch (e) {
      debugPrint('Error fetching role: $e');
    }
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await fb_auth.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    await fb_auth.FirebaseAuth.instance.signOut();
    ref.read(localUserProvider.notifier).state = null;
    ref.read(userRoleProvider.notifier).state = null;
    ref.read(forcePasswordChangeProvider.notifier).state = false;
  }

  Future<void> completePasswordChange() async {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Update Firestore
      await FirebaseFirestore.instance
          .collection('cashiers')
          .doc(user.uid)
          .update({
        'forcePasswordChange': false,
      });
      ref.read(forcePasswordChangeProvider.notifier).state = false;
    }
  }

  void loginWithPin(User user) {
    ref.read(localUserProvider.notifier).state = user;
    ref.read(userRoleProvider.notifier).state = user.role;
    // We don't set state to AsyncValue.data(user) because types mismatch
    // The router will check localUserProvider
  }
}
