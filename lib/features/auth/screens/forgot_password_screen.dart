import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets.dart';
import '../providers/auth_provider.dart';

/// `forget-password` → OTP → `reset-password` (optional new password).
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _otp = TextEditingController();
  final _password = TextEditingController();

  bool _codeSent = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final l10n = context.l10n;
    if (_email.text.trim().isEmpty) {
      showAppSnack(context, l10n.loginEmailRequired, error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).forgetPassword(_email.text);
      if (!mounted) return;
      setState(() => _codeSent = true);
      showAppSnack(context, l10n.forgotCodeSent);
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

  Future<void> _reset() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.resetPassword(
        email: _email.text,
        otp: _otp.text.trim(),
        password: _password.text.isEmpty ? null : _password.text,
      );
      if (!mounted) return;
      showAppSnack(context, l10n.forgotPasswordChanged);
      context.go('/login');
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
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.forgotTitle),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _codeSent ? l10n.forgotEnterCode : l10n.forgotResetTitle,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _codeSent
                          ? l10n.forgotCodeSentTo(_email.text.trim())
                          : l10n.forgotEmailHint,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _email,
                      readOnly: _codeSent,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: l10n.loginEmailLabel,
                      ),
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return l10n.loginEmailRequired;
                        if (!value.contains('@')) {
                          return l10n.loginEmailInvalid;
                        }
                        return null;
                      },
                    ),
                    if (_codeSent) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _otp,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: InputDecoration(
                          labelText: l10n.forgotCodeLabel,
                          counterText: '',
                        ),
                        validator: (v) => (v == null || v.trim().length < 4)
                            ? l10n.forgotCodeRequired
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: l10n.forgotNewPassword,
                          helperText: l10n.registerPasswordRules,
                          helperMaxLines: 2,
                        ),
                        validator: (v) {
                          final value = v ?? '';
                          if (value.isEmpty) return null;
                          if (value.length < 8) {
                            return l10n.registerPasswordMin8;
                          }
                          if (!value.contains(RegExp(r'[a-z]')) ||
                              !value.contains(RegExp(r'[A-Z]')) ||
                              !value.contains(RegExp(r'\d'))) {
                            return l10n.registerPasswordNeedsMix;
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _busy
                          ? null
                          : (_codeSent ? _reset : _sendCode),
                      child: _busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                              ),
                            )
                          : Text(
                              _codeSent
                                  ? l10n.forgotSubmitReset
                                  : l10n.forgotSubmitSend,
                            ),
                    ),
                    if (_codeSent)
                      TextButton(
                        onPressed: _busy ? null : _sendCode,
                        child: Text(l10n.forgotResend),
                      ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text(l10n.forgotBackToLogin),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
