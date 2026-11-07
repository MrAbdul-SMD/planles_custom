import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/orders_providers.dart';

/// Landing screen for Mollie's redirect after a payment. Refreshes the
/// relevant data with retry polling and then sends the user home.
class PaymentReturnScreen extends ConsumerStatefulWidget {
  const PaymentReturnScreen({super.key, this.kind = 'payment'});

  final String kind;

  @override
  ConsumerState<PaymentReturnScreen> createState() =>
      _PaymentReturnScreenState();
}

class _PaymentReturnScreenState extends ConsumerState<PaymentReturnScreen> {
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
  }

  Future<void> _finish() async {
    final l10n = context.l10n;
    Uri uri;
    try {
      uri = GoRouterState.of(context).uri;
    } catch (_) {
      uri = Uri.parse('/payment/callback?kind=${widget.kind}');
    }
    final kind = uri.queryParameters['kind'] ?? widget.kind;
    final orderId = int.tryParse(uri.queryParameters['orderId'] ?? '');

    try {
      if (kind == 'topup') {
        // Poll user balance up to 4 times to ensure Mollie webhook finished
        for (int i = 0; i < 4; i++) {
          await ref.read(authControllerProvider.notifier).refreshUser();
          if (i < 3) await Future.delayed(const Duration(milliseconds: 1400));
        }
      } else {
        ref.invalidate(ordersListProvider);
        if (orderId != null) {
          try {
            ref.invalidate(orderDetailProvider(orderId));
            ref.invalidate(orderItemsProvider(orderId));
          } catch (_) {}
        }
        for (int i = 0; i < 3; i++) {
          await Future.delayed(const Duration(milliseconds: 1200));
          ref.invalidate(ordersListProvider);
          if (orderId != null) {
            ref.invalidate(orderDetailProvider(orderId));
            ref.invalidate(orderItemsProvider(orderId));
          }
        }
      }
    } catch (_) {
      // Best effort
    }

    if (!mounted) return;
    setState(() => _completed = true);
    showAppSnack(context, l10n.paymentReturnSuccess);

    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      if (orderId != null) {
        context.go('/orders/$orderId');
      } else {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.paymentReturnProcessing),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/home'),
          tooltip: l10n.cancel,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _completed
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: _completed
                    ? const Icon(Icons.check_rounded, size: 40, color: Color(0xFF10B981))
                    : const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
              ),
              const SizedBox(height: 24),
              Text(
                _completed ? 'Betaling verwerkt!' : l10n.paymentReturnProcessing,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _completed
                    ? 'Je gegevens zijn bijgewerkt. We sturen je door...'
                    : 'We verifiëren de betaling met je bank...',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.tonal(
                onPressed: () => context.go('/home'),
                child: const Text('Direct naar Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
