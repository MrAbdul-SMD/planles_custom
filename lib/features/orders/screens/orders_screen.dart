import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/widgets.dart';
import '../models/order.dart';
import '../providers/orders_providers.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bestellingen')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/orders/new'),
        icon: const Icon(Icons.add),
        label: const Text('Kopen'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(ordersListProvider),
        child: AsyncView<OrdersPage>(
          value: orders,
          onRetry: () => ref.invalidate(ordersListProvider),
          data: (page) {
            if (page.items.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 80),
                  EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Nog geen bestellingen',
                    subtitle:
                        'Koop je eerste lespakket om lessen in te plannen.',
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              itemCount: page.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _OrderCard(order: page.items[index]),
            );
          },
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final payment = order.payment;
    final (label, tone) = switch (payment?.status) {
      'paid' => ('Betaald', StatusTone.success),
      'open' => ('Open', StatusTone.warning),
      'pending' => ('In behandeling', StatusTone.info),
      'failed' => ('Mislukt', StatusTone.danger),
      'canceled' => ('Geannuleerd', StatusTone.danger),
      'expired' => ('Verlopen', StatusTone.danger),
      _ => ('Nog niet betaald', StatusTone.neutral),
    };

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/orders/${order.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Bestelling #${order.id}',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  StatusChip(label: label, tone: tone),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                [
                  if (order.createdAt != null) F.dateTime(order.createdAt),
                  if (order.student != null) order.student!.fullName,
                ].join(' · '),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (payment?.finalAmountValue != null) ...[
                    Text(
                      F.money(payment!.finalAmountValue),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (order.totalDuration != null)
                    Text(
                      '${F.minutesLabel(order.totalDuration!)} les',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.outline,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
