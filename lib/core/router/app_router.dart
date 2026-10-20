import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/budget/presentation/add_savings_screen.dart';
import '../../features/budget/presentation/budgets_screen.dart';
import '../../features/cards/presentation/add_card_screen.dart';
import '../../features/cards/presentation/cards_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/reports/presentation/stats_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/transactions/presentation/add_transaction_screen.dart';
import '../../features/transactions/presentation/categories_screen.dart';
import '../../features/transactions/presentation/transaction_detail_screen.dart';
import '../../shared/widgets/glass_bottom_nav.dart';
import '../../shared/widgets/glass_fab.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    routes: [
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const HomeScreen(),
              transitionsBuilder: _fadeSlide,
            ),
          ),
          GoRoute(
            path: '/stats',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const StatsScreen(),
              transitionsBuilder: _fadeSlide,
            ),
          ),
          GoRoute(
            path: '/cards',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const CardsScreen(),
              transitionsBuilder: _fadeSlide,
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const SettingsScreen(),
              transitionsBuilder: _fadeSlide,
            ),
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/transactions/add',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AddTransactionScreen(),
          transitionsBuilder: _slideUp,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/transactions/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return CustomTransitionPage(
            key: state.pageKey,
            transitionDuration: const Duration(milliseconds: 180),
            reverseTransitionDuration: const Duration(milliseconds: 140),
            child: TransactionDetailScreen(transactionId: id),
            transitionsBuilder: _slideUp,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/cards/add',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AddCardScreen(),
          transitionsBuilder: _slideUp,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/cards/edit/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: AddCardScreen(cardId: id),
            transitionsBuilder: _slideUp,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/categories',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CategoriesScreen(),
          transitionsBuilder: _slideUp,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/budgets',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const BudgetsScreen(),
          transitionsBuilder: _slideUp,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/savings/add',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AddSavingsScreen(),
          transitionsBuilder: _slideUp,
        ),
      ),
    ],
  );
}

Widget _fadeSlide(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
  return FadeTransition(
    opacity: curved,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.04, 0),
        end: Offset.zero,
      ).animate(curved),
      child: child,
    ),
  );
}

Widget _slideUp(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(curved),
    child: FadeTransition(opacity: curved, child: child),
  );
}

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    NavItem(
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
      label: 'Stats',
    ),
    NavItem(
      icon: Icons.credit_card_outlined,
      activeIcon: Icons.credit_card,
      label: 'Card',
    ),
    NavItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'Settings',
    ),
  ];

  static const _paths = ['/', '/stats', '/cards', '/settings'];

  int _indexForLocation(String location) {
    final i = _paths.indexWhere((p) => location == p || location.startsWith('$p/'));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _indexForLocation(location);

    return Scaffold(
      body: child,
      extendBody: true,
      floatingActionButton: location == '/stats' || location == '/'
          ? GlassFab(
              onPressed: () => context.push('/transactions/add'),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: GlassBottomNav(
        items: _tabs,
        currentIndex: index,
        onTap: (i) {
          if (i != index) context.go(_paths[i]);
        },
      ),
    );
  }
}
