import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets.dart';
import '../../dashboard/screens/dashboard_screen.dart' show PlanningTile;
import '../models/planning.dart';
import '../providers/planning_providers.dart';

class PlanningListScreen extends ConsumerStatefulWidget {
  const PlanningListScreen({super.key});

  @override
  ConsumerState<PlanningListScreen> createState() =>
      _PlanningListScreenState();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planning'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Aankomend'),
            Tab(text: 'Afgerond'),
            Tab(text: 'Geannuleerd'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _PlanningTab(selector: (p) => p.upcoming),
          _PlanningTab(selector: (p) => p.past),
          _PlanningTab(selector: (p) => p.cancelled),
        ],
      ),
    );
  }
}

class _PlanningTab extends ConsumerWidget {
  const _PlanningTab({required this.selector});

  final List<Planning> Function(PlanningPage page) selector;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              children: const [
                SizedBox(height: 80),
                EmptyState(
                  icon: Icons.event_busy_outlined,
                  title: 'Niets te vinden',
                  subtitle: 'Er staan nog geen lessen in deze categorie.',
                ),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                PlanningTile(planning: items[index]),
          );
        },
      ),
    );
  }
}
