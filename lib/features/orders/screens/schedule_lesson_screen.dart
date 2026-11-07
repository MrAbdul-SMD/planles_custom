import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets.dart';
import '../../planning/providers/planning_providers.dart';
import '../models/order.dart';
import '../providers/orders_providers.dart';

/// Creates a planning slot for one order item.
/// `POST /planning/:itemId` where `:itemId` is the *order item* id.
class ScheduleLessonScreen extends ConsumerStatefulWidget {
  const ScheduleLessonScreen({
    super.key,
    required this.orderId,
    required this.itemId,
  });

  final int orderId;
  final int itemId;

  @override
  ConsumerState<ScheduleLessonScreen> createState() =>
      _ScheduleLessonScreenState();
}

class _ScheduleLessonScreenState extends ConsumerState<ScheduleLessonScreen> {
  DateTime? _date;

  @override
  void initState() {
    super.initState();
    ref.invalidate(orderItemsProvider(widget.orderId));
  }
  TimeOfDay? _start;
  int _duration = 60;
  bool _busy = false;

  int get _available {
    final items =
        ref.read(orderItemsProvider(widget.orderId)).value ??
        const <OrderItem>[];
    for (final item in items) {
      if (item.id == widget.itemId) return item.availableDuration ?? 0;
    }
    return 0;
  }

  OrderItem? get _item {
    final items =
        ref.read(orderItemsProvider(widget.orderId)).value ??
        const <OrderItem>[];
    for (final item in items) {
      if (item.id == widget.itemId) return item;
    }
    return null;
  }

  DateTime? get _startDateTime {
    if (_date == null || _start == null) return null;
    return DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _start!.hour,
      _start!.minute,
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now.add(const Duration(days: 1)),
      firstDate: now,
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

  Future<void> _submit() async {
    final l10n = context.l10n;
    final start = _startDateTime;
    if (start == null) {
      showAppSnack(context, l10n.scheduleLessonChooseDateTime, error: true);
      return;
    }
    final end = start.add(Duration(minutes: _duration));
    if (end.isBefore(DateTime.now())) {
      showAppSnack(context, l10n.scheduleLessonFutureDate, error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(planningRepositoryProvider)
          .create(orderItemId: widget.itemId, startDate: start, endDate: end);
      ref.invalidate(orderItemsProvider(widget.orderId));
      ref.invalidate(planningListProvider);
      if (!mounted) return;
      showAppSnack(context, l10n.scheduleLessonScheduled);
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
    final item = _item;
    final available = _available;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.scheduleLessonTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                item?.drivingClass?.name ?? l10n.orderDetailLesson,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                available > 0
                    ? l10n.scheduleLessonAvailable(
                        F.minutesLabel(l10n, available),
                      )
                    : l10n.scheduleLessonNoTimeLeft,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: available > 0
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: Text(l10n.scheduleLessonDate),
                      subtitle: Text(
                        _date == null
                            ? l10n.scheduleLessonNotChosen
                            : F.dateMedium(_date),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: available > 0 ? _pickDate : null,
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.schedule_outlined),
                      title: Text(l10n.scheduleLessonStartTime),
                      subtitle: Text(
                        _start?.format(context) ?? l10n.scheduleLessonNotChosen,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: available > 0 ? _pickTime : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.scheduleLessonDuration,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final minutes in const [45, 60, 90, 120])
                    ChoiceChip(
                      label: Text(F.minutesLabel(l10n, minutes)),
                      selected: _duration == minutes,
                      onSelected: available >= minutes
                          ? (_) => setState(() => _duration = minutes)
                          : null,
                    ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy || available <= 0 ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : Text(l10n.scheduleLessonScheduleButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
