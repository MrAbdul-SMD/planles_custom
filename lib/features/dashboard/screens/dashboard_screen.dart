import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets.dart';
import '../../auth/models/user.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/providers/notifications_providers.dart';
import '../../orders/providers/orders_providers.dart';
import '../../planning/models/planning.dart';
import '../../planning/providers/planning_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    await Future.wait([
      ref.refresh(planningListProvider.future),
      ref.refresh(ordersListProvider.future),
      ref.refresh(unreadCountProvider.future),
      ref.read(authControllerProvider.notifier).refreshUser(),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final planning = ref.watch(planningListProvider);
    final unread = ref.watch(unreadCountProvider).value ?? 0;
    final notifications = ref
        .watch(notificationsProvider)
        .items
        .take(2)
        .toList();

    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_greeting(l10n, user)),
        actions: [
          IconButton(
            tooltip: l10n.navNotifications,
            onPressed: () => context.go('/notifications'),
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _BalanceCard(user: user),
            const SizedBox(height: 20),
            SectionHeader(
              l10n.dashboardUpcomingLessons,
              trailing: TextButton(
                onPressed: () => context.go('/planning'),
                child: Text(l10n.dashboardViewAll),
              ),
            ),
            planning.when(
              skipLoadingOnReload: true,
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => ErrorView(
                message: describeError(context, e),
                onRetry: () => ref.invalidate(planningListProvider),
              ),
              data: (page) {
                final upcoming = page.upcoming.take(3).toList();
                if (upcoming.isEmpty) {
                  return const _NoLessons();
                }
                return Column(
                  children: [
                    for (final p in upcoming) ...[
                      PlanningTile(planning: p),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            SectionHeader(l10n.dashboardQuickActions),
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.add_shopping_cart_outlined,
                    label: l10n.dashboardBuyLessons,
                    onTap: () => context.push('/orders/new'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.account_balance_wallet_outlined,
                    label: l10n.dashboardTopUpBalance,
                    onTap: () => context.push('/balance/topup'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.receipt_long_outlined,
                    label: l10n.navOrders,
                    onTap: () => context.go('/orders'),
                  ),
                ),
              ],
            ),
            if (user?.isInstructor == true) ...[
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.groups_outlined,
                label: l10n.studentsTitle,
                onTap: () => context.push('/students'),
              ),
            ],
            if (notifications.isNotEmpty) ...[
              const SizedBox(height: 24),
              SectionHeader(
                l10n.dashboardRecentNotifications,
                trailing: TextButton(
                  onPressed: () => context.go('/notifications'),
                  child: Text(l10n.dashboardAllNotifications),
                ),
              ),
              for (final n in notifications)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      n.isRead
                          ? Icons.notifications_none_rounded
                          : Icons.notifications_active_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    n.title ?? l10n.dashboardNotificationFallback,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    n.body ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: n.createdAt == null
                      ? null
                      : Text(
                          F.relativeDay(l10n, n.createdAt),
                          style: theme.textTheme.bodySmall,
                        ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _greeting(AppLocalizations l10n, User? user) {
    final hour = DateTime.now().hour;
    final base = hour < 12
        ? l10n.dashboardGreetingMorning
        : hour < 18
        ? l10n.dashboardGreetingAfternoon
        : l10n.dashboardGreetingEvening;
    final name = user?.firstName;
    return (name == null || name.isEmpty) ? base : '$base, $name';
  }
}

class _BalanceCard extends ConsumerWidget {
  const _BalanceCard({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${l10n.dashboardHello} ${user?.firstName ?? ''}'.trim(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              AppAvatar(initials: user?.initials ?? '?', size: 40),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            l10n.dashboardBalanceLabel,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            F.money(user?.balance ?? 0),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () => context.push('/balance/topup'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: theme.colorScheme.primary,
              minimumSize: const Size.fromHeight(46),
            ),
            child: Text(l10n.dashboardTopUpBalance),
          ),
        ],
      ),
    );
  }
}

class _NoLessons extends StatelessWidget {
  const _NoLessons();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 34,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(l10n.dashboardNoLessonsTitle),
          const SizedBox(height: 4),
          Text(
            l10n.dashboardNoLessonsSubtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => context.push('/orders/new'),
            icon: const Icon(Icons.add),
            label: Text(l10n.dashboardBuyLessons),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      mouseCursor: SystemMouseCursors.click,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact lesson row used on the dashboard and the planning tab.
class PlanningTile extends StatelessWidget {
  const PlanningTile({super.key, required this.planning, this.trailing});

  final Planning planning;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final start = planning.startDate;
    final end = planning.endDate;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        mouseCursor: SystemMouseCursors.click,
        onTap: () => context.push('/planning/${planning.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 58,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      start == null ? '–' : F.dayLabel(l10n, start),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      start == null ? '' : F.time(start),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      planning.drivingClass?.name ??
                          l10n.dashboardLessonFallback,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (end != null && start != null)
                          '${F.time(start)} – ${F.time(end)}',
                        if (planning.instructor != null)
                          planning.instructor!.displayName(l10n),
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ??
                  StatusChip(
                    label: planning.statusLabel(l10n),
                    tone: PlanningTone.forStatus(planning.status),
                  ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
