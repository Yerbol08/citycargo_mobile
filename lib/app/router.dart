import 'dart:ui' as dart_ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:citycargo_mobile/gen_l10n/app_localizations.dart';
import 'app_role.dart';
import 'theme.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/role_select_screen.dart';
import '../features/auth/presentation/screens/app_role_select_screen.dart';
import '../features/registration/presentation/screens/client_registration_screen.dart';
import '../features/registration/presentation/screens/courier_registration_screen.dart';
import '../features/registration/presentation/screens/courier_pending_screen.dart';
import '../features/registration/presentation/screens/courier_rejected_screen.dart';
import '../features/orders/presentation/screens/home_screen.dart';
import '../features/orders/presentation/screens/orders_list_screen.dart';
import '../features/orders/presentation/screens/order_detail_screen.dart';
import '../features/orders/domain/models/create_order_params.dart';
import '../features/orders/presentation/screens/create_order_screen.dart';
import '../features/orders/presentation/screens/order_preview_screen.dart';
import '../features/orders/presentation/screens/address_picker_screen.dart';
import '../features/orders/presentation/screens/map_debug_screen.dart';
import '../features/orders/presentation/screens/security_code_display_screen.dart';
import '../features/orders/presentation/screens/order_history_screen.dart';
import '../features/orders/presentation/screens/order_security_codes_screen.dart';
import '../features/orders/presentation/screens/public_order_screen.dart';
import '../features/courier/presentation/screens/courier_dashboard_screen.dart';
import '../features/courier/presentation/screens/courier_orders_screen.dart';
import '../features/courier/presentation/screens/courier_statistics_screen.dart';
import '../features/courier/presentation/screens/courier_order_detail_screen.dart';
import '../features/courier/presentation/screens/security_code_input_screen.dart';
import '../features/wallet/presentation/screens/wallet_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/profile/presentation/screens/settings_screen.dart';
import '../features/chat/presentation/screens/chat_screen.dart';
import '../features/admin/presentation/screens/admin_chats_screen.dart';
import '../features/admin/presentation/screens/admin_courier_map_screen.dart';
import '../features/admin/presentation/screens/admin_couriers_screen.dart';
import '../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../features/admin/presentation/screens/admin_finance_screen.dart';
import '../features/admin/presentation/screens/admin_orders_screen.dart';
import '../features/admin/presentation/screens/admin_users_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuth = authState.isAuthenticated;
      final loc = state.uri.path;
      final isSplash = loc == '/splash';

      if (authState.isInitializing) return isSplash ? null : '/splash';

      const publicRoutes = [
        '/splash',
        '/login',
        '/register',
        '/register/client',
        '/register/courier',
        '/courier/pending',
        '/courier/rejected',
        '/debug/map',
      ];

      if (isSplash) {
        if (!isAuth) return '/login';
        if (authState.activeRole == null) return '/role-select';
        return authState.activeRole!.shellPath;
      }

      final isPublic = publicRoutes.any((r) => loc.startsWith(r));
      if (!isAuth && !isPublic) return '/login';
      if (isAuth && authState.activeRole == null && loc != '/role-select') {
        return '/role-select';
      }
      if (isAuth && loc == '/login') {
        if (authState.activeRole == null) return '/role-select';
        return authState.activeRole!.shellPath;
      }
      return null;
    },
    routes: [
      // Public routes
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
          path: '/role-select',
          builder: (_, __) => const AppRoleSelectScreen()),
      GoRoute(
        path: '/register',
        builder: (_, __) => const _BackToRoute(
          route: '/login',
          child: RoleSelectScreen(),
        ),
      ),
      GoRoute(
        path: '/register/client',
        builder: (_, __) => const _BackToRoute(
          route: '/login',
          child: ClientRegistrationScreen(),
        ),
      ),
      GoRoute(
        path: '/register/courier',
        builder: (_, __) => const _BackToRoute(
          route: '/login',
          child: CourierRegistrationScreen(),
        ),
      ),
      GoRoute(
        path: '/courier/pending',
        builder: (_, __) => const _BackToRoute(
          route: '/login',
          child: CourierPendingScreen(),
        ),
      ),
      GoRoute(
        path: '/courier/rejected',
        builder: (_, s) => _BackToRoute(
          route: '/login',
          child: CourierRejectedScreen(
            reason: s.uri.queryParameters['reason'],
          ),
        ),
      ),
      GoRoute(path: '/blocked', builder: (_, __) => const _BlockedScreen()),
      GoRoute(path: '/debug/map', builder: (_, __) => const MapDebugScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),

      GoRoute(path: '/app/customer', redirect: (_, __) => '/home'),
      GoRoute(path: '/app/courier', redirect: (_, __) => '/courier/dashboard'),

      ShellRoute(
        builder: (ctx, state, child) => _RoleShell(
          role: AppRole.moderator,
          location: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/app/moderator',
            builder: (_, __) => const AdminDashboardScreen(moderator: true),
          ),
          GoRoute(
            path: '/app/moderator/users',
            builder: (_, __) => const AdminUsersScreen(),
          ),
          GoRoute(
            path: '/app/moderator/orders',
            builder: (_, __) => const AdminOrdersScreen(moderator: true),
          ),
          GoRoute(
            path: '/app/moderator/finance',
            builder: (_, __) => const AdminFinanceScreen(),
          ),
          GoRoute(
            path: '/app/moderator/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),

      ShellRoute(
        builder: (ctx, state, child) => _RoleShell(
          role: AppRole.operator,
          location: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/app/operator',
            builder: (_, __) => const AdminOrdersScreen(moderator: false),
          ),
          GoRoute(
            path: '/app/operator/map',
            builder: (_, __) => const AdminCourierMapScreen(),
          ),
          GoRoute(
            path: '/app/operator/chats',
            builder: (_, __) => const AdminChatsScreen(),
          ),
          GoRoute(
            path: '/app/operator/courier-requests',
            builder: (_, __) => const AdminCouriersScreen(),
          ),
          GoRoute(
            path: '/app/operator/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),

      // Client shell
      ShellRoute(
        builder: (ctx, state, child) =>
            _ClientShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(
            path: '/orders',
            builder: (context, __) => OrdersListScreen(
              actorRole: 'sender',
              title: AppLocalizations.of(context)!.myShipments,
            ),
          ),
          GoRoute(
            path: '/receipts',
            builder: (context, __) => OrdersListScreen(
              actorRole: 'recipient',
              title: AppLocalizations.of(context)!.myReceipts,
            ),
          ),
          GoRoute(path: '/wallet', builder: (_, __) => const WalletScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // Client order routes (full-screen, no bottom nav)
      GoRoute(
          path: '/orders/create',
          builder: (_, __) => const CreateOrderScreen()),
      GoRoute(
          path: '/orders/preview',
          builder: (_, state) => OrderPreviewScreen(
                params: state.extra as CreateOrderParams,
              )),
      GoRoute(
          path: '/orders/address-picker',
          builder: (_, __) => const AddressPickerScreen()),
      GoRoute(
          path: '/orders/:number',
          builder: (_, s) => OrderDetailScreen(
                orderNumber: Uri.decodeComponent(s.pathParameters['number']!),
              )),
      GoRoute(
          path: '/orders/:number/pickup-code',
          builder: (_, s) => SecurityCodeDisplayScreen(
                orderNumber: Uri.decodeComponent(s.pathParameters['number']!),
                isPickup: true,
              )),
      GoRoute(
          path: '/orders/:number/delivery-code',
          builder: (_, s) => SecurityCodeDisplayScreen(
                orderNumber: Uri.decodeComponent(s.pathParameters['number']!),
                isPickup: false,
              )),
      GoRoute(
          path: '/orders/:number/history',
          builder: (_, s) => OrderHistoryScreen(
                orderNumber: Uri.decodeComponent(s.pathParameters['number']!),
              )),
      GoRoute(
          path: '/orders/:number/security-codes',
          builder: (_, s) => OrderSecurityCodesScreen(
                orderNumber: Uri.decodeComponent(s.pathParameters['number']!),
              )),
      GoRoute(
          path: '/orders/:number/public',
          builder: (_, s) => PublicOrderScreen(
                orderNumber: Uri.decodeComponent(s.pathParameters['number']!),
              )),

      // Courier shell
      ShellRoute(
        builder: (ctx, state, child) =>
            _CourierShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
              path: '/courier/dashboard',
              builder: (_, __) => const CourierDashboardScreen()),
          GoRoute(
              path: '/courier/statistics',
              builder: (_, __) => const CourierStatisticsScreen()),
          GoRoute(
              path: '/courier/orders',
              builder: (_, __) => const CourierOrdersScreen()),
          GoRoute(
              path: '/courier/wallet',
              builder: (_, __) => const WalletScreen()),
          GoRoute(
              path: '/courier/profile',
              builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // Courier order routes (full-screen)
      GoRoute(
          path: '/courier/orders/:number',
          builder: (_, s) => CourierOrderDetailScreen(
                orderNumber: Uri.decodeComponent(s.pathParameters['number']!),
              )),
      GoRoute(
          path: '/courier/orders/:number/pickup-code',
          builder: (_, s) => CourierSecurityCodeInputScreen(
                orderNumber: Uri.decodeComponent(s.pathParameters['number']!),
                isPickup: true,
              )),
      GoRoute(
          path: '/courier/orders/:number/delivery-code',
          builder: (_, s) => CourierSecurityCodeInputScreen(
                orderNumber: Uri.decodeComponent(s.pathParameters['number']!),
                isPickup: false,
              )),

      // Shared routes
      GoRoute(
          path: '/chat/:orderId',
          builder: (_, s) => ChatScreen(
                orderId: Uri.decodeComponent(s.pathParameters['orderId']!),
                title: s.uri.queryParameters['title'] ??
                    Uri.decodeComponent(s.pathParameters['orderId']!),
              )),
    ],
  );
});

// Client bottom navigation shell

class _ClientShell extends StatelessWidget {
  final String location;
  final Widget child;

  const _ClientShell({required this.location, required this.child});

  int get _selectedIndex {
    if (location.startsWith('/orders')) return 1;
    if (location.startsWith('/receipts')) return 2;
    if (location.startsWith('/wallet')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isHome = _selectedIndex == 0;
    return PopScope(
      canPop: isHome,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !isHome) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/home');
          });
        }
      },
      child: Scaffold(
        extendBody: true,
        body: child,
        bottomNavigationBar: ClipRect(
          child: BackdropFilter(
            filter: dart_ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
              child: NavigationBar(
                backgroundColor: Colors.transparent,
                selectedIndex: _selectedIndex,
                onDestinationSelected: (i) {
                  switch (i) {
                    case 0:
                      context.go('/home');
                    case 1:
                      context.go('/orders');
                    case 2:
                      context.go('/receipts');
                    case 3:
                      context.go('/wallet');
                    case 4:
                      context.go('/profile');
                  }
                },
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.home_outlined),
                    selectedIcon: const Icon(Icons.home),
                    label: AppLocalizations.of(context)!.home,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.list_alt_outlined),
                    selectedIcon: const Icon(Icons.list_alt),
                    label: AppLocalizations.of(context)!.shipments,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.move_to_inbox_outlined),
                    selectedIcon: const Icon(Icons.move_to_inbox),
                    label: AppLocalizations.of(context)!.receipts,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                    selectedIcon: const Icon(Icons.account_balance_wallet),
                    label: AppLocalizations.of(context)!.wallet,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.person_outline),
                    selectedIcon: const Icon(Icons.person),
                    label: AppLocalizations.of(context)!.profile,
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

// Courier bottom navigation shell

class _CourierShell extends StatelessWidget {
  final String location;
  final Widget child;

  const _CourierShell({required this.location, required this.child});

  int get _selectedIndex {
    if (location.startsWith('/courier/orders')) return 1;
    if (location.startsWith('/courier/wallet')) return 2;
    if (location.startsWith('/courier/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDashboard = _selectedIndex == 0;
    final l10n = AppLocalizations.of(context)!;
    
    return PopScope(
      canPop: isDashboard,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !isDashboard) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/courier/dashboard');
          });
        }
      },
      child: Scaffold(
        extendBody: true,
        body: child,
        bottomNavigationBar: ClipRect(
          child: BackdropFilter(
            filter: dart_ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
              child: NavigationBar(
                backgroundColor: Colors.transparent,
                selectedIndex: _selectedIndex,
                indicatorColor: AppColors.courierLight,
                onDestinationSelected: (i) {
                  switch (i) {
                    case 0:
                      context.go('/courier/dashboard');
                    case 1:
                      context.go('/courier/orders');
                    case 2:
                      context.go('/courier/wallet');
                    case 3:
                      context.go('/courier/profile');
                  }
                },
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.dashboard_outlined),
                    selectedIcon: const Icon(Icons.dashboard),
                    label: l10n.home,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.list_alt_outlined),
                    selectedIcon: const Icon(Icons.list_alt),
                    label: l10n.orders,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                    selectedIcon: const Icon(Icons.account_balance_wallet),
                    label: l10n.wallet,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.person_outline),
                    selectedIcon: const Icon(Icons.person),
                    label: l10n.profile,
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

class _RoleShell extends StatelessWidget {
  final AppRole role;
  final String location;
  final Widget child;

  const _RoleShell({
    required this.role,
    required this.location,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final destinations = switch (role) {
      AppRole.moderator => [
          _RoleDestination('/app/moderator', Icons.dashboard_outlined, l10n.adminDashboard),
          _RoleDestination('/app/moderator/users', Icons.people_outline, l10n.adminUsers),
          _RoleDestination('/app/moderator/orders', Icons.list_alt_outlined, l10n.orders),
          _RoleDestination('/app/moderator/finance', Icons.payments_outlined, l10n.adminFinance),
          _RoleDestination('/app/moderator/profile', Icons.person_outline, l10n.profile),
        ],
      AppRole.operator => [
          _RoleDestination('/app/operator', Icons.list_alt_outlined, l10n.orders),
          _RoleDestination('/app/operator/map', Icons.map_outlined, l10n.adminMap),
          _RoleDestination('/app/operator/chats', Icons.chat_outlined, l10n.adminChats),
          _RoleDestination('/app/operator/courier-requests', Icons.verified_user_outlined, l10n.adminRequests),
          _RoleDestination('/app/operator/profile', Icons.person_outline, l10n.profile),
        ],
      _ => <_RoleDestination>[],
    };

    final selectedIndex = _getSelectedIndex(destinations);
    final home = role.shellPath;
    final isHome = location == home;

    return PopScope(
      canPop: isHome,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !isHome) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go(home);
          });
        }
      },
      child: Scaffold(
        extendBody: true,
        body: child,
        bottomNavigationBar: ClipRect(
          child: BackdropFilter(
            filter: dart_ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
              child: NavigationBar(
                backgroundColor: Colors.transparent,
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) =>
                    context.go(destinations[index].path),
                destinations: [
                  for (final item in destinations)
                    NavigationDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.icon),
                      label: item.label,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _getSelectedIndex(List<_RoleDestination> destinations) {
    final index = destinations.indexWhere((item) => location == item.path);
    if (index >= 0) return index;
    final nestedIndex =
        destinations.indexWhere((item) => location.startsWith('${item.path}/'));
    return nestedIndex < 0 ? 0 : nestedIndex;
  }
}

class _RoleDestination {
  final String path;
  final IconData icon;
  final String label;

  const _RoleDestination(this.path, this.icon, this.label);
}

// Utility screens

class _BackToRoute extends StatelessWidget {
  final String route;
  final Widget child;

  const _BackToRoute({required this.route, required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go(route);
          });
        }
      },
      child: child,
    );
  }
}

class _BlockedScreen extends StatelessWidget {
  const _BlockedScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block, size: 80, color: AppColors.danger),
              const SizedBox(height: 16),
              Text(
                l10n.accountBlocked,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.contactSupport,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: Text(l10n.toLoginScreen),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
