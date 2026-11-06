import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
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
    if (_email.text.trim().isEmpty) {
      showAppSnack(context, 'Vul je e-mailadres in', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).forgetPassword(_email.text);
      if (!mounted) return;
      setState(() => _codeSent = true);
      showAppSnack(context, 'We hebben een code naar je e-mail gestuurd.');
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.validationMessage, error: true);
    } catch (_) {
      if (mounted) {
        showAppSnack(context, 'Versturen is mislukt.', error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.resetPassword(
        email: _email.text,
        otp: _otp.text.trim(),
        password: _password.text.isEmpty ? null : _password.text,
      );
      if (!mounted) return;
      showAppSnack(context, 'Wachtwoord gewijzigd. Je kunt nu inloggen.');
      context.go('/login');
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.validationMessage, error: true);
    } catch (_) {
      if (mounted) {
        showAppSnack(context, 'Resetten is mislukt.', error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Wachtwoord vergeten')),
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
                      _codeSent ? 'Voer de code in' : 'Herstel je wachtwoord',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _codeSent
                          ? 'We hebben een code gestuurd naar ${_email.text.trim()}.'
                          : 'Vul je e-mailadres in en we sturen je een herstelcode.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _email,
                      readOnly: _codeSent,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-mailadres',
                      ),
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return 'Vul je e-mailadres in';
                        if (!value.contains('@')) {
                          return 'Vul een geldig e-mailadres in';
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
                        decoration: const InputDecoration(
                          labelText: 'Herstelcode',
                          counterText: '',
                        ),
                        validator: (v) => (v == null || v.trim().length < 4)
                            ? 'Vul de code in'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Nieuw wachtwoord (optioneel)',
                          helperText: 'Minimaal 8 tekens met een kleine letter, hoofdletter en cijfer',
                          helperMaxLines: 2,
                        ),
                        validator: (v) {
                          final value = v ?? '';
                          if (value.isEmpty) return null;
                          if (value.length < 8) return 'Minimaal 8 tekens';
                          if (!value.contains(RegExp(r'[a-z]')) ||
                              !value.contains(RegExp(r'[A-Z]')) ||
                              !value.contains(RegExp(r'\d'))) {
                            return 'Gebruik een kleine letter, hoofdletter en cijfer';
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
                                  ? 'Wachtwoord resetten'
                                  : 'Code versturen',
                            ),
                    ),
                    if (_codeSent)
                      TextButton(
                        onPressed: _busy ? null : _sendCode,
                        child: const Text('Code opnieuw versturen'),
                      ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Terug naar inloggen'),
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
