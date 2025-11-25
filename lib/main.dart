import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pos_windows/firebase_options.dart';
import 'package:pos_windows/data/local/db_helper.dart';
import 'package:pos_windows/data/services/sync_service.dart';
import 'package:pos_windows/features/auth/presentation/login_screen.dart';
import 'package:pos_windows/features/auth/presentation/providers/auth_provider.dart';
import 'package:pos_windows/features/home/presentation/home_shell.dart';
import 'package:pos_windows/features/checkout/presentation/checkout_screen.dart';
import 'package:pos_windows/features/admin/presentation/product_management_screen.dart';
import 'package:pos_windows/features/admin/presentation/inventory_screen.dart';
import 'package:pos_windows/features/auth/presentation/change_password_screen.dart';
import 'package:pos_windows/features/settings/presentation/settings_screen.dart';
import 'package:pos_windows/features/auth/presentation/user_selection_screen.dart';
import 'package:pos_windows/core/theme/app_theme.dart';
import 'package:pos_windows/core/presentation/providers/touch_mode_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await DbHelper().init();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1024, 768),
    minimumSize: Size(1024, 768),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // Start initial sync in background
  SyncService().fetchProducts();
  runApp(const ProviderScope(child: MyApp()));
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      if (isLoading) return null;

      final localUser = ref.read(localUserProvider);
      final isLoggedIn = authState.value != null || localUser != null;
      final isLoggingIn = state.uri.toString() == '/login';
      final isChangingPassword = state.uri.toString() == '/change-password';
      final isSelectingUser = state.uri.toString() == '/select-user';

      if (!isLoggedIn && !isLoggingIn && !isSelectingUser) {
        return '/select-user';
      }

      if (isLoggedIn) {
        final forceChange = ref.read(forcePasswordChangeProvider);
        if (forceChange && !isChangingPassword) return '/change-password';
        if (!forceChange && isChangingPassword) return '/home';
        if (isLoggingIn || isSelectingUser) return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/select-user',
        builder: (context, state) => const UserSelectionScreen(),
      ),
      GoRoute(
        path: '/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return HomeShell(state: state, child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const ScaffoldPage(
              content: CheckoutScreen(),
            ),
          ),
          GoRoute(
            path: '/products',
            builder: (context, state) => const ScaffoldPage(
              content: ProductManagementScreen(),
            ),
          ),
          GoRoute(
            path: '/inventory',
            builder: (context, state) => const ScaffoldPage(
              content: InventoryScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final isTouchMode = ref.watch(touchModeProvider);

    return FluentApp.router(
      title: 'SuperMart POS',
      theme: AppTheme.getTheme(Brightness.light, isTouchMode),
      darkTheme: AppTheme.getTheme(Brightness.dark, isTouchMode),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
