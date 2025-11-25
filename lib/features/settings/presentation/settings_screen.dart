import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:pos_windows/features/auth/presentation/providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userRole = ref.watch(userRoleProvider);

    return ScaffoldPage(
      header: const PageHeader(title: Text('Settings')),
      content: NavigationView(
        pane: NavigationPane(
          selected: _selectedIndex,
          onChanged: (index) => setState(() => _selectedIndex = index),
          displayMode: PaneDisplayMode.top,
          items: [
            PaneItem(
              icon: const Icon(FluentIcons.settings),
              title: const Text('General'),
              body: const Center(child: Text('General Settings (Coming Soon)')),
            ),
            if (userRole == 'admin')
              PaneItem(
                icon: const Icon(FluentIcons.people),
                title: const Text('User Management'),
                body: const UserManagementTab(),
              ),
            PaneItem(
              icon: const Icon(FluentIcons.lock),
              title: const Text('Security'),
              body: const ChangePasswordTab(),
            ),
          ],
        ),
      ),
    );
  }
}

class UserManagementTab extends StatefulWidget {
  const UserManagementTab({super.key});

  @override
  State<UserManagementTab> createState() => _UserManagementTabState();
}

class _UserManagementTabState extends State<UserManagementTab> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isLoading = false;

  Future<void> _createCashier() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _pinController.text.isEmpty) {
      // Show error
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result =
          await FirebaseFunctions.instance.httpsCallable('createCashier').call({
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        'name': _nameController.text.trim(),
        'pin': _pinController.text.trim(),
      });

      if (result.data['success'] == true) {
        if (mounted) {
          displayInfoBar(context, builder: (context, close) {
            return InfoBar(
              title: const Text('Success'),
              content: const Text('Cashier created successfully'),
              action: IconButton(
                icon: const Icon(FluentIcons.clear),
                onPressed: close,
              ),
              severity: InfoBarSeverity.success,
            );
          });
          _nameController.clear();
          _emailController.clear();
          _passwordController.clear();
          _pinController.clear();
        }
      }
    } catch (e) {
      if (mounted) {
        displayInfoBar(context, builder: (context, close) {
          return InfoBar(
            title: const Text('Error'),
            content: Text(e.toString()),
            action: IconButton(
              icon: const Icon(FluentIcons.clear),
              onPressed: close,
            ),
            severity: InfoBarSeverity.error,
          );
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      content: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Create New Cashier',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            TextBox(controller: _nameController, placeholder: 'Name'),
            const SizedBox(height: 10),
            TextBox(controller: _emailController, placeholder: 'Email'),
            const SizedBox(height: 10),
            TextBox(
                controller: _passwordController,
                placeholder: 'Password',
                obscureText: true),
            const SizedBox(height: 10),
            TextBox(
                controller: _pinController,
                placeholder: 'PIN (for offline login)',
                keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _isLoading ? null : _createCashier,
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: ProgressRing())
                  : const Text('Create Cashier'),
            ),
          ],
        ),
      ),
    );
  }
}

class ChangePasswordTab extends StatelessWidget {
  const ChangePasswordTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
        child: Text(
            'Change Password functionality is available via /change-password route or on first login.'));
  }
}
