import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/responsive.dart';
import '../../../core/utils/formatters.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets.dart';
import '../models/order.dart';
import '../providers/orders_providers.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final orders = ref.watch(ordersListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.ordersTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/orders/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.ordersBuyButton),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () async => ref.refresh(ordersListProvider.future),
          child: AsyncView<OrdersPage>(
          value: orders,
          onRetry: () => ref.refresh(ordersListProvider.future),
          data: (page) {
            if (page.items.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: l10n.ordersEmptyTitle,
                    subtitle: l10n.ordersEmptySubtitle,
                  ),
                ],
              );
            }
            final wide = context.isExpanded;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: wide
                    ? GridView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 96),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 480,
                          mainAxisExtent: 170,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: page.items.length,
                        itemBuilder: (context, index) =>
                            _OrderCard(order: page.items[index]),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                        itemCount: page.items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) =>
                            _OrderCard(order: page.items[index]),
                      ),
              ),
            );
          },
          ),
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
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final payment = order.payment;
    final (label, tone) = switch (payment?.status) {
      'paid' => (l10n.ordersPaymentPaid, StatusTone.success),
      'open' => (l10n.ordersPaymentOpen, StatusTone.warning),
      'pending' => (l10n.ordersPaymentPending, StatusTone.info),
      'failed' => (l10n.ordersPaymentFailed, StatusTone.danger),
      'canceled' => (l10n.ordersPaymentCanceled, StatusTone.danger),
      'expired' => (l10n.ordersPaymentExpired, StatusTone.danger),
      _ => (l10n.ordersPaymentUnpaid, StatusTone.neutral),
    };

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        mouseCursor: SystemMouseCursors.click,
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
                      l10n.ordersOrderNumber(order.id),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  StatusChip(label: label, tone: tone),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                [
                  if (order.createdAt != null) F.dateTime(order.createdAt),
                  if (order.student != null) order.student!.displayName(l10n),
                ].join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (payment?.finalAmountValue != null) ...[
                    Text(
                      F.money(payment!.finalAmountValue),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (order.totalDuration != null)
                    Text(
                      l10n.ordersTotalDuration(
                        F.minutesLabel(l10n, order.totalDuration!),
                      ),
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
