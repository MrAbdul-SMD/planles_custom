import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/responsive.dart';
import '../core/update/app_update_prompt.dart';
import '../features/notifications/providers/notifications_providers.dart';
import '../features/orders/providers/orders_providers.dart';
import '../features/planning/providers/planning_providers.dart';
import '../features/auth/providers/auth_provider.dart';
import '../l10n/l10n.dart';
import '../shared/widgets.dart';

/// Adaptive navigation shell: bottom bar on compact screens, navigation rail on
/// wider (tablet/desktop/web) screens.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppUpdatePrompt.checkAndPrompt(
        context,
        includePrereleases: true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final navigationShell = widget.navigationShell;
    final unread = ref.watch(unreadCountProvider).value ?? 0;
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final useRail = context.useSideNav;

    final destinations = _destinations(l10n, unread);

    if (useRail) {
      final extended = context.screenWidth >= Breakpoints.expanded;
      return Scaffold(
        body: Column(
          children: [
            const ConnectivityBanner(),
            Expanded(
              child: Row(
                children: [
                  SafeArea(
                    right: false,
                    child: Container(
                      color: theme.colorScheme.surfaceContainerLow,
                      child: NavigationRail(
                        extended: extended,
                        minExtendedWidth: 220,
                        backgroundColor: Colors.transparent,
                        selectedIndex: navigationShell.currentIndex,
                        onDestinationSelected: (i) => _goBranch(i, ref),
                        indicatorColor: theme.colorScheme.primaryContainer,
                        labelType: extended
                            ? NavigationRailLabelType.none
                            : NavigationRailLabelType.all,
                        selectedIconTheme: IconThemeData(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        selectedLabelTextStyle:
                            theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                        unselectedLabelTextStyle:
                            theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        leading: extended
                            ? Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 12, 12, 20),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(Icons.school_rounded,
                                          color: theme.colorScheme.primary),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Planles',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Padding(
                                padding:
                                    const EdgeInsets.only(top: 8, bottom: 12),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.school_rounded,
                                      color: theme.colorScheme.primary),
                                ),
                              ),
                        destinations: [
                          for (final d in destinations)
                            NavigationRailDestination(
                              icon: d.icon,
                              selectedIcon: d.selectedIcon,
                              label: Text(d.label),
                            ),
                        ],
                      ),
                    ),
                  ),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: theme.colorScheme.outlineVariant
                        .withValues(alpha: 0.4),
                  ),
                  Expanded(child: navigationShell),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      body: Column(
        children: [
          const ConnectivityBanner(),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        bottom: true,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF131B2E).withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(
                alpha: isDark ? 0.35 : 0.6,
              ),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                blurRadius: 20,
                offset: const Offset(0, 4),
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
            destinations: destinations,
          ),
        ),
      ),
    );
  }

  List<NavigationDestination> _destinations(AppLocalizations l10n, int unread) {
    return [
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
    ];
  }

  void _goBranch(int index, WidgetRef ref) {
    final navigationShell = widget.navigationShell;
    if (index != navigationShell.currentIndex) {
      switch (index) {
        case 0:
          ref.invalidate(planningListProvider);
          ref.invalidate(ordersListProvider);
          ref.invalidate(unreadCountProvider);
          ref.read(authControllerProvider.notifier).refreshUser();
          break;
        case 1:
          ref.invalidate(planningListProvider);
          break;
        case 2:
          ref.invalidate(ordersListProvider);
          break;
        case 3:
          ref.read(notificationsProvider.notifier).refresh().ignore();
          ref.invalidate(unreadCountProvider);
          break;
        case 4:
          ref.read(authControllerProvider.notifier).refreshUser();
          break;
      }
    }
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
