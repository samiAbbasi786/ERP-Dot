import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/pos/presentation/pos_screen.dart';
import '../../features/inventory/presentation/products_screen.dart';
import '../../features/sales/presentation/sales_screen.dart';
import '../../features/purchasing/presentation/purchasing_screen.dart';
import '../../features/vendors/presentation/vendors_screen.dart';
import '../../features/accounting/presentation/accounting_screen.dart';
import '../../features/admin/presentation/users_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../providers/app_providers.dart';
import '../services/role_service.dart';

final router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/pos',
          builder: (context, state) => const PosScreen(),
        ),
        GoRoute(
          path: '/inventory',
          builder: (context, state) => const ProductsScreen(),
        ),
        GoRoute(
          path: '/sales',
          builder: (context, state) => const SalesScreen(),
        ),
        GoRoute(
          path: '/purchasing',
          builder: (context, state) => const PurchasingScreen(),
        ),
        GoRoute(
          path: '/vendors',
          builder: (context, state) => const VendorsScreen(),
        ),
        GoRoute(
          path: '/accounting',
          builder: (context, state) => const AccountingScreen(),
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => const UsersScreen(),
        ),
      ],
    ),
  ],
);

class _NavigationItem {
  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final UserPermission? requiredPermission;

  const _NavigationItem({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.requiredPermission,
  });
}

class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  List<_NavigationItem> get _allNavigationItems => const [
        _NavigationItem(
          path: '/',
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          requiredPermission: null, // Everyone can see dashboard
        ),
        _NavigationItem(
          path: '/pos',
          label: 'POS',
          icon: Icons.point_of_sale_outlined,
          selectedIcon: Icons.point_of_sale,
          requiredPermission: UserPermission.manageSales,
        ),
        _NavigationItem(
          path: '/inventory',
          label: 'Inventory',
          icon: Icons.inventory_2_outlined,
          selectedIcon: Icons.inventory_2,
          requiredPermission: UserPermission.viewInventory,
        ),
        _NavigationItem(
          path: '/sales',
          label: 'Sales',
          icon: Icons.shopping_cart_outlined,
          selectedIcon: Icons.shopping_cart,
          requiredPermission: UserPermission.viewSales,
        ),
        _NavigationItem(
          path: '/purchasing',
          label: 'Purchasing',
          icon: Icons.shopping_bag_outlined,
          selectedIcon: Icons.shopping_bag,
          requiredPermission: UserPermission.manageInventory, // Requires inventory management
        ),
        _NavigationItem(
          path: '/vendors',
          label: 'Vendors',
          icon: Icons.business_outlined,
          selectedIcon: Icons.business,
          requiredPermission: UserPermission.manageInventory,
        ),
        _NavigationItem(
          path: '/accounting',
          label: 'Accounting',
          icon: Icons.account_balance_outlined,
          selectedIcon: Icons.account_balance,
          requiredPermission: UserPermission.viewReports, // Only managers and admins
        ),
        _NavigationItem(
          path: '/admin',
          label: 'Admin',
          icon: Icons.admin_panel_settings_outlined,
          selectedIcon: Icons.admin_panel_settings,
          requiredPermission: UserPermission.manageUsers, // Only admins
        ),
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    
    // Filter navigation items based on user permissions
    final allowedItems = _allNavigationItems.where((item) {
      if (item.requiredPermission == null) return true;
      return currentUser?.hasPermission(item.requiredPermission!) ?? false;
    }).toList();

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: true,
            selectedIndex: _getSelectedIndex(context, allowedItems),
            onDestinationSelected: (index) => _onDestinationSelected(context, index, allowedItems),
            destinations: allowedItems.map((item) {
              return NavigationRailDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: Text(item.label),
              );
            }).toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

  int _getSelectedIndex(BuildContext context, List<_NavigationItem> items) {
    final location = GoRouterState.of(context).uri.path;
    for (var i = 0; i < items.length; i++) {
      if (location == items[i].path || 
          (items[i].path != '/' && location.startsWith(items[i].path))) {
        return i;
      }
    }
    return 0;
  }

  void _onDestinationSelected(BuildContext context, int index, List<_NavigationItem> items) {
    if (index >= 0 && index < items.length) {
      context.go(items[index].path);
    }
  }
}
