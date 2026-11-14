import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/responsive.dart';
import '../../../core/utils/formatters.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets.dart';
import '../../dashboard/screens/dashboard_screen.dart' show PlanningTile;
import '../models/planning.dart';
import '../providers/planning_providers.dart';

class PlanningListScreen extends ConsumerStatefulWidget {
  const PlanningListScreen({super.key});

  @override
  ConsumerState<PlanningListScreen> createState() => _PlanningListScreenState();
}

class _PlanningListScreenState extends ConsumerState<PlanningListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pageAsync = ref.watch(planningListProvider);

    final upcomingCount = pageAsync.value?.upcoming.length ?? 0;
    final completedCount = pageAsync.value?.past.length ?? 0;
    final cancelledCount = pageAsync.value?.cancelled.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.planningTitle),
        actions: [
          IconButton(
            tooltip: l10n.retry,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(planningListProvider),
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.planningTabUpcoming),
                  if (upcomingCount > 0) ...[
                    const SizedBox(width: 6),
                    _CountBadge(count: upcomingCount, active: true),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.planningTabCompleted),
                  if (completedCount > 0) ...[
                    const SizedBox(width: 6),
                    _CountBadge(count: completedCount, active: false),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.planningTabCancelled),
                  if (cancelledCount > 0) ...[
                    const SizedBox(width: 6),
                    _CountBadge(count: cancelledCount, active: false),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: TabBarView(
          controller: _tabs,
          children: [
            _PlanningTab(
              selector: (p) => p.upcoming,
              groupByDay: true,
              isUpcoming: true,
            ),
            _PlanningTab(
              selector: (p) => p.past,
              groupByDay: true,
              isUpcoming: false,
            ),
            _PlanningTab(
              selector: (p) => p.cancelled,
              groupByDay: false,
              isUpcoming: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.active});

  final int count;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: active
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: active
              ? theme.colorScheme.onPrimaryContainer
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _PlanningTab extends ConsumerWidget {
  const _PlanningTab({
    required this.selector,
    required this.groupByDay,
    required this.isUpcoming,
  });

  final List<Planning> Function(PlanningPage page) selector;
  final bool groupByDay;
  final bool isUpcoming;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final page = ref.watch(planningListProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(planningListProvider);
        await ref.read(planningListProvider.future);
      },
      child: AsyncView<PlanningPage>(
        value: page,
        onRetry: () => ref.invalidate(planningListProvider),
        data: (value) {
          final items = selector(value);
          if (items.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 60),
                EmptyState(
                  icon: Icons.event_available_outlined,
                  title: l10n.planningEmptyTitle,
                  subtitle: l10n.planningEmptySubtitle,
                ),
                if (isUpcoming) ...[
                  const SizedBox(height: 20),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/orders'),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(l10n.dashboardBuyLessons),
                    ),
                  ),
                ],
              ],
            );
          }
          if (!groupByDay) return _flat(context, items);
          return _grouped(context, items);
        },
      ),
    );
  }

  Widget _flat(BuildContext context, List<Planning> items) {
    final wide = context.isExpanded;
    if (wide) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth >= 1200 ? 3 : 2;
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisExtent: 112,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) =>
                PlanningTile(planning: items[index]),
          );
        },
      );
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) => PlanningTile(planning: items[index]),
        ),
      ),
    );
  }

  Widget _grouped(BuildContext context, List<Planning> items) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final children = <Widget>[];
    DateTime? currentDay;
    bool hadUnknownDate = false;

    for (final planning in items) {
      if (planning.startDate == null) {
        if (!hadUnknownDate) {
          hadUnknownDate = true;
          children.add(
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 10),
              child: Text(
                l10n.planningUnknownDate,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }
      } else {
        final dayKey = DateTime(
          planning.startDate!.year,
          planning.startDate!.month,
          planning.startDate!.day,
        );
        if (currentDay == null || dayKey != currentDay) {
          currentDay = dayKey;
          children.add(
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 10),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    F.relativeDay(l10n, planning.startDate),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Divider(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
      children.add(PlanningTile(planning: planning));
      children.add(const SizedBox(height: 10));
    }

    final wide = context.isExpanded;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: wide ? 8 : 0),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: wide ? 1400 : 900),
        child: ListView(
          padding: EdgeInsets.fromLTRB(wide ? 20 : 20, 6, wide ? 20 : 20, 32),
          children: children,
        ),
      ),
    );
  }
}
