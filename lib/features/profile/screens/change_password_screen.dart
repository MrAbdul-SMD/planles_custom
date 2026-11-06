import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
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
    final v = value ?? '';
    if (v.length < 8) return 'Minimaal 8 tekens';
    if (!v.contains(RegExp(r'[a-z]')) ||
        !v.contains(RegExp(r'[A-Z]')) ||
        !v.contains(RegExp(r'\d'))) {
      return 'Gebruik een kleine letter, hoofdletter en cijfer';
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
      showAppSnack(context, 'Wachtwoord gewijzigd');
      context.pop();
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.validationMessage, error: true);
    } catch (e) {
      if (mounted) showAppSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wachtwoord wijzigen')),
      body: Center(
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
                  decoration: const InputDecoration(
                    labelText: 'Huidig wachtwoord',
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Vul je wachtwoord in' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _next,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nieuw wachtwoord',
                    helperText: 'Minimaal 8 tekens met een kleine letter, hoofdletter en cijfer',
                    helperMaxLines: 2,
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirm,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Herhaal wachtwoord',
                  ),
                  validator: (v) => v != _next.text
                      ? 'Wachtwoorden komen niet overeen'
                      : null,
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
                      : const Text('Wachtwoord opslaan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
