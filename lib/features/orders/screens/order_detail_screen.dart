
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/deep_links.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/order.dart';
import '../providers/orders_providers.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.id});

  final int id;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, {String? success}) async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(orderDetailProvider(widget.id));
      ref.invalidate(orderItemsProvider(widget.id));
      ref.invalidate(ordersListProvider);
      ref.read(authControllerProvider.notifier).refreshUser();
      if (mounted) {
        showAppSnack(context, success ?? l10n.genericSuccess);
      }
    } on ApiException catch (e) {
      if (mounted) {
        showAppSnack(context, describeError(context, e), error: true);
        }
    } catch (e) {
      if (mounted) {
        showAppSnack(context, describeError(context, e), error: true);
        }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pay() async {
    final url = await _checkout(
      () => ref
          .read(ordersRepositoryProvider)
          .pay(orderId: widget.id, redirectUrl: paymentRedirectUrl(kind: paymentRedirectKind)),
    );
    if (url != null) await _open(url);
  }

  Future<String?> _checkout(Future<String?> Function() call) async {
    setState(() => _busy = true);
    try {
      return await call();
    } on ApiException catch (e) {
      if (mounted) {
        showAppSnack(context, describeError(context, e), error: true);
        }
      return null;
    } catch (e) {
      if (mounted) {
        showAppSnack(context, describeError(context, e), error: true);
        }
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      showAppSnack(
        context,
        context.l10n.orderDetailPaymentPageFailed,
        error: true,
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final async = ref.watch(orderDetailProvider(widget.id));
    final items = ref.watch(orderItemsProvider(widget.id));
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.orderDetailTitle(widget.id))),
      body: AsyncView<Order>(
        value: async,
        onRetry: () => ref.invalidate(orderDetailProvider(widget.id)),
        data: (order) {
          final payment = order.payment;
          final (label, tone) = _paymentTone(payment, l10n);
          final isStudent = user?.isInstructor != true;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.orderDetailTitle(order.id),
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        StatusChip(label: label, tone: tone),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      payment?.finalAmountValue != null
                          ? F.money(payment!.finalAmountValue)
                          : '–',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                    if (order.createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.orderDetailPlacedOn(F.dateTime(order.createdAt)),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer
                              .withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              SectionHeader(l10n.orderDetailSectionDetails),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      InfoRow(
                        l10n.orderDetailStudent,
                        order.student?.displayName(l10n) ?? '–',
                      ),
                      InfoRow(
                        l10n.orderDetailInstructor,
                        order.instructor?.displayName(l10n) ?? '–',
                      ),
                      if (order.totalDuration != null)
                        InfoRow(
                          l10n.orderDetailTotal,
                          F.minutesLabel(l10n, order.totalDuration!),
                        ),
                      if (order.reservedDuration != null)
                        InfoRow(
                          l10n.orderDetailScheduled,
                          F.minutesLabel(l10n, order.reservedDuration!),
                        ),
                      if (order.availableDuration != null)
                        InfoRow(
                          l10n.orderDetailAvailable,
                          F.minutesLabel(l10n, order.availableDuration!),
                        ),
                      InfoRow(
                        l10n.orderDetailPaymentMethod,
                        switch (payment?.type) {
                          'digital' => l10n.orderDetailPaymentDigital,
                          'cash' => l10n.orderDetailPaymentCash,
                          'balance' => l10n.orderDetailPaymentBalance,
                          _ => '–',
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              SectionHeader(l10n.orderDetailSectionLessons),
              items.when(
                skipLoadingOnReload: true,
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => ErrorView(
                  message: describeError(context, e),
                  onRetry: () => ref.invalidate(orderItemsProvider(widget.id)),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(l10n.orderDetailNoLessons),
                      ),
                    );
                  }
                  return Card(
                    child: Column(
                      children: [
                        for (final (i, item) in list.indexed) ...[
                          if (i > 0) const Divider(),
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            title: Text(
                              item.drivingClass?.name ?? l10n.orderDetailLesson,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  [
                                    l10n.orderDetailLessonCount(
                                      item.quantity ?? 0,
                                    ),
                                    if (item.drivingClass?.duration != null)
                                      F.durationLabel(
                                        l10n,
                                        item.drivingClass!.duration,
                                      ),
                                    if (item.drivingClass?.priceValue != null)
                                      F.money(item.drivingClass!.priceValue),
                                  ].join(' · '),
                                ),
                                if (item.availableDuration != null) ...[
                                  const SizedBox(height: 6),
                                  StatusChip(
                                    label: l10n.orderDetailMinutesAvailable(
                                      F.minutesLabel(
                                        l10n,
                                        item.availableDuration!,
                                      ),
                                    ),
                                    tone: item.availableDuration! > 0
                                        ? StatusTone.success
                                        : StatusTone.neutral,
                                  ),
                                ],
                              ],
                            ),
                            isThreeLine: true,
                            trailing: (item.availableDuration ?? 0) > 0
                                ? TextButton(
                                    onPressed: () => context.push(
                                      '/schedule/${widget.id}/${item.id}',
                                    ),
                                    child: Text(l10n.orderDetailScheduleButton),
                                  )
                                : null,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),
              SectionHeader(l10n.orderDetailSectionActions),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                if (payment?.isPaid != true) ...[
                  FilledButton.icon(
                    onPressed: _pay,
                    icon: const Icon(Icons.payment_rounded),
                    label: Text(
                      isStudent
                          ? l10n.orderDetailPayNow
                          : l10n.orderDetailMarkPaid,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (!isStudent) ...[
                  OutlinedButton.icon(
                    onPressed: () => _run(
                      () => ref
                          .read(ordersRepositoryProvider)
                          .requestPayment(widget.id),
                      success: l10n.orderDetailPaymentRequested,
                    ),
                    icon: const Icon(Icons.request_quote_outlined),
                    label: Text(l10n.orderDetailRequestPayment),
                  ),
                  const SizedBox(height: 10),
                ],
                OutlinedButton.icon(
                  onPressed: () => context.push('/orders/${widget.id}/invoice'),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(l10n.orderDetailOpenInvoice),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  (String, StatusTone) _paymentTone(Payment? payment, AppLocalizations l10n) =>
      switch (payment?.status) {
        'paid' => (l10n.ordersPaymentPaid, StatusTone.success),
        'open' => (l10n.ordersPaymentOpen, StatusTone.warning),
        'pending' => (l10n.ordersPaymentPending, StatusTone.info),
        'failed' => (l10n.ordersPaymentFailed, StatusTone.danger),
        'canceled' => (l10n.ordersPaymentCanceled, StatusTone.danger),
        'expired' => (l10n.ordersPaymentExpired, StatusTone.danger),
        _ => (l10n.ordersPaymentUnpaid, StatusTone.neutral),
      };
}
