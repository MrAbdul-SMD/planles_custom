import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _pickEnvironment(BuildContext context) async {
    final l10n = context.l10n;
    final prefs = await SharedPreferences.getInstance();
    final current = ApiClient.resolvedBaseUrl;

    final devUrl = dotenv.maybeGet('API_BASE_URL_DEV', fallback: 'http://localhost:8000/api') ?? 'http://localhost:8000/api';
    final stagingUrl = dotenv.maybeGet('API_BASE_URL_STAGING', fallback: 'https://staging.planles.nl/api') ?? 'https://staging.planles.nl/api';
    final prodUrl = dotenv.maybeGet('API_BASE_URL', fallback: ApiClient.defaultBaseUrl) ?? ApiClient.defaultBaseUrl;

    final options = <MapEntry<String, String>>[
      MapEntry('Production', prodUrl),
      MapEntry('Staging', stagingUrl),
      MapEntry('Development', devUrl),
    ];

    if (!context.mounted) return;
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final scheme = theme.colorScheme;
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                      child: Icon(
                        Icons.dns_rounded,
                        color: scheme.onPrimaryContainer,
                      ),
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
                        onTap: () => Navigator.of(ctx).pop(e.value),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
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
                                      style:
                                          theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      e.value,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
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
                    onPressed: () => Navigator.of(ctx).pop('__custom__'),
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
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(l10n.cancel),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (picked == null || !context.mounted) return;

    String url = picked;
    if (picked == '__custom__') {
      final controller = TextEditingController(text: current);
      final result = await showDialog<String>(
        context: context,
        builder: (ctx) {
          final theme = Theme.of(ctx);
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
                  child: Icon(Icons.link_rounded,
                      color: scheme.onPrimaryContainer),
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
                onPressed: () => Navigator.of(ctx).pop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                ),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 44),
                ),
                child: Text(l10n.confirm),
              ),
            ],
          );
        },
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
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .login(email: _email.text, password: _password.text);
      // The router redirect takes over from here.
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
    final scheme = theme.colorScheme;

    return Scaffold(
      body: Container(
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton.filledTonal(
                          icon: const Icon(Icons.tune_rounded),
                          tooltip: 'Environment',
                          onPressed: () => _pickEnvironment(context),
                        ),
                      ),
                      const SizedBox(height: 8),
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
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.loginTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.loginSubtitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              decoration: InputDecoration(
                                labelText: l10n.loginEmailLabel,
                                prefixIcon:
                                    const Icon(Icons.mail_outline_rounded),
                              ),
                              validator: (value) {
                                final v = value?.trim() ?? '';
                                if (v.isEmpty) return l10n.loginEmailRequired;
                                if (!v.contains('@')) {
                                  return l10n.loginEmailInvalid;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _password,
                              obscureText: _obscure,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                labelText: l10n.loginPasswordLabel,
                                prefixIcon:
                                    const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) => (value ?? '').isEmpty
                                  ? l10n.loginPasswordRequired
                                  : null,
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () =>
                                    context.push('/forgot-password'),
                                child: Text(l10n.loginForgotPassword),
                              ),
                            ),
                            const SizedBox(height: 4),
                            FilledButton(
                              onPressed: _busy ? null : _submit,
                              child: _busy
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                      ),
                                    )
                                  : Text(l10n.loginSubmit),
                            ),
                          ],
                        ),
                      ),
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
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
