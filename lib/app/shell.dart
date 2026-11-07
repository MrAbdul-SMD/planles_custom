import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/notifications/providers/notifications_providers.dart';
import '../features/orders/providers/orders_providers.dart';
import '../features/planning/providers/planning_providers.dart';
import '../features/auth/providers/auth_provider.dart';
import '../l10n/l10n.dart';

/// Bottom navigation shell shared by the five primary tabs.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider).value ?? 0;
    final l10n = context.l10n;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (i) => _goBranch(i, ref),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          elevation: 0,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: l10n.navHome,
            ),
            NavigationDestination(
              icon: const Icon(Icons.event_outlined),
              selectedIcon: const Icon(Icons.event_rounded),
              label: l10n.navPlanning,
            ),
            NavigationDestination(
              icon: const Icon(Icons.receipt_long_outlined),
              selectedIcon: const Icon(Icons.receipt_long_rounded),
              label: l10n.navOrders,
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                child: const Icon(Icons.notifications_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                child: const Icon(Icons.notifications_rounded),
              ),
              label: l10n.navNotifications,
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline_rounded),
              selectedIcon: const Icon(Icons.person_rounded),
              label: l10n.navProfile,
            ),
          ],
        ),
      ),
    );
  }

  void _goBranch(int index, WidgetRef ref) {
    if (index != navigationShell.currentIndex) {
      // Refresh the destination tab's data on every visit.
      switch (index) {
        case 0:
          ref.invalidate(planningListProvider);
          ref.invalidate(ordersListProvider);
          ref.invalidate(unreadCountProvider);
          ref.read(authControllerProvider.notifier).refreshUser();
        case 1:
          ref.invalidate(planningListProvider);
        case 2:
          ref.invalidate(ordersListProvider);
        case 3:
          ref.invalidate(notificationsProvider);
          ref.invalidate(unreadCountProvider);
        case 4:
          ref.read(authControllerProvider.notifier).refreshUser();
      }
    }
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
