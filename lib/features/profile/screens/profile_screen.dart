import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../l10n/language_picker.dart';
import '../../../l10n/l10n.dart';
import '../../../l10n/theme_mode_picker.dart';
import '../../../shared/widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // (Re)load the latest user data when the profile appears so it is never
    // left empty or showing stale information.
    ref.read(authControllerProvider.notifier).refreshUser();
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await confirmAction(
      context,
      title: l10n.profileSignOut,
      message: l10n.profileSignOutMessage,
      confirmLabel: l10n.profileSignOut,
    );
    if (!ok) return;
    await ref.read(authControllerProvider.notifier).signOut();
  }

  Future<void> _deactivate(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await confirmAction(
      context,
      title: l10n.profileDeactivate,
      message: l10n.profileDeactivateMessage,
      confirmLabel: l10n.profileDeactivateConfirm,
      destructive: true,
    );
    if (!ok) return;
    try {
      await ref.read(profileRepositoryProvider).deactivate();
      if (!context.mounted) return;
      showAppSnack(context, l10n.profileAccountDeactivated);
      await ref.read(authControllerProvider.notifier).signOut();
    } catch (e) {
      if (context.mounted) {
        showAppSnack(context, describeError(context, e), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
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
                      user.displayName(l10n),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
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
                      label: user.isInstructor
                          ? l10n.registerInstructor
                          : l10n.registerStudent,
                      tone: StatusTone.info,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.dashboardBalanceLabel,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            F.money(user.balance),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: () => context.push('/balance/topup'),
                      // The global button theme uses `Size.fromHeight`, i.e. an
                      // infinite minimum width. Inside an unbounded Row that
                      // forces an infinite width and crashes layout, so give
                      // this button a finite minimum width.
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 40),
                      ),
                      child: Text(l10n.profileTopUp),
                    ),
                  ],
                ),
              ),
            ),

            // --------------------------------------------------------- info
            const SizedBox(height: 24),
            SectionHeader(l10n.registerPersonalDetails),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    InfoRow(l10n.planningInfoPhone, user.phone ?? '–'),
                    InfoRow(
                      l10n.registerBirthdate,
                      F.dateShort(F.date(user.birthdate)),
                    ),
                    InfoRow(
                      l10n.registerAddress,
                      [
                        user.street,
                        user.houseNumber,
                        user.zipCode,
                        user.city,
                      ].where((e) => e != null && e.isNotEmpty).join(' '),
                    ),
                    if (user.pickupLocation != null &&
                        user.pickupLocation!.isNotEmpty)
                      InfoRow(l10n.studentsPickupLabel, user.pickupLocation!),
                    if (user.licensePlate != null &&
                        user.licensePlate!.isNotEmpty)
                      InfoRow(l10n.profileLicensePlate, user.licensePlate!),
                  ],
                ),
              ),
            ),

            // ------------------------------------------------------- actions
            const SizedBox(height: 24),
            SectionHeader(l10n.profileSectionAccount),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: Text(l10n.editProfileTitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/profile/edit'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: Text(l10n.changePasswordTitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/profile/password'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.tune_outlined),
                    title: Text(l10n.profileNotificationSettings),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/notifications/settings'),
                  ),
                  const Divider(),
                  const LanguageListTile(),
                  const Divider(),
                  const ThemeModeListTile(),
                  if (user.isInstructor) ...[
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.groups_outlined),
                      title: Text(l10n.studentsTitle),
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
              label: Text(l10n.profileSignOut),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _deactivate(context, ref),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              child: Text(l10n.profileDeactivate),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Planles',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
