import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/planning_repository.dart';
import '../models/planning.dart';
import '../providers/planning_providers.dart';

class PlanningDetailScreen extends ConsumerStatefulWidget {
  const PlanningDetailScreen({super.key, required this.id});

  final int id;

  @override
  ConsumerState<PlanningDetailScreen> createState() =>
      _PlanningDetailScreenState();
}

class _PlanningDetailScreenState extends ConsumerState<PlanningDetailScreen> {
  bool _busy = false;

  PlanningRepository get _repo => ref.read(planningRepositoryProvider);

  Future<void> _run(
    Future<void> Function() action, {
    String success = 'Gelukt',
  }) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(planningDetailProvider(widget.id));
      ref.invalidate(planningListProvider);
      if (mounted) showAppSnack(context, success);
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.validationMessage, error: true);
    } catch (e) {
      if (mounted) showAppSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() =>
      _run(() => _repo.confirm(widget.id), success: 'Les bevestigd');

  Future<void> _cancel() async {
    final reason = await _askCancelReason();
    if (reason == null) return;
    await _run(
      () => _repo.cancel(widget.id, reason: reason),
      success: 'Les geannuleerd',
    );
  }

  Future<String?> _askCancelReason() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Les annuleren'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Reden (optioneel)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Terug'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Annuleren'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _complete() async {
    final ok = await confirmAction(
      context,
      title: 'Les afronden',
      message: 'Weet je zeker dat je deze les wilt afronden?',
      confirmLabel: 'Afronden',
    );
    if (!ok) return;
    await _run(() => _repo.complete(widget.id), success: 'Les afgerond');
  }

  Future<void> _editNotes(Planning planning) async {
    final controller = TextEditingController(text: planning.notes ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notities bijwerken'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Notities'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Opslaan'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return;
    await _run(
      () => _repo.updateNotes(widget.id, result),
      success: 'Notities opgeslagen',
    );
  }

  Future<void> _studentConfirmation(bool confirmed) async {
    final ok = await confirmAction(
      context,
      title: confirmed ? 'Bevestigen' : 'Afwezigheid melden',
      message: confirmed ? 'Bevestig dat deze les heeft plaatsgevonden.' : 'Meld je afwezigheid. Je instructeur en de administratie worden op de hoogte gebracht.',
      confirmLabel: 'Bevestigen',
      destructive: !confirmed,
    );
    if (!ok) return;
    await _run(
      () => _repo.studentConfirmation(widget.id, confirmed: confirmed),
      success: 'Bevestigd',
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(planningDetailProvider(widget.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Lesdetails')),
      body: AsyncView<Planning>(
        value: async,
        onRetry: () => ref.invalidate(planningDetailProvider(widget.id)),
        data: (planning) => _body(context, planning),
      ),
    );
  }

  Widget _body(BuildContext context, Planning planning) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final isStudent = user?.isInstructor != true;
    final start = planning.startDate;
    final end = planning.endDate;
    final actions = _actions(planning, isStudent);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        // ---------------------------------------------------------- header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      planning.drivingClass?.name ?? 'Les',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  StatusChip(
                    label: planning.statusLabel,
                    tone: PlanningTone.forStatus(planning.status),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                start == null ? 'Datum niet ingesteld' : F.dateMedium(start),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                [
                  if (start != null && end != null)
                    '${F.time(start)} – ${F.time(end)}',
                  if (planning.durationMinutes > 0)
                    F.minutesLabel(planning.durationMinutes),
                ].join(' · '),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // -------------------------------------------------------- details
        SectionHeader('Gegevens'),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                InfoRow('Les', planning.drivingClass?.name ?? '–'),
                InfoRow('Lesvorm', switch (planning.drivingClass?.lessonType) {
                  'trial' => 'Proefles',
                  'base' => 'Basisles',
                  'pack' => 'Lespakket',
                  'exam' => 'Examen',
                  _ => '–',
                }),
                InfoRow(
                  isStudent ? 'Instructeur' : 'Leerling',
                  isStudent
                      ? (planning.instructor?.fullName ?? '–')
                      : (planning.student?.fullName ?? '–'),
                ),
                if (planning.student?.phone != null)
                  InfoRow('Telefoon', planning.student!.phone!),
                InfoRow('Bestelling', '#${planning.order?.id ?? '–'}'),
                if (planning.payment?.finalAmountValue != null)
                  InfoRow(
                    'Betaald',
                    F.money(planning.payment!.finalAmountValue),
                  ),
              ],
            ),
          ),
        ),

        // ----------------------------------------------------------- notes
        if (planning.notes != null && planning.notes!.isNotEmpty) ...[
          const SizedBox(height: 20),
          SectionHeader(
            'Notities',
            trailing: user?.isInstructor == true
                ? TextButton(
                    onPressed: _busy ? null : () => _editNotes(planning),
                    child: const Text('Bewerken'),
                  )
                : null,
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(planning.notes!),
            ),
          ),
        ],

        if (planning.cancelReason != null &&
            planning.cancelReason!.isNotEmpty) ...[
          const SizedBox(height: 20),
          const SectionHeader('Annuleringsreden'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(planning.cancelReason!),
            ),
          ),
        ],

        // --------------------------------------------------------- actions
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 24),
          SectionHeader('Acties'),
          for (final action in actions) ...[action, const SizedBox(height: 10)],
        ],

        // ----------------------------------------------------------- logs
        if (planning.logs.isNotEmpty) ...[
          const SizedBox(height: 24),
          const SectionHeader('Geschiedenis'),
          Card(
            child: Column(
              children: [
                for (final (i, log) in planning.logs.indexed) ...[
                  if (i > 0) const Divider(),
                  ListTile(
                    leading: Icon(switch (log.action) {
                      'created' => Icons.add_circle_outline,
                      'confirmed' => Icons.check_circle_outline,
                      'cancelled' => Icons.cancel_outlined,
                      'completed' => Icons.task_alt,
                      'rescheduled' => Icons.event_repeat_outlined,
                      _ => Icons.history,
                    }, color: theme.colorScheme.primary),
                    title: Text(_logLabel(log.action)),
                    subtitle: Text(
                      [
                        log.user?.fullName,
                        if (log.createdAt != null) F.dateTime(log.createdAt),
                      ].where((e) => e != null && e.isNotEmpty).join(' · '),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _logLabel(String? action) => switch (action) {
    'created' => 'Les ingepland',
    'confirmed' => 'Les bevestigd',
    'cancelled' => 'Les geannuleerd',
    'completed' => 'Les afgerond',
    'rescheduled' => 'Les verplaatst',
    _ => 'Wijziging',
  };

  List<Widget> _actions(Planning planning, bool isStudent) {
    if (_busy) {
      return [
        const Center(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(),
          ),
        ),
      ];
    }

    final actions = <Widget>[];
    final canReschedule =
        planning.isConfirmed &&
        (planning.startDate?.isAfter(
              DateTime.now().add(const Duration(hours: 24)),
            ) ??
            false);

    if (isStudent) {
      if (planning.isPending) {
        actions.add(
          FilledButton.icon(
            onPressed: _confirm,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Les bevestigen'),
          ),
        );
      }
      if (planning.isPending || planning.isConfirmed) {
        actions.add(
          OutlinedButton.icon(
            onPressed: _cancel,
            icon: const Icon(Icons.close_rounded),
            label: const Text('Les annuleren'),
          ),
        );
      }
      if (canReschedule) {
        actions.add(
          OutlinedButton.icon(
            onPressed: () => context.push('/planning/${widget.id}/reschedule'),
            icon: const Icon(Icons.event_repeat_outlined),
            label: const Text('Les verplaatsen'),
          ),
        );
      }
      if (planning.isCompleted && planning.studentConfirmation == null) {
        actions.add(
          FilledButton.icon(
            onPressed: () => _studentConfirmation(true),
            icon: const Icon(Icons.how_to_reg_outlined),
            label: const Text('Ik was aanwezig'),
          ),
        );
        actions.add(
          OutlinedButton.icon(
            onPressed: () => _studentConfirmation(false),
            icon: const Icon(Icons.person_off_outlined),
            label: const Text('Ik was afwezig'),
          ),
        );
      }
      if (planning.studentConfirmation != null) {
        actions.add(
          Card(
            child: ListTile(
              leading: Icon(
                planning.studentConfirmation!
                    ? Icons.how_to_reg_outlined
                    : Icons.person_off_outlined,
                color: planning.studentConfirmation!
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error,
              ),
              title: Text(
                planning.studentConfirmation!
                    ? 'Aanwezigheid bevestigd'
                    : 'Afwezigheid gemeld',
              ),
            ),
          ),
        );
      }
    } else {
      if (planning.isConfirmed) {
        actions.add(
          FilledButton.icon(
            onPressed: _complete,
            icon: const Icon(Icons.task_alt),
            label: const Text('Les afronden'),
          ),
        );
      }
      actions.add(
        OutlinedButton.icon(
          onPressed: () => _editNotes(planning),
          icon: const Icon(Icons.edit_note_outlined),
          label: const Text('Notities bijwerken'),
        ),
      );
      if (planning.isPending || planning.isConfirmed) {
        actions.add(
          OutlinedButton.icon(
            onPressed: _cancel,
            icon: const Icon(Icons.close_rounded),
            label: const Text('Les annuleren'),
          ),
        );
      }
    }

    actions.add(
      OutlinedButton.icon(
        onPressed: () => context.push('/planning/${widget.id}/lesson-cards'),
        icon: const Icon(Icons.fact_check_outlined),
        label: const Text('Leskaart bekijken'),
      ),
    );

    return actions;
  }
}
