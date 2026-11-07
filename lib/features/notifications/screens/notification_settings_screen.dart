import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../l10n/language_picker.dart';
import '../../../l10n/l10n.dart';
import '../../../l10n/theme_mode_picker.dart';
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
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notifSettingsTitle)),
      body: AsyncView<NotificationSettings>(
        value: async,
        onRetry: () => ref.invalidate(notificationSettingsProvider),
        data: (settings) {
          _draft ??= settings;
          final draft = _draft!;

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
              const LanguageListTile(),
              const SizedBox(height: 12),
              const ThemeModeListTile(),
              const SizedBox(height: 12),
              SectionHeader(l10n.notifSettingsQuietSection),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(l10n.notifSettingsQuietHours),
                      subtitle: Text(
                        l10n.notifSettingsQuietRange(
                          _timeLabel(draft.quietHours.start),
                          _timeLabel(draft.quietHours.end),
                        ),
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
                        title: Text(l10n.notifSettingsQuietStart),
                        trailing: Text(
                          _timeLabel(draft.quietHours.start),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onTap: () => _pickTime(
                          initial: draft.quietHours.start,
                          onPicked: (v) =>
                              _updateQuiet(draft.quietHours.copyWith(start: v)),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.wb_sunny_outlined),
                        title: Text(l10n.notifSettingsQuietEnd),
                        trailing: Text(
                          _timeLabel(draft.quietHours.end),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onTap: () => _pickTime(
                          initial: draft.quietHours.end,
                          onPicked: (v) =>
                              _updateQuiet(draft.quietHours.copyWith(end: v)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SectionHeader(l10n.notifSettingsTypesSection),
              Card(
                child: Column(
                  children: [
                    for (final (i, pref) in draft.preferences.indexed) ...[
                      if (i > 0) const Divider(),
                      SwitchListTile(
                        title: Text(pref.label(l10n)),
                        subtitle: pref.locked
                            ? Text(l10n.notifPrefLocked)
                            : null,
                        value: pref.pushEnabled,
                        onChanged: pref.locked
                            ? null
                            : (value) => _toggle(pref, value),
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
                    : Text(l10n.save),
              ),
            ],
          ),
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
          p.category == pref.category
              ? NotificationPreference(
                  category: p.category,
                      locked: p.locked,
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
    // `ACCOUNT` is locked and not editable on the backend — don't send it.
    final toSave = NotificationSettings(
      quietHours: draft.quietHours,
      preferences: draft.preferences.where((p) => !p.locked).toList(),
    );
    setState(() => _saving = true);
    try {
      final updated = await ref
          .read(notificationsRepositoryProvider)
          .updateSettings(toSave);
      ref.invalidate(notificationSettingsProvider);
      if (mounted) {
        setState(() => _draft = updated);
        showAppSnack(context, context.l10n.notifSettingsSaved);
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
      if (mounted) setState(() => _saving = false);
    }
  }
}
