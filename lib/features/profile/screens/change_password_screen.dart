import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/widgets.dart';
import '../providers/profile_providers.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    final l10n = context.l10n;
    final v = value ?? '';
    if (v.length < 8) return l10n.registerPasswordMin8;
    if (!v.contains(RegExp(r'[a-z]')) ||
        !v.contains(RegExp(r'[A-Z]')) ||
        !v.contains(RegExp(r'\d'))) {
      return l10n.registerPasswordNeedsMix;
    }
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .changePassword(
            currentPassword: _current.text,
            newPassword: _next.text,
          );
      if (!mounted) return;
      showAppSnack(context, context.l10n.changePasswordSuccess);
      context.pop();
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
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.changePasswordTitle)),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                TextFormField(
                  controller: _current,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.changePasswordCurrentLabel,
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? l10n.loginPasswordRequired
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _next,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.changePasswordNewLabel,
                    helperText: l10n.registerPasswordRules,
                    helperMaxLines: 2,
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirm,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.registerPasswordRepeat,
                  ),
                  validator: (v) =>
                      v != _next.text ? l10n.registerPasswordMismatch : null,
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _busy ? null : _save,
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : Text(l10n.changePasswordSubmit),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}
