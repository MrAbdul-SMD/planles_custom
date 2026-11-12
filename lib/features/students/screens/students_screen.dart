import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/widgets.dart';
import '../../auth/models/user.dart';
import '../providers/directory_providers.dart';

class StudentsScreen extends ConsumerStatefulWidget {
  const StudentsScreen({super.key});

  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends ConsumerState<StudentsScreen> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    ref.invalidate(myStudentsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final students = ref.watch(myStudentsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.studentsTitle)),
      body: SafeArea(
        top: false,
        child: students.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorView(
            message: describeError(context, e),
            onRetry: () => ref.invalidate(myStudentsProvider),
          ),
          data: (list) {
          final filtered = _query.isEmpty
              ? list
              : list
                    .where(
                      (s) =>
                          s
                              .displayName(l10n)
                              .toLowerCase()
                              .contains(_query.toLowerCase()) ||
                          (s.email ?? '').toLowerCase().contains(
                            _query.toLowerCase(),
                          ),
                    )
                    .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: l10n.studentsSearchHint,
                    prefixIcon: const Icon(Icons.search_rounded),
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.groups_outlined,
                        title: l10n.studentsEmptyTitle,
                        subtitle: l10n.studentsEmptySubtitle,
                      )
                    : RefreshIndicator(
                        onRefresh: () async =>
                            ref.invalidate(myStudentsProvider),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) =>
                              _StudentTile(student: filtered[index]),
                        ),
                      ),
              ),
            ],
          );
        },
        ),
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  const _StudentTile({required this.student});

  final User student;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        leading: AppAvatar(initials: student.initials, size: 42),
        title: Text(
          student.displayName(l10n),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(student.email ?? ''),
        trailing: student.balance != null
            ? Text(
                '€ ${student.balance!.toStringAsFixed(2)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              )
            : null,
        onTap: () => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          builder: (context) {
            final theme = Theme.of(context);
            final scheme = theme.colorScheme;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppAvatar(initials: student.initials, size: 52),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student.displayName(l10n),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              if ((student.email ?? '').isNotEmpty)
                                Text(
                                  student.email!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Column(
                        children: [
                          InfoRow(
                            l10n.studentsEmailLabel,
                            student.email ?? '–',
                            icon: Icons.mail_outline,
                          ),
                          const Divider(height: 12),
                          InfoRow(
                            l10n.studentsPhoneLabel,
                            student.phone ?? '–',
                            icon: Icons.phone_outlined,
                          ),
                          const Divider(height: 12),
                          InfoRow(
                            l10n.studentsAddressLabel,
                            [
                              student.street,
                              student.houseNumber,
                              student.zipCode,
                              student.city,
                            ].where((e) => e != null && e.isNotEmpty).join(' '),
                            icon: Icons.home_outlined,
                          ),
                          if (student.pickupLocation != null &&
                              student.pickupLocation!.isNotEmpty) ...[
                            const Divider(height: 12),
                            InfoRow(
                              l10n.studentsPickupLabel,
                              student.pickupLocation!,
                              icon: Icons.location_on_outlined,
                            ),
                          ],
                          const Divider(height: 12),
                          InfoRow(
                            l10n.dashboardBalanceLabel,
                            student.balance?.toStringAsFixed(2) ?? '–',
                            icon: Icons.account_balance_wallet_outlined,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
