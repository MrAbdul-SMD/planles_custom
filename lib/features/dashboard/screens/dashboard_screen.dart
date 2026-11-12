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
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
            children: [
            // ------------------------------------------------ Titanium Balance Card
            _BalanceTelemetryCard(user: user),
            const SizedBox(height: 24),

            // ------------------------------------------------ Next Drive / Upcoming
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
                final upcoming = page.upcoming;
                if (upcoming.isEmpty) {
                  return const _NoLessons();
                }
                final firstLesson = upcoming.first;
                final otherLessons = upcoming.skip(1).take(2).toList();

                return Column(
                  children: [
                    _NextLessonBoardingPass(planning: firstLesson),
                    if (otherLessons.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      for (final p in otherLessons) ...[
                        PlanningTile(planning: p),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // ------------------------------------------------ Cockpit Quick Actions
            SectionHeader(l10n.dashboardQuickActions),
            Row(
              children: [
                Expanded(
                  child: _TactileActionCard(
                    icon: Icons.add_shopping_cart_rounded,
                    label: l10n.dashboardBuyLessons,
                    subtitle: 'Pakket of losse les',
                    onTap: () => context.push('/orders/new'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TactileActionCard(
                    icon: Icons.account_balance_wallet_rounded,
                    label: l10n.dashboardTopUpBalance,
                    subtitle: 'iDEAL direct',
                    onTap: () => context.push('/balance/topup'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TactileActionCard(
                    icon: Icons.receipt_long_rounded,
                    label: l10n.navOrders,
                    subtitle: 'Facturen & status',
                    onTap: () => context.go('/orders'),
                  ),
                ),
              ],
            ),
            if (user?.isInstructor == true) ...[
              const SizedBox(height: 10),
              _TactileActionCard(
                icon: Icons.groups_rounded,
                label: l10n.studentsTitle,
                subtitle: 'Bekijk leerlingendossiers & vorderingen',
                onTap: () => context.push('/students'),
                horizontal: true,
              ),
            ],

            // ------------------------------------------------ Notifications Preview
            if (notifications.isNotEmpty) ...[
              const SizedBox(height: 28),
              SectionHeader(
                l10n.dashboardRecentNotifications,
                trailing: TextButton(
                  onPressed: () => context.go('/notifications'),
                  child: Text(l10n.dashboardAllNotifications),
                ),
              ),
              for (final n in notifications)
                Card(
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        n.isRead
                            ? Icons.notifications_none_rounded
                            : Icons.notifications_active_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      n.title ?? l10n.dashboardNotificationFallback,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
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
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                  ),
                ),
            ],
          ],
        ),
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

/// Matte titanium membership card with telemetry styling.
class _BalanceTelemetryCard extends ConsumerWidget {
  const _BalanceTelemetryCard({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFF0F4C81), const Color(0xFF02679E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF0F4C81)).withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars_rounded, size: 14, color: Color(0xFFFDBA74)),
                    const SizedBox(width: 5),
                    Text(
                      user?.isInstructor == true ? 'INSTRUCTEUR' : 'LEERLINGPAS',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              AppAvatar(initials: user?.initials ?? '?', size: 36),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            l10n.dashboardBalanceLabel.toUpperCase(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                F.money(user?.balance ?? 0),
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () => context.push('/balance/topup'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0F4C81),
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_rounded, size: 18),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          l10n.dashboardTopUpBalance,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  tooltip: l10n.dashboardBuyLessons,
                  icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                  onPressed: () => context.push('/orders/new'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Editorial Boarding-Pass style upcoming lesson card.
class _NextLessonBoardingPass extends StatelessWidget {
  const _NextLessonBoardingPass({required this.planning});

  final Planning planning;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final start = planning.startDate;
    final end = planning.endDate;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.6),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            onTap: () => context.push('/planning/${planning.id}'),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'VOLGENDE LES',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onPrimaryContainer,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      StatusChip(
                        label: planning.statusLabel(l10n),
                        tone: PlanningTone.forStatus(planning.status),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date block
                      Container(
                        width: 64,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            Text(
                              start == null ? '–' : F.dayLabel(l10n, start),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              start == null ? '' : '${start.day}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
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
                              planning.drivingClass?.name ?? l10n.dashboardLessonFallback,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              [
                                if (start != null && end != null)
                                  '${F.time(start)} – ${F.time(end)}',
                                if (planning.durationMinutes > 0)
                                  F.minutesLabel(l10n, planning.durationMinutes),
                              ].join(' · '),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (planning.instructor != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  AppAvatar(
                                    initials: planning.instructor!.initials,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    planning.instructor!.displayName(l10n),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Flexible(
                  child: TextButton.icon(
                    onPressed: () => context.push('/planning/${planning.id}'),
                    icon: const Icon(Icons.info_outline_rounded, size: 16),
                    label: const Text(
                      'Details bekijken',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        context.push('/planning/${planning.id}/reschedule'),
                    icon: const Icon(Icons.event_repeat_rounded, size: 16),
                    label: Text(
                      l10n.planningRescheduleLesson,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
              ],
            ),
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
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_available_rounded,
              size: 28,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.dashboardNoLessonsTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.dashboardNoLessonsSubtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () => context.push('/orders/new'),
            child: Text(l10n.dashboardBuyLessons),
          ),
        ],
      ),
    );
  }
}

class _TactileActionCard extends StatelessWidget {
  const _TactileActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.horizontal = false,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      mouseCursor: SystemMouseCursors.click,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.5),
            width: 1,
          ),
        ),
        child: horizontal
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: theme.colorScheme.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.outline,
                    size: 18,
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: theme.colorScheme.primary, size: 20),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Ticket-style planning card for lesson lists and timeline.
class PlanningTile extends StatelessWidget {
  const PlanningTile({super.key, required this.planning, this.trailing});

  final Planning planning;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final start = planning.startDate;
    final end = planning.endDate;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        mouseCursor: SystemMouseCursors.click,
        onTap: () => context.push('/planning/${planning.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Ticket Date Pill
              Container(
                width: 58,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.4),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      start == null ? '–' : F.dayLabel(l10n, start),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      start == null ? '' : F.time(start),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            planning.drivingClass?.name ?? l10n.dashboardLessonFallback,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.planningNumber(planning.id),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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
              Flexible(
                child: trailing ??
                    StatusChip(
                      label: planning.statusLabel(l10n),
                      tone: PlanningTone.forStatus(planning.status),
                    ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.outline,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
