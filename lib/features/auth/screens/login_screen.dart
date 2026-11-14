import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:formz/formz.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/responsive.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/form_inputs.dart';
import '../../../shared/widgets.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  EmailInput _email = const EmailInput.pure();
  PasswordInput _password = const PasswordInput.pure();
  bool _obscure = true;
  bool _busy = false;
  FormzSubmissionStatus _status = FormzSubmissionStatus.initial;

  bool get _isValid => Formz.validate([_email, _password]);

  Future<void> _pickEnvironment(BuildContext context) async {
    final l10n = context.l10n;
    final prefs = await SharedPreferences.getInstance();
    final current = ApiClient.resolvedBaseUrl;

    final devUrl = dotenv.maybeGet('API_BASE_URL_DEV',
            fallback: 'http://localhost:8000/api') ??
        'http://localhost:8000/api';
    final stagingUrl = dotenv.maybeGet('API_BASE_URL_STAGING',
            fallback: 'https://staging.planles.nl/api') ??
        'https://staging.planles.nl/api';
    final prodUrl = dotenv.maybeGet('API_BASE_URL',
            fallback: ApiClient.defaultBaseUrl) ??
        ApiClient.defaultBaseUrl;

    final options = <MapEntry<String, String>>[
      MapEntry('Production', prodUrl),
      MapEntry('Staging', stagingUrl),
      MapEntry('Development', devUrl),
    ];

    if (!context.mounted) return;
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => _EnvironmentDialog(
        l10nCancel: l10n.cancel,
        current: current,
        options: options,
      ),
    );

    if (picked == null || !context.mounted) return;

    String url = picked;
    if (picked == '__custom__') {
      final controller = TextEditingController(text: current);
      final result = await showDialog<String>(
        context: context,
        builder: (ctx) => _CustomUrlDialog(
          controller: controller,
          cancelLabel: l10n.cancel,
          confirmLabel: l10n.confirm,
        ),
      );
      controller.dispose();
      if (result == null || result.isEmpty || !context.mounted) return;
      url = result;
    }

    await prefs.setString('planles.baseUrlOverride', url);
    ApiClient.setOverride(url);
    try {
      ref.read(apiClientProvider).setBaseUrl(url);
    } catch (_) {}
    if (context.mounted) {
      showAppSnack(context, 'Base URL: $url');
    }
  }

  Future<void> _submit() async {
    final email = EmailInput.dirty(_email.value);
    final password = PasswordInput.dirty(_password.value);
    setState(() {
      _email = email;
      _password = password;
      _status = FormzSubmissionStatus.inProgress;
    });
    if (!Formz.validate([email, password])) {
      setState(() => _status = FormzSubmissionStatus.failure);
      return;
    }

    setState(() => _busy = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .login(email: email.value.trim(), password: password.value);
      setState(() => _status = FormzSubmissionStatus.success);
    } on ApiException catch (e) {
      if (mounted) {
        showAppSnack(context, describeError(context, e), error: true);
      }
      setState(() => _status = FormzSubmissionStatus.failure);
    } catch (e) {
      if (mounted) {
        showAppSnack(context, describeError(context, e), error: true);
      }
      setState(() => _status = FormzSubmissionStatus.failure);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _emailErrorText(BuildContext context) {
    if (_email.isPure) return null;
    return switch (_email.error) {
      EmailValidationError.empty => context.l10n.loginEmailRequired,
      EmailValidationError.invalid => context.l10n.loginEmailInvalid,
      null => null,
    };
  }

  String? _passwordErrorText(BuildContext context) {
    if (_password.isPure) return null;
    return switch (_password.error) {
      PasswordValidationError.empty => context.l10n.loginPasswordRequired,
      PasswordValidationError.tooShort => context.l10n.loginPasswordRequired,
      null => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final scheme = theme.colorScheme;
    final wide = context.screenWidth >= Breakpoints.medium;

    Widget envButton() => IconButton.filledTonal(
          icon: const Icon(Icons.tune_rounded),
          tooltip: 'Environment',
          onPressed: () => _pickEnvironment(context),
        ).animate().fadeIn(duration: 300.ms);

    final formColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (wide)
          Align(
            alignment: Alignment.centerRight,
            child: envButton(),
          ),
        if (!wide) ...[
          const SizedBox(height: 40),
          Center(
            child: Container(
              width: 88,
              height: 88,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              child: Image.asset(
                'assets/branding/planles_logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ).animate().fadeIn(duration: 350.ms).scale(begin: const Offset(0.96, 0.96)),
          const SizedBox(height: 20),
          Text(
            l10n.loginTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ).animate().fadeIn(delay: 60.ms).moveY(begin: 6, end: 0),
          const SizedBox(height: 6),
          Text(
            l10n.loginSubtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 24),
        ] else ...[
          Text(
            l10n.loginTitle,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ).animate().fadeIn(delay: 60.ms).moveY(begin: 6, end: 0),
          const SizedBox(height: 6),
          Text(
            l10n.loginSubtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 28),
        ],
        Container(
          padding: EdgeInsets.all(wide ? 24 : 18),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
            boxShadow: wide
                ? [
                    BoxShadow(
                      color: scheme.shadow.withValues(alpha: 0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: InputDecoration(
                  labelText: l10n.loginEmailLabel,
                  prefixIcon: const Icon(Icons.mail_outline_rounded),
                  errorText: _emailErrorText(context),
                ),
                onChanged: (v) => setState(() {
                  _email = EmailInput.dirty(v);
                }),
              ),
              const SizedBox(height: 14),
              TextField(
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: l10n.loginPasswordLabel,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  errorText: _passwordErrorText(context),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                onChanged: (v) => setState(() {
                  _password = PasswordInput.dirty(v);
                }),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push('/forgot-password'),
                  child: Text(l10n.loginForgotPassword),
                ),
              ),
              const SizedBox(height: 4),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy || _status.isInProgress
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : Text(l10n.loginSubmit),
              ),
              if (!_isValid && !_email.isPure && !_password.isPure)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.loginEmailInvalid,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ).animate().fadeIn(delay: 140.ms).moveY(begin: 10, end: 0),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.loginNoAccount,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/register'),
              child: Text(l10n.loginRegister),
            ),
          ],
        ).animate().fadeIn(delay: 180.ms),
      ],
    );

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primary,
                      scheme.primary.withValues(alpha: 0.85),
                      const Color(0xFF4CB4E7),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Image.asset(
                                'assets/branding/planles_logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Planles',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          l10n.loginSubtitle,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Plan en beheer rijlessen, bestellingen en voortgang op elk apparaat — mobiel, web en desktop.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: const [
                            _LoginFeaturePill(icon: Icons.event_available_rounded, label: 'Planning'),
                            _LoginFeaturePill(icon: Icons.receipt_long_rounded, label: 'Bestellingen'),
                            _LoginFeaturePill(icon: Icons.notifications_rounded, label: 'Meldingen'),
                          ],
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Container(
                color: scheme.surface,
                child: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: formColumn,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  scheme.primary.withValues(alpha: 0.10),
                  scheme.surface,
                  scheme.surface,
                ],
                stops: const [0, 0.35, 1],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: formColumn,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 4, right: 8),
                child: envButton(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnvironmentDialog extends StatelessWidget {
  const _EnvironmentDialog({
    required this.l10nCancel,
    required this.current,
    required this.options,
  });

  final String l10nCancel;
  final String current;
  final List<MapEntry<String, String>> options;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.dns_rounded, color: scheme.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Text(
                  'Environment',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (final e in options)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: e.value == current
                      ? scheme.primaryContainer.withValues(alpha: 0.45)
                      : scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.of(context).pop(e.value),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                            e.value == current
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            size: 20,
                            color: e.value == current
                                ? scheme.primary
                                : scheme.outline,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.key,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  e.value,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop('__custom__'),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Custom URL'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10nCancel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginFeaturePill extends StatelessWidget {
  const _LoginFeaturePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomUrlDialog extends StatelessWidget {
  const _CustomUrlDialog({
    required this.controller,
    required this.cancelLabel,
    required this.confirmLabel,
  });

  final TextEditingController controller;
  final String cancelLabel;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.link_rounded, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Text('Custom base URL')),
        ],
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.url,
        decoration: const InputDecoration(
          labelText: 'API base URL',
          hintText: 'https://...',
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text.trim()),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
