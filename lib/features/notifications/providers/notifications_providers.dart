import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/notifications_repository.dart';
import '../models/app_notification.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(ref.watch(apiClientProvider)),
);

/// Cursor paginated notification inbox.
class NotificationsState {
  const NotificationsState({
    this.items = const [],
    this.nextCursor,
    this.loadingMore = false,
    this.refreshing = false,
  });

  final List<AppNotification> items;
  final int? nextCursor;
  final bool loadingMore;
  final bool refreshing;

  bool get hasMore => nextCursor != null;

  NotificationsState copyWith({
    List<AppNotification>? items,
    int? Function()? nextCursor,
    bool? loadingMore,
    bool? refreshing,
  }) =>
      NotificationsState(
        items: items ?? this.items,
        nextCursor: nextCursor != null ? nextCursor() : this.nextCursor,
        loadingMore: loadingMore ?? this.loadingMore,
        refreshing: refreshing ?? this.refreshing,
      );
}

class NotificationsController extends Notifier<NotificationsState> {
  @override
  NotificationsState build() => const NotificationsState();

  NotificationsRepository get _repo => ref.read(notificationsRepositoryProvider);

  Future<void> refresh() async {
    if (state.refreshing) return;
    _set(state.copyWith(refreshing: true));
    try {
      final page = await _repo.list();
      _set(NotificationsState(
        items: page.items,
        nextCursor: page.nextCursor,
      ));
    } catch (_) {
      _set(state.copyWith(refreshing: false));
      rethrow;
    }
  }

  Future<void> loadMore() async {
    final cursor = state.nextCursor;
    if (cursor == null || state.loadingMore) return;
    _set(state.copyWith(loadingMore: true));
    try {
      final page = await _repo.list(cursor: cursor);
      _set(NotificationsState(
        items: [...state.items, ...page.items],
        nextCursor: page.nextCursor,
      ));
    } catch (_) {
      _set(state.copyWith(loadingMore: false));
      rethrow;
    }
  }

  Future<void> markRead(int id) async {
    await _repo.markRead(id);
    _set(state.copyWith(
      items: [
        for (final n in state.items)
          n.id == id
              ? AppNotification(
                  id: n.id,
                  userId: n.userId,
                  type: n.type,
                  title: n.title,
                  body: n.body,
                  data: n.data,
                  readAt: DateTime.now(),
                  createdAt: n.createdAt,
                  dedupeKey: n.dedupeKey,
                )
              : n,
      ],
      nextCursor: () => state.nextCursor,
    ));
  }

  Future<void> markAllRead() async {
    await _repo.markAllRead();
    final now = DateTime.now();
    _set(state.copyWith(
      items: [
        for (final n in state.items)
          AppNotification(
            id: n.id,
            userId: n.userId,
            type: n.type,
            title: n.title,
            body: n.body,
            data: n.data,
            readAt: n.readAt ?? now,
            createdAt: n.createdAt,
            dedupeKey: n.dedupeKey,
          ),
      ],
      nextCursor: () => state.nextCursor,
    ));
    ref.invalidate(unreadCountProvider);
  }

  void _set(NotificationsState next) {
    if (ref.mounted) state = next;
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsController, NotificationsState>(
  NotificationsController.new,
);

final unreadCountProvider = FutureProvider<int>((ref) {
  return ref.watch(notificationsRepositoryProvider).unreadCount();
});

final notificationSettingsProvider =
    FutureProvider<NotificationSettings>((ref) {
  return ref.watch(notificationsRepositoryProvider).settings();
});
