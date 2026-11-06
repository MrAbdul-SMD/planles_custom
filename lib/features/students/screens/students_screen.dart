import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  Widget build(BuildContext context) {
    final students = ref.watch(myStudentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mijn leerlingen')),
      body: students.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: '$e',
          onRetry: () => ref.invalidate(myStudentsProvider),
        ),
        data: (list) {
          final filtered = _query.isEmpty
              ? list
              : list
                    .where(
                      (s) =>
                          s.fullName.toLowerCase().contains(
                            _query.toLowerCase(),
                          ) ||
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
                  decoration: const InputDecoration(
                    hintText: 'Zoek leerling',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const EmptyState(
                        icon: Icons.groups_outlined,
                        title: 'Geen leerlingen',
                        subtitle:
                            'Er zijn nog geen leerlingen aan je gekoppeld.',
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
    );
  }
}

class _StudentTile extends StatelessWidget {
  const _StudentTile({required this.student});

  final User student;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        leading: AppAvatar(initials: student.initials, size: 42),
        title: Text(
          student.fullName,
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
          builder: (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  InfoRow(
                    'E-mail',
                    student.email ?? '–',
                    icon: Icons.mail_outline,
                  ),
                  InfoRow(
                    'Telefoon',
                    student.phone ?? '–',
                    icon: Icons.phone_outlined,
                  ),
                  InfoRow(
                    'Adres',
                    [
                      student.street,
                      student.houseNumber,
                      student.zipCode,
                      student.city,
                    ].where((e) => e != null && e.isNotEmpty).join(' '),
                    icon: Icons.home_outlined,
                  ),
                  if (student.pickupLocation != null &&
                      student.pickupLocation!.isNotEmpty)
                    InfoRow(
                      'Ophaallocatie',
                      student.pickupLocation!,
                      icon: Icons.location_on_outlined,
                    ),
                  InfoRow(
                    'Saldo',
                    student.balance?.toStringAsFixed(2) ?? '–',
                    icon: Icons.account_balance_wallet_outlined,
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
