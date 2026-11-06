import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
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
  bool _invoiceBusy = false;

  Future<void> _run(
    Future<void> Function() action, {
    String success = 'Gelukt',
  }) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(orderDetailProvider(widget.id));
      ref.invalidate(orderItemsProvider(widget.id));
      ref.invalidate(ordersListProvider);
      ref.read(authControllerProvider.notifier).refreshUser();
      if (mounted) showAppSnack(context, success);
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.validationMessage, error: true);
    } catch (e) {
      if (mounted) showAppSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pay() async {
    final url = await _checkout(
      () => ref
          .read(ordersRepositoryProvider)
          .pay(orderId: widget.id, redirectUrl: 'planles://payment'),
    );
    if (url != null) await _open(url);
  }

  Future<String?> _checkout(Future<String?> Function() call) async {
    setState(() => _busy = true);
    try {
      return await call();
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.validationMessage, error: true);
      return null;
    } catch (e) {
      if (mounted) showAppSnack(context, '$e', error: true);
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
        'De betalingspagina kon niet worden geopend.',
        error: true,
      );
    }
  }

  Future<void> _invoice() async {
    setState(() => _invoiceBusy = true);
    try {
      final bytes = await ref.read(ordersRepositoryProvider).invoice(widget.id);
      if (bytes.isEmpty) throw 'Lege factuur.';
      final pdf = Uint8List.fromList(bytes);
      await Printing.layoutPdf(
        onLayout: (_) async => pdf,
        name: 'factuur-${widget.id}.pdf',
      );
    } catch (e) {
      if (mounted) showAppSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _invoiceBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(orderDetailProvider(widget.id));
    final items = ref.watch(orderItemsProvider(widget.id));
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Bestelling #${widget.id}')),
      body: AsyncView<Order>(
        value: async,
        onRetry: () => ref.invalidate(orderDetailProvider(widget.id)),
        data: (order) {
          final payment = order.payment;
          final (label, tone) = _paymentTone(payment);
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
                            'Bestelling #${order.id}',
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
                        'Geplaatst op ${F.dateTime(order.createdAt)}',
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

              SectionHeader('Gegevens'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      InfoRow('Leerling', order.student?.fullName ?? '–'),
                      InfoRow('Instructeur', order.instructor?.fullName ?? '–'),
                      if (order.totalDuration != null)
                        InfoRow('Totaal', F.minutesLabel(order.totalDuration!)),
                      if (order.reservedDuration != null)
                        InfoRow(
                          'Gepland',
                          F.minutesLabel(order.reservedDuration!),
                        ),
                      if (order.availableDuration != null)
                        InfoRow(
                          'Beschikbaar',
                          F.minutesLabel(order.availableDuration!),
                        ),
                      InfoRow('Betaalwijze', switch (payment?.type) {
                        'digital' => 'Online',
                        'cash' => 'Contant',
                        'balance' => 'Saldo',
                        _ => '–',
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              SectionHeader('Lessen'),
              items.when(
                skipLoadingOnReload: true,
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => ErrorView(
                  message: '$e',
                  onRetry: () => ref.invalidate(orderItemsProvider(widget.id)),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Geen lesonderdelen gevonden.'),
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
                              item.drivingClass?.name ?? 'Les',
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
                                    '${item.quantity ?? 0} lessen',
                                    if (item.drivingClass?.duration != null)
                                      F.durationLabel(
                                        item.drivingClass!.duration,
                                      ),
                                    if (item.drivingClass?.priceValue != null)
                                      F.money(item.drivingClass!.priceValue),
                                  ].join(' · '),
                                ),
                                if (item.availableDuration != null) ...[
                                  const SizedBox(height: 6),
                                  StatusChip(
                                    label:
                                        '${F.minutesLabel(item.availableDuration!)} vrij',
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
                                    child: const Text('Inplannen'),
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
              SectionHeader('Acties'),
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
                      isStudent ? 'Nu betalen' : 'Markeer als betaald',
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
                      success: 'Betalingsverzoek verstuurd',
                    ),
                    icon: const Icon(Icons.request_quote_outlined),
                    label: const Text('Betaling aanvragen'),
                  ),
                  const SizedBox(height: 10),
                ],
                OutlinedButton.icon(
                  onPressed: _invoiceBusy ? null : _invoice,
                  icon: _invoiceBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Factuur openen'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  (String, StatusTone) _paymentTone(Payment? payment) =>
      switch (payment?.status) {
        'paid' => ('Betaald', StatusTone.success),
        'open' => ('Open', StatusTone.warning),
        'pending' => ('In behandeling', StatusTone.info),
        'failed' => ('Mislukt', StatusTone.danger),
        'canceled' => ('Geannuleerd', StatusTone.danger),
        'expired' => ('Verlopen', StatusTone.danger),
        _ => ('Nog niet betaald', StatusTone.neutral),
      };
}
