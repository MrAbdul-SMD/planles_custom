import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/planning_repository.dart';
import '../models/planning.dart';

final planningRepositoryProvider = Provider<PlanningRepository>(
  (ref) => PlanningRepository(ref.watch(apiClientProvider)),
);

class PlanningPage {
  const PlanningPage({required this.total, required this.items});

  final int total;
  final List<Planning> items;

  List<Planning> get upcoming =>
      items
          .where((p) => !p.isCancelled && (p.endDate == null || !p.isPast))
          .toList()
        ..sort(_byStartAsc);

  List<Planning> get past {
    final list =
        items
            .where((p) => !p.isCancelled && p.endDate != null && p.isPast)
            .toList()
          ..sort(_byStartDesc);
    return list;
  }

  List<Planning> get cancelled {
    final list = items.where((p) => p.isCancelled).toList()..sort(_byStartDesc);
    return list;
  }

  static int _byStartAsc(Planning a, Planning b) =>
      (a.startDate ?? DateTime(2100)).compareTo(b.startDate ?? DateTime(2100));

  static int _byStartDesc(Planning a, Planning b) =>
      (b.startDate ?? DateTime(2100)).compareTo(a.startDate ?? DateTime(2100));
}

/// All plannings visible to the signed-in user (role is applied server side).
final planningListProvider = FutureProvider<PlanningPage>((ref) async {
  final repo = ref.watch(planningRepositoryProvider);
  final page = await repo.getAll(pageIndex: 0, pageSize: 100);
  return PlanningPage(total: page.total, items: page.items);
});

final planningDetailProvider = FutureProvider.autoDispose.family<Planning, int>(
  (ref, id) {
    return ref.watch(planningRepositoryProvider).getById(id);
  },
);
