import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_windows/core/presentation/providers/touch_mode_provider.dart';
import 'package:pos_windows/features/auth/presentation/providers/auth_provider.dart';
import 'package:window_manager/window_manager.dart';

class HomeShell extends ConsumerStatefulWidget {
  final Widget child;
  final GoRouterState state;

  const HomeShell({super.key, required this.child, required this.state});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = widget.state.uri.toString();
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/products')) return 1;
    if (location.startsWith('/inventory')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final isTouchMode = ref.watch(touchModeProvider);
    final userRole = ref.watch(userRoleProvider);

    final List<NavigationPaneItem> items = [
      PaneItem(
        icon: const Icon(FluentIcons.shopping_cart),
        title: const Text('Checkout'),
        body: selectedIndex == 0 ? widget.child : const SizedBox.shrink(),
      ),
    ];

    if (userRole == 'admin') {
      items.addAll([
        PaneItem(
          icon: const Icon(FluentIcons.product_list),
          title: const Text('Products'),
          body: selectedIndex == 1 ? widget.child : const SizedBox.shrink(),
        ),
        PaneItem(
          icon: const Icon(FluentIcons.stock_up),
          title: const Text('Inventory'),
          body: selectedIndex == 2 ? widget.child : const SizedBox.shrink(),
        ),
        PaneItem(
          icon: const Icon(FluentIcons.settings),
          title: const Text('Settings'),
          body: selectedIndex == 3 ? widget.child : const SizedBox.shrink(),
        ),
      ]);
    }

    return NavigationView(
      appBar: NavigationAppBar(
        title: const Text('SuperMart POS'),
        automaticallyImplyLeading: false,
        actions: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Tooltip(
              message:
                  isTouchMode ? 'Switch to Mouse Mode' : 'Switch to Touch Mode',
              child: IconButton(
                icon: Icon(isTouchMode
                    ? FluentIcons.chrome_restore
                    : FluentIcons.touch_pointer),
                onPressed: () {
                  ref.read(touchModeProvider.notifier).state = !isTouchMode;
                },
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Toggle Full Screen',
              child: IconButton(
                icon: const Icon(FluentIcons.full_screen),
                onPressed: () async {
                  final isFullScreen = await windowManager.isFullScreen();
                  if (isFullScreen) {
                    await windowManager.setFullScreen(false);
                  } else {
                    await windowManager.setFullScreen(true);
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
      pane: NavigationPane(
        selected: selectedIndex,
        onChanged: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              if (userRole == 'admin') context.go('/products');
              break;
            case 2:
              if (userRole == 'admin') context.go('/inventory');
              break;
            case 3:
              if (userRole == 'admin') context.go('/settings');
              break;
          }
        },
        displayMode: PaneDisplayMode.compact,
        items: items,
        footerItems: [
          PaneItemAction(
            icon: const Icon(FluentIcons.sign_out),
            title: const Text('Logout'),
            onTap: () {
              ref.read(authProvider.notifier).signOut();
            },
          ),
        ],
      ),
    );
  }
}
