import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.planningTitle),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: l10n.planningTabUpcoming),
            Tab(text: l10n.planningTabCompleted),
            Tab(text: l10n.planningTabCancelled),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _PlanningTab(selector: (p) => p.upcoming, groupByDay: true),
          _PlanningTab(selector: (p) => p.past, groupByDay: true),
          _PlanningTab(selector: (p) => p.cancelled, groupByDay: false),
        ],
      ),
    );
  }
}

class _PlanningTab extends ConsumerWidget {
  const _PlanningTab({required this.selector, required this.groupByDay});

  final List<Planning> Function(PlanningPage page) selector;

  /// Upcoming/past lessons read better when bucketed per day ("Vandaag",
  /// "Morgen", …); cancelled ones stay a flat list.
  final bool groupByDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final page = ref.watch(planningListProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(planningListProvider),
      child: AsyncView<PlanningPage>(
        value: page,
        onRetry: () => ref.invalidate(planningListProvider),
        data: (value) {
          final items = selector(value);
          if (items.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 80),
                EmptyState(
                  icon: Icons.event_busy_outlined,
                  title: l10n.planningEmptyTitle,
                  subtitle: l10n.planningEmptySubtitle,
                ),
              ],
            );
          }
          if (!groupByDay) return _flat(items);
          return _grouped(context, items);
        },
      ),
    );
  }

  Widget _flat(List<Planning> items) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => PlanningTile(planning: items[index]),
    );
  }

  Widget _grouped(BuildContext context, List<Planning> items) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final children = <Widget>[];
    DateTime? currentDay;

    for (final planning in items) {
      final dayKey = planning.startDate == null
          ? null
          : DateTime(
              planning.startDate!.year,
              planning.startDate!.month,
              planning.startDate!.day,
            );
      if (dayKey != currentDay) {
        currentDay = dayKey;
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 14, 4, 10),
            child: Text(
              planning.startDate == null
                  ? l10n.planningUnknownDate
                  : F.relativeDay(l10n, planning.startDate),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      }
      children.add(PlanningTile(planning: planning));
      children.add(const SizedBox(height: 10));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: children,
    );
  }
}
