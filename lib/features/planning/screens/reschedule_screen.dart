import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/planning.dart';
import '../providers/planning_providers.dart';

/// Students may only reschedule more than 24h ahead and the new slot must
/// keep the original duration — both rules are enforced server side.
class RescheduleScreen extends ConsumerStatefulWidget {
  const RescheduleScreen({super.key, required this.id});

  final int id;

  @override
  ConsumerState<RescheduleScreen> createState() => _RescheduleScreenState();
}

class _RescheduleScreenState extends ConsumerState<RescheduleScreen> {
  DateTime? _date;
  TimeOfDay? _start;
  bool _busy = false;
  bool _initialized = false;

  void _initFromPlanning(Planning planning) {
    if (_initialized) return;
    _initialized = true;
    final start = planning.startDate;
    if (start != null) {
      _date = DateTime(start.year, start.month, start.day);
      _start = TimeOfDay(hour: start.hour, minute: start.minute);
    }
  }

  DateTime? _calcStart() {
    if (_date == null || _start == null) return null;
    return DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _start!.hour,
      _start!.minute,
    );
  }

  DateTime? _calcEnd(int durationMinutes) {
    final start = _calcStart();
    if (start == null) return null;
    return start.add(Duration(minutes: durationMinutes));
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final user = ref.read(currentUserProvider);
    final isStudent = user?.isInstructor != true;
    final firstAllowed = isStudent ? now.add(const Duration(hours: 24)) : now;

    final picked = await showDatePicker(
      context: context,
      initialDate: _date != null && _date!.isAfter(firstAllowed)
          ? _date!
          : firstAllowed.add(const Duration(days: 1)),
      firstDate: firstAllowed,
      lastDate: now.add(const Duration(days: 365)),
      locale: Localizations.localeOf(context),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _start ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _submit(Planning planning) async {
    final l10n = context.l10n;
    final duration = planning.durationMinutes > 0 ? planning.durationMinutes : 60;
    final start = _calcStart();
    final end = _calcEnd(duration);

    if (start == null || end == null) {
      showAppSnack(context, l10n.reschedulePickDateTime, error: true);
      return;
    }

    final now = DateTime.now();
    final user = ref.read(currentUserProvider);
    final isStudent = user?.isInstructor != true;

    if (start.isBefore(now)) {
      showAppSnack(context, l10n.rescheduleFutureDate, error: true);
      return;
    }

    if (isStudent && start.isBefore(now.add(const Duration(hours: 24)))) {
      showAppSnack(
        context,
        'Leerlingen kunnen lessen minimaal 24 uur van tevoren inplannen.',
        error: true,
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await ref
          .read(planningRepositoryProvider)
          .reschedule(id: widget.id, startDate: start, endDate: end);
      ref.invalidate(planningDetailProvider(widget.id));
      ref.invalidate(planningListProvider);
      if (!mounted) return;
      showAppSnack(context, l10n.planningLessonRescheduled);
      context.pop();
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
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final async = ref.watch(planningDetailProvider(widget.id));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.planningRescheduleLesson)),
      body: AsyncView<Planning>(
        value: async,
        onRetry: () => ref.invalidate(planningDetailProvider(widget.id)),
        data: (planning) {
          _initFromPlanning(planning);
          final duration = planning.durationMinutes > 0 ? planning.durationMinutes : 60;
          final newStart = _calcStart();
          final newEnd = _calcEnd(duration);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    l10n.reschedulePickMoment,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.rescheduleDurationHint(F.minutesLabel(l10n, duration)),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ------------------------------ Original vs New Slot Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 18,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Huidig gepland tijdstip',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.outline,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          planning.startDate != null
                              ? '${F.dateMedium(planning.startDate!)} · ${F.time(planning.startDate!)} – ${planning.endDate != null ? F.time(planning.endDate!) : ''}'
                              : l10n.planningDateNotSet,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_downward_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ---------------------------------------- Pick Date & Time
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.calendar_today_rounded,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          title: Text(
                            l10n.rescheduleDateLabel,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            _date == null
                                ? l10n.rescheduleNotChosen
                                : F.dateMedium(_date!),
                            style: TextStyle(
                              color: _date == null
                                  ? theme.colorScheme.outline
                                  : theme.colorScheme.onSurface,
                              fontWeight: _date != null ? FontWeight.w700 : null,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: _pickDate,
                        ),
                        const Divider(),
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.schedule_rounded,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          title: Text(
                            l10n.rescheduleStartTimeLabel,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            _start?.format(context) ?? l10n.rescheduleNotChosen,
                            style: TextStyle(
                              color: _start == null
                                  ? theme.colorScheme.outline
                                  : theme.colorScheme.onSurface,
                              fontWeight: _start != null ? FontWeight.w700 : null,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: _pickTime,
                        ),
                      ],
                    ),
                  ),

                  if (newStart != null && newEnd != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Nieuw voorgesteld moment',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Spacer(),
                              StatusChip(
                                label: F.minutesLabel(l10n, duration),
                                tone: StatusTone.info,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            F.dateMedium(newStart),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${F.time(newStart)} – ${F.time(newEnd)}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: _busy || newStart == null ? null : () => _submit(planning),
                    child: _busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        : Text(l10n.planningRescheduleLesson),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
