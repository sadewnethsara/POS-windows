import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_windows/data/local/db_helper.dart';
import 'package:pos_windows/data/local/schema/user_schema.dart';
import 'package:pos_windows/data/services/sync_service.dart';
import 'package:pos_windows/features/auth/presentation/providers/auth_provider.dart';

class UserSelectionScreen extends ConsumerStatefulWidget {
  const UserSelectionScreen({super.key});

  @override
  ConsumerState<UserSelectionScreen> createState() =>
      _UserSelectionScreenState();
}

class _UserSelectionScreenState extends ConsumerState<UserSelectionScreen> {
  List<User> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    var users = await DbHelper().getAllUsers();

    if (users.isEmpty) {
      // Try to sync from Firestore if local DB is empty
      await SyncService().fetchUsers();
      users = await DbHelper().getAllUsers();
    }

    if (!mounted) return;
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  void _showPinDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => PinDialog(user: user),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: ProgressRing());
    }

    if (_users.isEmpty) {
      // Show fallback UI when no users are available
      return ScaffoldPage(
        header: const PageHeader(title: Text('Welcome')),
        content: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(FluentIcons.people, size: 64, color: Colors.grey),
              const SizedBox(height: 20),
              const Text(
                'No Users Found',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Please login with your admin account to set up users',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
              FilledButton(
                onPressed: () => context.go('/login'),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text('Login with Email'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ScaffoldPage(
      header: const PageHeader(title: Text('Select User')),
      content: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
        ),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return HoverButton(
            onPressed: () => _showPinDialog(user),
            builder: (context, states) {
              return Card(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(FluentIcons.contact, size: 48),
                    const SizedBox(height: 10),
                    Text(user.name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(user.role, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class PinDialog extends ConsumerStatefulWidget {
  final User user;

  const PinDialog({super.key, required this.user});

  @override
  ConsumerState<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends ConsumerState<PinDialog> {
  final _pinController = TextEditingController();
  String _error = '';

  void _verifyPin() {
    final pin = _pinController.text;
    if (pin == widget.user.pin) {
      // Login successful (Offline mode)
      ref.read(authProvider.notifier).loginWithPin(widget.user);
      context.go('/home');
    } else {
      setState(() {
        _error = 'Incorrect PIN';
        _pinController.clear();
      });
    }
  }

  void _onDigitPress(String digit) {
    if (_pinController.text.length < 4) {
      setState(() {
        _pinController.text += digit;
        _error = '';
      });
    }
  }

  void _onBackspace() {
    if (_pinController.text.isNotEmpty) {
      setState(() {
        _pinController.text =
            _pinController.text.substring(0, _pinController.text.length - 1);
        _error = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Text('Enter PIN for ${widget.user.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PasswordBox(
            controller: _pinController,
            placeholder: 'PIN',
            enabled: false, // Disable keyboard input, force use of number pad
          ),
          if (_error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(_error, style: TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: 200,
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                for (var i = 1; i <= 9; i++)
                  Button(
                    child: Text('$i', style: const TextStyle(fontSize: 20)),
                    onPressed: () => _onDigitPress('$i'),
                  ),
                Button(
                  onPressed: _onBackspace,
                  child: const Icon(FluentIcons.back),
                ),
                Button(
                  child: const Text('0', style: TextStyle(fontSize: 20)),
                  onPressed: () => _onDigitPress('0'),
                ),
                FilledButton(
                  onPressed: _verifyPin,
                  child: const Icon(FluentIcons.check_mark),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Button(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
