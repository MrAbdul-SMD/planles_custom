import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/orders_providers.dart';

/// Landing screen for Mollie's redirect after a payment. Refreshes the
/// relevant data and then sends the user home.
class PaymentReturnScreen extends ConsumerStatefulWidget {
  const PaymentReturnScreen({super.key, this.kind = 'payment'});

  final String kind;

  @override
  ConsumerState<PaymentReturnScreen> createState() =>
      _PaymentReturnScreenState();
}

class _PaymentReturnScreenState extends ConsumerState<PaymentReturnScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_finish);
  }

  Future<void> _finish() async {
    final l10n = context.l10n;
    try {
      if (widget.kind == 'topup') {
        await ref.read(authControllerProvider.notifier).refreshUser();
      } else {
        ref.invalidate(ordersListProvider);
      }
    } catch (_) {
      // Best effort; the user can refresh manually.
    }
    if (!mounted) return;
    showAppSnack(context, l10n.paymentReturnSuccess);
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l10n.paymentReturnProcessing),
          ],
        ),
      ),
    );
  }
}
