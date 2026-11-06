import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/orders_repository.dart';
import '../models/order.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>(
  (ref) => OrdersRepository(ref.watch(apiClientProvider)),
);

class OrdersPage {
  const OrdersPage({required this.total, required this.items});

  final int total;
  final List<Order> items;
}

final ordersListProvider = FutureProvider<OrdersPage>((ref) async {
  final page = await ref
      .watch(ordersRepositoryProvider)
      .getAll(pageIndex: 0, pageSize: 100);
  return OrdersPage(total: page.total, items: page.items);
});

final orderDetailProvider = FutureProvider.autoDispose.family<Order, int>((
  ref,
  id,
) {
  return ref.watch(ordersRepositoryProvider).getById(id);
});

final orderItemsProvider = FutureProvider.autoDispose
    .family<List<OrderItem>, int>((ref, id) {
      return ref.watch(ordersRepositoryProvider).items(id);
    });

final vehiclesProvider = FutureProvider<List<Vehicle>>((ref) {
  return ref.watch(ordersRepositoryProvider).vehicles();
});

final classesProvider = FutureProvider.autoDispose
    .family<List<DrivingClass>, int>((ref, vehicleId) {
      return ref.watch(ordersRepositoryProvider).classes(vehicleId);
    });
