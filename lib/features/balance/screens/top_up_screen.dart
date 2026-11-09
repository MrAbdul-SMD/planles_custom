import 'dart:async';
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
  static const _presets = [25.0, 50.0, 100.0, 200.0];

  double? _selectedPreset = 50.0;
  final _custom = TextEditingController();
  bool _busy = false;

  // Active payment state
  bool _awaitingPayment = false;
  double _balanceBeforePayment = 0.0;
  bool _paymentVerified = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _custom.text = '50';
    // Refresh balance so the screen shows the latest value.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(authControllerProvider.notifier).refreshUser();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _custom.dispose();
    super.dispose();
  }

  double? get _effectiveAmount {
    final text = _custom.text.trim().replaceAll(',', '.');
    final customVal = double.tryParse(text);
    if (customVal != null && customVal > 0) return customVal;
    return _selectedPreset;
  }

  void _selectPreset(double val) {
    setState(() {
      _selectedPreset = val;
      _custom.text = val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 2);
    });
  }

  void _adjustAmount(double delta) {
    final cur = _effectiveAmount ?? 50.0;
    final next = (cur + delta).clamp(5.0, 5000.0);
    setState(() {
      _selectedPreset = null;
      _custom.text = next.toStringAsFixed(next.truncateToDouble() == next ? 0 : 2);
    });
  }

  Future<void> _checkBalance() async {
    setState(() => _busy = true);
    try {
      await ref.read(authControllerProvider.notifier).refreshUser();
      final updated = ref.read(currentUserProvider)?.balance ?? 0.0;
      if (updated > _balanceBeforePayment) {
        _pollingTimer?.cancel();
        if (mounted) {
          setState(() {
            _paymentVerified = true;
            _awaitingPayment = false;
          });
          showAppSnack(context, 'Saldo succesvol opgewaardeerd!');
        }
      }
    } catch (_) {
      // Best effort
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    int attempts = 0;
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) async {
      attempts++;
      if (attempts > 8) {
        timer.cancel();
        return;
      }
      try {
        await ref.read(authControllerProvider.notifier).refreshUser();
        final updated = ref.read(currentUserProvider)?.balance ?? 0.0;
        if (updated > _balanceBeforePayment && mounted) {
          timer.cancel();
          setState(() {
            _paymentVerified = true;
            _awaitingPayment = false;
          });
          showAppSnack(context, 'Saldo succesvol opgewaardeerd!');
        }
      } catch (_) {}
    });
  }

  Future<void> _submit() async {
    final amount = _effectiveAmount;

    if (amount == null || amount < 5.0) {
      showAppSnack(context, 'Kies een bedrag van minimaal € 5,00', error: true);
      return;
    }

    setState(() => _busy = true);
    _balanceBeforePayment = ref.read(currentUserProvider)?.balance ?? 0.0;

    try {
      final url = await ref
          .read(ordersRepositoryProvider)
          .purchaseBalance(amount: amount, redirectUrl: paymentRedirectUrl(kind: 'topup'));
      final uri = Uri.tryParse(url);
      if (uri == null) {
        throw const ApiException(
          'Ongeldige betaal-link ontvangen.',
          code: AppErrorCode.paymentFailed,
        );
      }

      final launched = await launchUrl(
        uri,
        mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
        webOnlyWindowName: kIsWeb ? '_self' : null,
      );
      if (!launched && !kIsWeb) {
        throw const ApiException(
          'Kon de betaalpagina niet openen.',
          code: AppErrorCode.paymentFailed,
        );
      }

      if (!mounted) return;
      setState(() {
        _busy = false;
        _awaitingPayment = true;
      });
      _startPolling();
    } on ApiException catch (e) {
      if (mounted) {
        showAppSnack(context, describeError(context, e), error: true);
        setState(() => _busy = false);
      }
    } catch (e) {
      if (mounted) {
        showAppSnack(context, describeError(context, e), error: true);
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final amount = _effectiveAmount;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboardTopUpBalance),
        actions: [
          IconButton(
            tooltip: l10n.retry,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(authControllerProvider.notifier).refreshUser(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              // ---------------------------------------- Card: Current Balance
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                        : [const Color(0xFF0F4C81), const Color(0xFF0369A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.black : const Color(0xFF0F4C81)).withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          l10n.topUpCurrentBalance,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: const Color(0xFF34D399).withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt_rounded, size: 14, color: Color(0xFF34D399)),
                              SizedBox(width: 4),
                              Text(
                                'Direct actief',
                                style: TextStyle(
                                  color: Color(0xFFD1FAE5),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      F.money(user?.balance ?? 0),
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Beschikbaar tegoed voor al je rijlessen & examens',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),

              // ---------------------------------------- Awaiting Verification State
              if (_paymentVerified) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 48, color: Color(0xFF10B981)),
                      const SizedBox(height: 12),
                      Text(
                        'Opwaardering geslaagd!',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFFD1FAE5) : const Color(0xFF065F46),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Je nieuwe saldo is bijgewerkt.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF047857),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => context.go('/home'),
                        child: const Text('Terug naar Dashboard'),
                      ),
                    ],
                  ),
                ),
              ] else if (_awaitingPayment) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.6),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Betaling gestart via Mollie',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Rond de betaling af in je bank-app.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _busy ? null : _checkBalance,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Controleer saldo'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          FilledButton.tonal(
                            onPressed: () {
                              _pollingTimer?.cancel();
                              setState(() => _awaitingPayment = false);
                            },
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 40),
                            ),
                            child: const Text('Ander bedrag'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // ---------------------------------------- Preset Grid
              Text(
                l10n.topUpChooseAmount,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.3,
                children: [
                  for (final val in _presets)
                    _PresetCard(
                      value: val,
                      selected: _selectedPreset == val,
                      tag: val == 50.0 ? 'Populier' : (val == 100.0 ? 'Aanbevolen' : null),
                      onTap: () => _selectPreset(val),
                    ),
                ],
              ),

              const SizedBox(height: 22),

              // ---------------------------------------- Custom Amount
              Text(
                'Of vul een eigen bedrag in',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Text(
                      '€',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _custom,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        decoration: const InputDecoration(
                          hintText: '0,00',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          fillColor: Colors.transparent,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (v) {
                          final parsed = double.tryParse(v.trim().replaceAll(',', '.'));
                          setState(() {
                            if (parsed != null && _presets.contains(parsed)) {
                              _selectedPreset = parsed;
                            } else {
                              _selectedPreset = null;
                            }
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_rounded),
                      tooltip: '+ €10',
                      onPressed: () => _adjustAmount(10.0),
                    ),
                    IconButton(
                      icon: const Icon(Icons.exposure_plus_2_rounded),
                      tooltip: '+ €25',
                      onPressed: () => _adjustAmount(25.0),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ---------------------------------------- Trust Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Veilig betalen met Mollie',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'iDEAL · Bancontact · Creditcard · Apple Pay',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ---------------------------------------- Action Button
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : Text(
                        amount == null || amount < 5.0
                            ? l10n.topUpChooseAmount
                            : 'Opwaarderen ${F.money(amount)}',
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

class _PresetCard extends StatelessWidget {
  const _PresetCard({
    required this.value,
    required this.selected,
    this.tag,
    required this.onTap,
  });

  final double value;
  final bool selected;
  final String? tag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.6),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  F.money(value),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: selected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                  ),
                ),
                if (tag != null)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tag!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ),
              ],
            ),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
              color: selected ? theme.colorScheme.primary : theme.colorScheme.outline,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
