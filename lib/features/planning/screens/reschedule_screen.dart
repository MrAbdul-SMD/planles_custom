import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets.dart';
import '../providers/planning_providers.dart';

/// Students may only reschedule more than 24h ahead and the new slot must
/// keep the original duration — both rules are enforced server side, this
/// screen tries to prevent the error from happening in the first place.
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

  @override
  void initState() {
    super.initState();
    final planning = ref.read(planningDetailProvider(widget.id)).value;
    final start = planning?.startDate;
    if (start != null) {
      _date = DateTime(start.year, start.month, start.day);
      _start = TimeOfDay(hour: start.hour, minute: start.minute);
    }
  }

  int get _duration {
    final p = ref.read(planningDetailProvider(widget.id)).value;
    return p == null ? 60 : p.durationMinutes;
  }

  DateTime? get _newStart {
    if (_date == null || _start == null) return null;
    return DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _start!.hour,
      _start!.minute,
    );
  }

  DateTime? get _newEnd {
    final start = _newStart;
    if (start == null) return null;
    return start.add(Duration(minutes: _duration));
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
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

  Future<void> _submit() async {
    final start = _newStart;
    final end = _newEnd;
    if (start == null || end == null) {
      showAppSnack(context, 'Kies een datum en starttijd.', error: true);
      return;
    }
    if (start.isBefore(DateTime.now())) {
      showAppSnack(context, 'De nieuwe datum moet in de toekomst liggen.',
          error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(planningRepositoryProvider).reschedule(
            id: widget.id,
            startDate: start,
            endDate: end,
          );
      ref.invalidate(planningDetailProvider(widget.id));
      ref.invalidate(planningListProvider);
      if (!mounted) return;
      showAppSnack(context, 'Les verplaatst');
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Les verplaatsen')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Kies een nieuw moment',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'De les duurt ${F.minutesLabel(_duration)} en moet minstens '
                '24 uur vooruit worden verplaatst.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: const Text('Datum'),
                      subtitle: Text(
                        _date == null
                            ? 'Nog niet gekozen'
                            : DateFormat('EEEE d MMMM yyyy', 'nl_NL')
                                .format(_date!),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _pickDate,
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.schedule_outlined),
                      title: const Text('Starttijd'),
                      subtitle: Text(
                        _start?.format(context) ?? 'Nog niet gekozen',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _pickTime,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_newStart != null && _newEnd != null)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('EEEE d MMMM yyyy', 'nl_NL')
                            .format(_newStart!),
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${F.time(_newStart!)} – ${F.time(_newEnd!)}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : const Text('Les verplaatsen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
