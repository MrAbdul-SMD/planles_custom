import 'package:flutter_test/flutter_test.dart';
import 'package:planles_custom/features/planning/models/planning.dart';
import 'package:planles_custom/features/planning/providers/planning_providers.dart';

void main() {
  group('PlanningPage filtering', () {
    test('upcoming includes only future pending and confirmed lessons', () {
      final now = DateTime.now();
      final page = PlanningPage(
        total: 4,
        items: [
          Planning(
            id: 1,
            status: 'confirmed',
            startDate: now.add(const Duration(days: 1)),
            endDate: now.add(const Duration(days: 1, hours: 1)),
          ),
          Planning(
            id: 2,
            status: 'pending',
            startDate: now.add(const Duration(days: 2)),
            endDate: now.add(const Duration(days: 2, hours: 1)),
          ),
          Planning(
            id: 3,
            status: 'completed',
            startDate: now.subtract(const Duration(days: 1)),
            endDate: now.subtract(const Duration(days: 1, hours: -1)),
          ),
          Planning(
            id: 4,
            status: 'cancelled',
            startDate: now.add(const Duration(days: 3)),
            endDate: now.add(const Duration(days: 3, hours: 1)),
          ),
        ],
      );

      expect(page.upcoming.map((p) => p.id), [1, 2]);
      expect(page.past.map((p) => p.id), [3]);
      expect(page.cancelled.map((p) => p.id), [4]);
    });

    test('completed lessons are not placed into upcoming even if endDate is future', () {
      final now = DateTime.now();
      final page = PlanningPage(
        total: 1,
        items: [
          Planning(
            id: 10,
            status: 'completed',
            startDate: now.subtract(const Duration(minutes: 30)),
            endDate: now.add(const Duration(minutes: 30)),
          ),
        ],
      );

      expect(page.upcoming, isEmpty);
      expect(page.past.map((p) => p.id), [10]);
    });
  });
}

