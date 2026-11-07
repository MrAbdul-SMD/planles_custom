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
  TimeOfDay? _start;
  int _duration = 60;
  bool _busy = false;
  bool _durationInitialized = false;

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
      initialTime: _start ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _submit(OrderItem item) async {
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
    final itemsAsync = ref.watch(orderItemsProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.scheduleLessonTitle)),
      body: AsyncView<List<OrderItem>>(
        value: itemsAsync,
        onRetry: () => ref.refresh(orderItemsProvider(widget.orderId)),
        data: (items) {
          final item = items.where((i) => i.id == widget.itemId).firstOrNull;
          if (item == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.errLessonNotFound,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.pop(),
                      child: Text(l10n.back),
                    ),
                  ],
                ),
              ),
            );
          }

          final available = item.availableDuration ?? 0;

          if (!_durationInitialized && available > 0) {
            _durationInitialized = true;
            if (available >= 60) {
              _duration = 60;
            } else if (available >= 45) {
              _duration = 45;
            } else {
              _duration = available;
            }
          }

          final start = _startDateTime;
          final end = start?.add(Duration(minutes: _duration));

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // ---------------------------------------- Header Item Dossier
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(20),
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
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.directions_car_rounded,
                                color: theme.colorScheme.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.drivingClass?.name ?? l10n.orderDetailLesson,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Bestelling #${widget.orderId} · Item #${widget.itemId}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.outline,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: available > 0
                                ? (theme.brightness == Brightness.dark
                                    ? const Color(0xFF064E3B)
                                    : const Color(0xFFECFDF5))
                                : theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                available > 0
                                    ? Icons.timelapse_rounded
                                    : Icons.warning_amber_rounded,
                                size: 18,
                                color: available > 0
                                    ? (theme.brightness == Brightness.dark
                                        ? const Color(0xFF6EE7B7)
                                        : const Color(0xFF047857))
                                    : theme.colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  available > 0
                                      ? l10n.scheduleLessonAvailable(
                                          F.minutesLabel(l10n, available),
                                        )
                                      : l10n.scheduleLessonNoTimeLeft,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: available > 0
                                        ? (theme.brightness == Brightness.dark
                                            ? const Color(0xFF6EE7B7)
                                            : const Color(0xFF047857))
                                        : theme.colorScheme.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (available <= 0) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              size: 40,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Alle uren uit dit lespakket zijn reeds ingepland.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.tonal(
                              onPressed: () => context.go('/planning'),
                              child: const Text('Naar Planning'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    // ---------------------------------------- Date & Time Pickers
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
                              l10n.scheduleLessonDate,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              _date == null
                                  ? l10n.scheduleLessonNotChosen
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
                              l10n.scheduleLessonStartTime,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              _start?.format(context) ?? l10n.scheduleLessonNotChosen,
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

                    const SizedBox(height: 24),

                    // ---------------------------------------- Duration Selection
                    Text(
                      l10n.scheduleLessonDuration,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 12),
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

                    if (start != null && end != null) ...[
                      const SizedBox(height: 24),
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
                                  Icons.event_available_rounded,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Overzicht lesafspraak',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Spacer(),
                                StatusChip(
                                  label: F.minutesLabel(l10n, _duration),
                                  tone: StatusTone.info,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              F.dateMedium(start),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${F.time(start)} – ${F.time(end)}',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Resterend na inplannen: ${F.minutesLabel(l10n, available - _duration)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed:
                          _busy || start == null || available < _duration
                              ? null
                              : () => _submit(item),
                      child: _busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.4),
                            )
                          : Text(l10n.scheduleLessonScheduleButton),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
