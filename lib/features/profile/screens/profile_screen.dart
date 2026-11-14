import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/responsive.dart';
import '../../../core/update/app_update_prompt.dart';
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

    final detailsCard = Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            if (user.pickupLocation != null && user.pickupLocation!.isNotEmpty)
              InfoRow(l10n.studentsPickupLabel, user.pickupLocation!),
            if (user.licensePlate != null && user.licensePlate!.isNotEmpty)
              InfoRow(l10n.profileLicensePlate, user.licensePlate!),
          ],
        ),
      ),
    );

    final instructorCard = (!user.isInstructor && user.instructor != null)
        ? Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppAvatar(
                        initials: user.instructor!.initials,
                        size: 44,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.instructor!.displayName(l10n),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if ((user.instructor!.email ?? '').isNotEmpty)
                              Text(
                                user.instructor!.email!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  InfoRow(
                    l10n.planningInfoPhone,
                    user.instructor!.phone ?? '–',
                  ),
                  if ((user.instructor!.pickupLocation ?? '').isNotEmpty)
                    InfoRow(
                      l10n.studentsPickupLabel,
                      user.instructor!.pickupLocation!,
                    ),
                  if ((user.instructor!.licensePlate ?? '').isNotEmpty)
                    InfoRow(
                      l10n.profileLicensePlate,
                      user.instructor!.licensePlate!,
                    ),
                ],
              ),
            ),
          )
        : null;

    final actionsCard = Card(
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
          const Divider(),
          ListTile(
            leading: const Icon(Icons.system_update_alt_outlined),
            title: const Text('Check for updates'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => AppUpdatePrompt.checkAndPrompt(
              context,
              force: true,
              silent: false,
              includePrereleases: true,
            ),
          ),
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
    );

    final signOutSection = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(authControllerProvider.notifier).refreshUser(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= Breakpoints.medium;
              final horizontal = wide ? 28.0 : 20.0;

              final headerCard = Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      AppAvatar(initials: user.initials, size: 84),
                      const SizedBox(height: 14),
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
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      StatusChip(
                        label: user.isInstructor
                            ? l10n.registerInstructor
                            : l10n.registerStudent,
                        tone: StatusTone.info,
                      ),
                    ],
                  ),
                ),
              );

              final balanceCard = Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          color: theme.colorScheme.primary,
                          size: 22,
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
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.tonal(
                        onPressed: () => context.push('/balance/topup'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 42),
                        ),
                        child: Text(l10n.profileTopUp),
                      ),
                    ],
                  ),
                ),
              );

              final left = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  headerCard,
                  const SizedBox(height: 16),
                  balanceCard,
                ],
              );

              final right = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionHeader(l10n.registerPersonalDetails),
                  detailsCard,
                  if (instructorCard != null) ...[
                    const SizedBox(height: 24),
                    SectionHeader(l10n.planningInfoInstructor),
                    instructorCard,
                  ],
                  const SizedBox(height: 24),
                  SectionHeader(l10n.profileSectionAccount),
                  actionsCard,
                  const SizedBox(height: 24),
                  signOutSection,
                ],
              );

              Widget content;
              if (wide) {
                content = Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: left),
                    const SizedBox(width: 24),
                    Expanded(flex: 6, child: right),
                  ],
                );
              } else {
                content = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    left,
                    const SizedBox(height: 24),
                    right,
                  ],
                );
              }

              return ListView(
                padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 32),
                children: [
                  ResponsiveCenter(
                    maxWidth: context.isWideDesktop ? 1500 : 1200,
                    child: content,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
