import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../l10n/l10n.dart';
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

  Future<void> _run(Future<void> Function() action, {String? success}) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(planningDetailProvider(widget.id));
      ref.invalidate(planningListProvider);
      if (mounted) {
        showAppSnack(context, success ?? context.l10n.genericSuccess);
      }
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

  Future<void> _confirm() => _run(
    () => _repo.confirm(widget.id),
    success: context.l10n.planningLessonConfirmed,
  );

  Future<void> _cancel() async {
    final l10n = context.l10n;
    final reason = await _askCancelReason();
    if (reason == null) return;
    await _run(
      () => _repo.cancel(widget.id, reason: reason),
      success: l10n.planningLessonCancelled,
    );
  }

  Future<String?> _askCancelReason() async {
    final l10n = context.l10n;
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.planningCancelLesson),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: l10n.planningCancelReasonLabel,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.back),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _complete() async {
    final l10n = context.l10n;
    final ok = await confirmAction(
      context,
      title: l10n.planningCompleteLesson,
      message: l10n.planningCompleteConfirmMessage,
      confirmLabel: l10n.planningCompleteAction,
    );
    if (!ok) return;
    await _run(
      () => _repo.complete(widget.id),
      success: l10n.planningLessonCompleted,
    );
  }

  Future<void> _editNotes(Planning planning) async {
    final l10n = context.l10n;
    final controller = TextEditingController(text: planning.notes ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.planningEditNotes),
        content: TextField(
          controller: controller,
          maxLines: 5,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.planningNotes),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return;
    await _run(
      () => _repo.updateNotes(widget.id, result),
      success: l10n.planningNotesSaved,
    );
  }

  Future<void> _studentConfirmation(bool confirmed) async {
    final l10n = context.l10n;
    final ok = await confirmAction(
      context,
      title: confirmed ? l10n.confirm : l10n.planningReportAbsenceTitle,
      message: confirmed
          ? l10n.planningConfirmAttendedMessage
          : l10n.planningReportAbsentMessage,
      destructive: !confirmed,
    );
    if (!ok) return;
    await _run(
      () => _repo.studentConfirmation(widget.id, confirmed: confirmed),
      success: l10n.statusConfirmed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final async = ref.watch(planningDetailProvider(widget.id));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.planningDetailTitle)),
      body: AsyncView<Planning>(
        value: async,
        onRetry: () => ref.invalidate(planningDetailProvider(widget.id)),
        data: (planning) => _body(context, planning),
      ),
    );
  }

  Widget _body(BuildContext context, Planning planning) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final isStudent = user?.isInstructor != true;
    final start = planning.startDate;
    final end = planning.endDate;
    final actions = _actions(planning, isStudent);

    return SafeArea(
      bottom: true,
      child: ListView(
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
                      planning.drivingClass?.name ?? l10n.planningLesson,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  StatusChip(
                    label: planning.statusLabel(l10n),
                    tone: PlanningTone.forStatus(planning.status),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                start == null ? l10n.planningDateNotSet : F.dateMedium(start),
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
                    F.minutesLabel(l10n, planning.durationMinutes),
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
        SectionHeader(l10n.planningSectionDetails),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                InfoRow(
                  l10n.planningNumber(planning.id),
                  '#${planning.id}',
                ),
                InfoRow(
                  l10n.planningInfoLessonType,
                  switch (planning.drivingClass?.lessonType) {
                    'trial' => l10n.planningTypeTrial,
                    'base' => l10n.planningTypeBase,
                    'pack' => l10n.planningTypePack,
                    'exam' => l10n.planningTypeExam,
                    _ => '–',
                  },
                ),
                InfoRow(
                  isStudent
                      ? l10n.planningInfoInstructor
                      : l10n.planningInfoStudent,
                  isStudent
                      ? (planning.instructor?.displayName(l10n) ?? '–')
                      : (planning.student?.displayName(l10n) ?? '–'),
                ),
                if (planning.student?.phone != null)
                  InfoRow(l10n.planningInfoPhone, planning.student!.phone!),
                InfoRow(
                  l10n.planningInfoOrder,
                  '#${planning.order?.id ?? '–'}',
                ),
                if (planning.payment?.finalAmountValue != null)
                  InfoRow(
                    l10n.planningInfoPaid,
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
            l10n.planningNotes,
            trailing: user?.isInstructor == true
                ? TextButton(
                    onPressed: _busy ? null : () => _editNotes(planning),
                    child: Text(l10n.edit),
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
          SectionHeader(l10n.planningCancelReasonTitle),
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
          SectionHeader(l10n.planningSectionActions),
          for (final action in actions) ...[action, const SizedBox(height: 10)],
        ],

        // ----------------------------------------------------------- logs
        if (planning.logs.isNotEmpty) ...[
          const SizedBox(height: 24),
          SectionHeader(l10n.planningSectionHistory),
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
                    title: Text(_logLabel(l10n, log.action)),
                    subtitle: Text(
                      [
                        log.user?.displayName(l10n),
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
    ),
    );
  }

  String _logLabel(AppLocalizations l10n, String? action) => switch (action) {
    'created' => l10n.planningLessonScheduled,
    'confirmed' => l10n.planningLessonConfirmed,
    'cancelled' => l10n.planningLessonCancelled,
    'completed' => l10n.planningLessonCompleted,
    'rescheduled' => l10n.planningLessonRescheduled,
    _ => l10n.planningLogChange,
  };

  List<Widget> _actions(Planning planning, bool isStudent) {
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider);
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
      if (planning.canBeConfirmedBy(user)) {
        actions.add(
          FilledButton.icon(
            onPressed: _confirm,
            icon: const Icon(Icons.check_rounded),
            label: Text(l10n.planningConfirmLesson),
          ),
        );
      } else if (planning.isPending) {
        // The current user proposed this slot — wait for the other party.
        actions.add(
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                l10n.planningAwaitingConfirmation,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
      }
      if (planning.isPending || planning.isConfirmed) {
        actions.add(
          OutlinedButton.icon(
            onPressed: _cancel,
            icon: const Icon(Icons.close_rounded),
            label: Text(l10n.planningCancelLesson),
          ),
        );
      }
      if (canReschedule) {
        actions.add(
          OutlinedButton.icon(
            onPressed: () => context.push('/planning/${widget.id}/reschedule'),
            icon: const Icon(Icons.event_repeat_outlined),
            label: Text(l10n.planningRescheduleLesson),
          ),
        );
      }
      if (planning.isCompleted && planning.studentConfirmation == null) {
        actions.add(
          FilledButton.icon(
            onPressed: () => _studentConfirmation(true),
            icon: const Icon(Icons.how_to_reg_outlined),
            label: Text(l10n.planningWasPresent),
          ),
        );
        actions.add(
          OutlinedButton.icon(
            onPressed: () => _studentConfirmation(false),
            icon: const Icon(Icons.person_off_outlined),
            label: Text(l10n.planningWasAbsent),
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
                    ? l10n.planningAttendanceConfirmed
                    : l10n.planningAbsenceReported,
              ),
            ),
          ),
        );
      }
    } else {
      if (planning.canBeConfirmedBy(user)) {
        actions.add(
          FilledButton.icon(
            onPressed: _confirm,
            icon: const Icon(Icons.check_rounded),
            label: Text(l10n.planningConfirmLesson),
          ),
        );
      } else if (planning.isPending) {
        actions.add(
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                l10n.planningAwaitingConfirmation,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
      }
      if (planning.isConfirmed) {
        actions.add(
          FilledButton.icon(
            onPressed: _complete,
            icon: const Icon(Icons.task_alt),
            label: Text(l10n.planningCompleteLesson),
          ),
        );
      }
      actions.add(
        OutlinedButton.icon(
          onPressed: () => _editNotes(planning),
          icon: const Icon(Icons.edit_note_outlined),
          label: Text(l10n.planningEditNotes),
        ),
      );
      if (planning.isPending || planning.isConfirmed) {
        actions.add(
          OutlinedButton.icon(
            onPressed: _cancel,
            icon: const Icon(Icons.close_rounded),
            label: Text(l10n.planningCancelLesson),
          ),
        );
      }
      // Instructors can reschedule pending or confirmed plannings.
      if (planning.isPending || planning.isConfirmed) {
        actions.add(
          OutlinedButton.icon(
            onPressed: () => context.push('/planning/${widget.id}/reschedule'),
            icon: const Icon(Icons.event_repeat_outlined),
            label: Text(l10n.planningRescheduleLesson),
          ),
        );
      }
    }

    actions.add(
      OutlinedButton.icon(
        onPressed: () => context.push('/planning/${widget.id}/lesson-cards'),
        icon: const Icon(Icons.fact_check_outlined),
        label: Text(l10n.lessonCardView),
      ),
    );

    return actions;
  }
}
