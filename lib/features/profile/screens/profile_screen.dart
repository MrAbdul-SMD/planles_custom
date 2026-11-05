import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final ok = await confirmAction(
      context,
      title: 'Uitloggen',
      message: 'Weet je zeker dat je wilt uitloggen?',
      confirmLabel: 'Uitloggen',
    );
    if (!ok) return;
    await ref.read(authControllerProvider.notifier).signOut();
  }

  Future<void> _deactivate(BuildContext context, WidgetRef ref) async {
    final ok = await confirmAction(
      context,
      title: 'Account deactiveren',
      message:
          'Je account wordt gedeactiveerd en je kunt niet meer inloggen. '
          'Dit kan niet ongedaan worden gemaakt.',
      confirmLabel: 'Deactiveren',
      destructive: true,
    );
    if (!ok) return;
    try {
      await ref.read(profileRepositoryProvider).deactivate();
      if (!context.mounted) return;
      showAppSnack(context, 'Account gedeactiveerd');
      await ref.read(authControllerProvider.notifier).signOut();
    } on ApiException catch (e) {
      if (context.mounted) {
        showAppSnack(context, e.validationMessage, error: true);
      }
    } catch (e) {
      if (context.mounted) showAppSnack(context, '$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profiel')),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(authControllerProvider.notifier).refreshUser(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            // ------------------------------------------------------ header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    AppAvatar(initials: user.initials, size: 72),
                    const SizedBox(height: 12),
                    Text(
                      user.fullName,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    StatusChip(
                      label: user.isInstructor ? 'Instructeur' : 'Leerling',
                      tone: StatusTone.info,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined,
                        color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Saldo', style: theme.textTheme.bodyLarge)),
                    Text(
                      F.money(user.balance),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Opwaarderen',
                      onPressed: () => context.push('/balance/topup'),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ),
            ),

            // --------------------------------------------------------- info
            const SizedBox(height: 24),
            const SectionHeader('Persoonlijke gegevens'),
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    InfoRow('Telefoon', user.phone ?? '–'),
                    InfoRow('Geboortedatum', F.dateShort(F.date(user.birthdate))),
                    InfoRow(
                      'Adres',
                      [
                        user.street,
                        user.houseNumber,
                        user.zipCode,
                        user.city,
                      ].where((e) => e != null && e.isNotEmpty).join(' '),
                    ),
                    if (user.pickupLocation != null &&
                        user.pickupLocation!.isNotEmpty)
                      InfoRow('Ophaallocatie', user.pickupLocation!),
                    if (user.licensePlate != null &&
                        user.licensePlate!.isNotEmpty)
                      InfoRow('Kenteken', user.licensePlate!),
                  ],
                ),
              ),
            ),

            // ------------------------------------------------------- actions
            const SizedBox(height: 24),
            const SectionHeader('Account'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: const Text('Gegevens bewerken'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/profile/edit'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Wachtwoord wijzigen'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/profile/password'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.tune_outlined),
                    title: const Text('Meldingsinstellingen'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/notifications/settings'),
                  ),
                  if (user.isInstructor) ...[
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.groups_outlined),
                      title: const Text('Mijn leerlingen'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/students'),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => _signOut(context, ref),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Uitloggen'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _deactivate(context, ref),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              child: const Text('Account deactiveren'),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Planles',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
