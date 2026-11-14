import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/responsive.dart';
import '../../../core/utils/formatters.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets.dart';
import '../models/app_notification.dart';
import '../providers/notifications_providers.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  /// Whether the initial load has finished. Used to distinguish "still
  /// loading for the first time" from "loaded but empty".
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_initialLoad);
  }

  Future<void> _initialLoad() async {
    try {
      await ref.read(notificationsProvider.notifier).refresh();
    } catch (_) {
      // The error view already reflects the failure on rebuild.
    } finally {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _refresh() async {
    try {
      await ref.read(notificationsProvider.notifier).refresh();
    } catch (_) {
      if (mounted) {
        showAppSnack(
          context,
          context.l10n.notificationsRefreshFailed,
          error: true,
        );
      }
    }
  }

  Future<void> _open(AppNotification notification) async {
    if (!notification.isRead) {
      await ref.read(notificationsProvider.notifier).markRead(notification.id);
      ref.invalidate(unreadCountProvider);
    }
    final data = notification.data ?? const <String, dynamic>{};
    final planningId = int.tryParse(data['planningId']?.toString() ?? '');
    final orderId = int.tryParse(data['orderId']?.toString() ?? '');
    if (!mounted) return;
    if (planningId != null) {
      context.push('/planning/$planningId');
    } else if (orderId != null) {
      context.push('/orders/$orderId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationsTitle),
        actions: [
          IconButton(
            tooltip: l10n.notificationsMarkAllRead,
            onPressed: state.items.isEmpty
                ? null
                : () async {
                    await ref
                        .read(notificationsProvider.notifier)
                        .markAllRead();
                    ref.invalidate(unreadCountProvider);
                  },
            icon: const Icon(Icons.done_all_rounded),
          ),
          IconButton(
            tooltip: l10n.notificationsOpenSettings,
            onPressed: () => context.push('/notifications/settings'),
            icon: const Icon(Icons.tune_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: NotificationListener<ScrollNotification>(
            onNotification: (scroll) {
              if (scroll.metrics.pixels >=
                  scroll.metrics.maxScrollExtent - 200) {
                ref.read(notificationsProvider.notifier).loadMore();
              }
              return false;
            },
            child: _buildBody(state, theme),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(NotificationsState state, ThemeData theme) {
    final l10n = context.l10n;
    // Until the initial load has finished, show a loading indicator instead of
    // an "empty" state so the alert list isn't mistaken for having no data
    // before the first refresh completes.
    final isLoading = state.items.isEmpty && (state.refreshing || !_loaded);
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.items.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          EmptyState(
            icon: Icons.notifications_none_rounded,
            title: l10n.notificationsEmptyTitle,
            subtitle: l10n.notificationsEmptySubtitle,
          ),
        ],
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView.separated(
          padding: EdgeInsets.fromLTRB(
            context.isExpanded ? 28 : 20,
            12,
            context.isExpanded ? 28 : 20,
            32,
          ),
          itemCount: state.items.length + (state.loadingMore ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            if (index >= state.items.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            final n = state.items[index];
            return Card(
              color: n.isRead ? null : theme.colorScheme.primaryContainer,
              child: ListTile(
                isThreeLine: n.body != null && n.body!.isNotEmpty,
                leading:
                    Icon(_iconFor(n.type), color: theme.colorScheme.primary),
                title: Text(
                  n.title ?? l10n.dashboardNotificationFallback,
                  style: TextStyle(
                    fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700,
                  ),
                ),
                subtitle: Text(n.body ?? '', maxLines: 3),
                trailing: n.createdAt == null
                    ? null
                    : Text(
                        F.relativeDay(l10n, n.createdAt),
                        style: theme.textTheme.bodySmall,
                      ),
                onTap: () => _open(n),
              ),
            );
          },
        ),
      ),
    );
  }

  IconData _iconFor(String? type) => switch (type) {
    'LESSON_BOOKED' => Icons.event_available_outlined,
    'LESSON_CANCELLED' => Icons.event_busy_outlined,
    'LESSON_CHANGED' => Icons.event_repeat_outlined,
    'LESSON_COMPLETED' => Icons.task_alt,
    'LESSON_REMINDER_24H' || 'LESSON_REMINDER_1H' => Icons.alarm_outlined,
    'PAYMENT_SUCCESSFUL' => Icons.check_circle_outline,
    'PAYMENT_FAILED' => Icons.error_outline,
    'PAYMENT_REFUNDED' => Icons.replay_rounded,
    'PAYMENT_REQUESTED' => Icons.request_quote_outlined,
    'LOW_LESSON_CREDIT' => Icons.warning_amber_outlined,
    'EXAM_BOOKED' ||
    'EXAM_REMINDER_7D' ||
    'EXAM_REMINDER_24H' => Icons.grading_outlined,
    'EXAM_CANCELLED' => Icons.block_rounded,
    'LESSON_CARD_UPDATED' => Icons.fact_check_outlined,
    'INSTRUCTOR_FEEDBACK' => Icons.forum_outlined,
    'ACCOUNT_SECURITY' => Icons.shield_outlined,
    _ => Icons.notifications_outlined,
  };
}
