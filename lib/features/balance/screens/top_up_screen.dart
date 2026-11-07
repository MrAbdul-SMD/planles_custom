import 'package:flutter/foundation.dart';
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
import '../../orders/providers/orders_providers.dart';

/// Tops up the account balance through Mollie (`POST /balance`).
class TopUpScreen extends ConsumerStatefulWidget {
  const TopUpScreen({super.key});

  @override
  ConsumerState<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends ConsumerState<TopUpScreen> {
  static const _presets = [10, 25, 50, 100, 200];

  int? _amount = 25;
  final _custom = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    ref.invalidate(currentUserProvider);
  }

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  int? get _effective {
    final custom = int.tryParse(_custom.text.trim());
    if (custom != null && custom > 0) return custom;
    return _amount;
  }

  Future<void> _submit() async {
    final amount = _effective;
    if (amount == null || amount <= 0) {
      showAppSnack(context, context.l10n.topUpInvalidAmount, error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final url = await ref
          .read(ordersRepositoryProvider)
          .purchaseBalance(amount: amount, redirectUrl: paymentRedirectUrl(kind: 'topup'));
      final uri = Uri.tryParse(url);
      if (uri != null) {
        await launchUrl(uri, mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication);
      }
      // The webhook credits the balance; refresh in case it was instant.
      await ref.read(authControllerProvider.notifier).refreshUser();
      if (!mounted) return;
      showAppSnack(context, context.l10n.topUpCompletePayment);
      context.pop();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final amount = _effective;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.dashboardTopUpBalance)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      l10n.topUpCurrentBalance,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      F.money(user?.balance ?? 0),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.topUpChooseAmount,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final value in _presets)
                    ChoiceChip(
                      label: Text(F.money(value)),
                      selected: _amount == value && _custom.text.trim().isEmpty,
                      onSelected: (_) {
                        setState(() {
                          _amount = value;
                          _custom.clear();
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _custom,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.topUpCustomAmount,
                  prefixText: '€ ',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : Text(
                        amount == null
                            ? l10n.topUpChooseAmount
                            : l10n.topUpPayButton(F.money(amount)),
                      ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.topUpMollieNote,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
