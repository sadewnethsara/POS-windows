import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_windows/features/auth/presentation/providers/auth_provider.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _changePassword() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.length < 6) {
      setState(() {
        _isLoading = false;
        _error = 'Password must be at least 6 characters.';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _isLoading = false;
        _error = 'Passwords do not match.';
      });
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updatePassword(password);

        // Update forcePasswordChange flag in Firestore if applicable
        // This logic should ideally be in AuthProvider or a service
        await ref.read(authProvider.notifier).completePasswordChange();

        if (mounted) {
          context.go('/home');
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      content: ScaffoldPage(
        content: Center(
          child: Card(
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Change Password',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  if (_error != null)
                    InfoBar(
                      title: const Text('Error'),
                      content: Text(_error!),
                      severity: InfoBarSeverity.error,
                    ),
                  const SizedBox(height: 20),
                  PasswordBox(
                    controller: _passwordController,
                    placeholder: 'New Password',
                  ),
                  const SizedBox(height: 10),
                  PasswordBox(
                    controller: _confirmPasswordController,
                    placeholder: 'Confirm New Password',
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _changePassword,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: ProgressRing(),
                            )
                          : const Text('Change Password'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
