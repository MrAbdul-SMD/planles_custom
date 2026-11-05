import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/widgets.dart';
import '../models/app_notification.dart';
import '../providers/notifications_providers.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  NotificationSettings? _draft;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(notificationSettingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Meldingsinstellingen')),
      body: AsyncView<NotificationSettings>(
        value: async,
        onRetry: () => ref.invalidate(notificationSettingsProvider),
        data: (settings) {
          _draft ??= settings;
          final draft = _draft!;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              const SectionHeader('Niet storen'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Stille uren'),
                      subtitle: Text(
                        'Geen meldingen tussen '
                        '${_timeLabel(draft.quietHours.start)} en '
                        '${_timeLabel(draft.quietHours.end)}',
                      ),
                      value: draft.quietHours.enabled,
                      onChanged: (value) => _updateQuiet(
                        draft.quietHours.copyWith(enabled: value),
                      ),
                    ),
                    if (draft.quietHours.enabled) ...[
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.bedtime_outlined),
                        title: const Text('Begin'),
                        trailing: Text(
                          _timeLabel(draft.quietHours.start),
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        onTap: () => _pickTime(
                          initial: draft.quietHours.start,
                          onPicked: (v) => _updateQuiet(
                            draft.quietHours.copyWith(start: v),
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.wb_sunny_outlined),
                        title: const Text('Einde'),
                        trailing: Text(
                          _timeLabel(draft.quietHours.end),
                          style: theme.textTheme.titleSmall
                             ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        onTap: () => _pickTime(
                          initial: draft.quietHours.end,
                          onPicked: (v) => _updateQuiet(
                            draft.quietHours.copyWith(end: v),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const SectionHeader('Soorten meldingen'),
              Card(
                child: Column(
                  children: [
                    for (final (i, pref) in draft.preferences.indexed) ...[
                      if (i > 0) const Divider(),
                      SwitchListTile(
                        title: Text(pref.label),
                        value: pref.inAppEnabled || pref.pushEnabled,
                        onChanged: (value) => _toggle(pref, value),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : const Text('Opslaan'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _timeLabel(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts.first) ?? 0;
    final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return TimeOfDay(hour: h, minute: m).format(context);
  }

  void _updateQuiet(QuietHours quiet) {
    setState(() {
      _draft = NotificationSettings(
        quietHours: quiet,
        preferences: _draft!.preferences,
      );
    });
  }

  void _toggle(NotificationPreference pref, bool value) {
    setState(() {
      final updated = [
        for (final p in _draft!.preferences)
          p.type == pref.type
              ? NotificationPreference(
                  type: p.type,
                  inAppEnabled: value,
                  pushEnabled: value,
                )
              : p,
      ];
      _draft = NotificationSettings(
        quietHours: _draft!.quietHours,
        preferences: updated,
      );
    });
  }

  Future<void> _pickTime({
    required String initial,
    required ValueChanged<String> onPicked,
  }) async {
    final parts = initial.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts.first) ?? 22,
        minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
      ),
    );
    if (picked == null) return;
    onPicked(
      '${picked.hour.toString().padLeft(2, '0')}:'
      '${picked.minute.toString().padLeft(2, '0')}',
    );
  }

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null) return;
    setState(() => _saving = true);
    try {
      final updated = await ref
          .read(notificationsRepositoryProvider)
          .updateSettings(draft);
      ref.invalidate(notificationSettingsProvider);
      if (mounted) {
        setState(() => _draft = updated);
        showAppSnack(context, 'Instellingen opgeslagen');
      }
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.validationMessage, error: true);
    } catch (e) {
      if (mounted) showAppSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
