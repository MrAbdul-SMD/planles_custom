import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/deep_links.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/responsive.dart';
import '../../../core/utils/formatters.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets.dart';
import '../../auth/models/user.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/providers/notifications_providers.dart';
import '../../orders/models/order.dart';
import '../../orders/providers/orders_providers.dart';
import '../../planning/models/planning.dart';
import '../../students/providers/directory_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    await Future.wait([
      ref.refresh(ordersListProvider.future),
      ref.refresh(unreadCountProvider.future),
      ref.refresh(vehiclesProvider.future),
      ref.read(authControllerProvider.notifier).refreshUser(),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final unread = ref.watch(unreadCountProvider).value ?? 0;
    final notifications = ref
        .watch(notificationsProvider)
        .items
        .take(2)
        .toList();

    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_greeting(l10n, user)),
        actions: [
          IconButton(
            tooltip: l10n.navNotifications,
            onPressed: () => context.go('/notifications'),
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= Breakpoints.medium;
              final isDesktop = constraints.maxWidth >= Breakpoints.expanded;
              final horizontal = isDesktop ? 32.0 : (wide ? 24.0 : 20.0);

              final notificationsSection = notifications.isEmpty
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SectionHeader(
                          l10n.dashboardRecentNotifications,
                          trailing: TextButton(
                            onPressed: () => context.go('/notifications'),
                            child: Text(l10n.dashboardAllNotifications),
                          ),
                        ),
                        for (final n in notifications)
                          Card(
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  n.isRead
                                      ? Icons.notifications_none_rounded
                                      : Icons.notifications_active_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                n.title ?? l10n.dashboardNotificationFallback,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                n.body ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: n.createdAt == null
                                  ? null
                                  : Text(
                                      F.relativeDay(l10n, n.createdAt),
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.outline,
                                      ),
                                    ),
                            ),
                          ),
                      ],
                    );

              Widget body;
              if (wide) {
                body = Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _BalanceTelemetryCard(user: user),
                          const SizedBox(height: 24),
                          if (notifications.isNotEmpty) ...[
                            notificationsSection,
                          ] else ...[
                            _DesktopHintCard(
                              icon: Icons.dashboard_customize_outlined,
                              title: l10n.navHome,
                              subtitle:
                                  'Beheer je lessen, bestellingen en meldingen overzichtelijk op één plek.',
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 7,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SectionHeader(l10n.buyLessonsTitle),
                          const SizedBox(height: 8),
                          const _EmbeddedOrderCreation(),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                body = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _BalanceTelemetryCard(user: user),
                    const SizedBox(height: 24),
                    SectionHeader(l10n.buyLessonsTitle),
                    const SizedBox(height: 8),
                    const _EmbeddedOrderCreation(),
                    if (notifications.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      notificationsSection,
                    ],
                  ],
                );
              }

              return ListView(
                padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 40),
                children: [
                  ResponsiveCenter(
                    maxWidth: 1280,
                    child: body,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _greeting(AppLocalizations l10n, User? user) {
    final hour = DateTime.now().hour;
    final base = hour < 12
        ? l10n.dashboardGreetingMorning
        : hour < 18
        ? l10n.dashboardGreetingAfternoon
        : l10n.dashboardGreetingEvening;
    final name = user?.firstName;
    return (name == null || name.isEmpty) ? base : '$base, $name';
  }
}

/// Matte titanium membership card with telemetry styling.
class _BalanceTelemetryCard extends ConsumerWidget {
  const _BalanceTelemetryCard({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFF0F4C81), const Color(0xFF02679E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF0F4C81)).withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars_rounded, size: 14, color: Color(0xFFFDBA74)),
                    const SizedBox(width: 5),
                    Text(
                      user?.isInstructor == true ? 'INSTRUCTEUR' : 'LEERLINGPAS',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              AppAvatar(initials: user?.initials ?? '?', size: 36),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            l10n.dashboardBalanceLabel.toUpperCase(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                F.money(user?.balance ?? 0),
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () => context.push('/balance/topup'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0F4C81),
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_rounded, size: 18),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          l10n.dashboardTopUpBalance,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  tooltip: l10n.dashboardBuyLessons,
                  icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                  onPressed: () => context.push('/orders/new'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class _DashCartItem {
  _DashCartItem({required this.drivingClass, required this.quantity});

  final DrivingClass drivingClass;
  int quantity;
}

/// Embedded order creation for dashboard (replaces upcoming lessons + quick actions).
class _EmbeddedOrderCreation extends ConsumerStatefulWidget {
  const _EmbeddedOrderCreation();

  @override
  ConsumerState<_EmbeddedOrderCreation> createState() => _EmbeddedOrderCreationState();
}

class _EmbeddedOrderCreationState extends ConsumerState<_EmbeddedOrderCreation> {
  int? _vehicleId;
  int? _classId;
  int _quantity = 1;
  String _paymentType = 'digital';
  int? _studentId;
  bool _busy = false;
  final List<_DashCartItem> _cart = [];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final vehicles = ref.watch(vehiclesProvider);
    final user = ref.watch(currentUserProvider);
    final isInstructor = user?.isInstructor == true;

    AsyncValue<List<DrivingClass>>? classes;
    if (_vehicleId != null) classes = ref.watch(classesProvider(_vehicleId!));
    final classList = classes?.value ?? const <DrivingClass>[];
    DrivingClass? selectedClass;
    for (final c in classList) {
      if (c.id == _classId) selectedClass = c;
    }

    final canSubmit = !_busy && _cart.isNotEmpty && (!isInstructor || _studentId != null);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.buyLessonsStepVehicle,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            vehicles.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => ErrorView(
                message: describeError(context, e),
                onRetry: () => ref.invalidate(vehiclesProvider),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return Text(l10n.buyLessonsNoPackages);
                }
                const palette = [
                  Color(0xFF2563EB),
                  Color(0xFF059669),
                  Color(0xFFEA580C),
                  Color(0xFF7C3AED),
                  Color(0xFFDB2777),
                  Color(0xFF0891B2),
                  Color(0xFFCA8A04),
                  Color(0xFF4F46E5),
                ];
                return LayoutBuilder(
                  builder: (context, box) {
                    final cols = box.maxWidth >= 700
                        ? 5
                        : box.maxWidth >= 420
                            ? 4
                            : 3;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: list.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.95,
                      ),
                      itemBuilder: (context, i) {
                        final v = list[i];
                        return _VehicleTypeCard(
                          vehicle: v,
                          selected: _vehicleId == v.id,
                          color: palette[i % palette.length],
                          onTap: () {
                            setState(() {
                              _vehicleId = v.id;
                              _classId = null;
                              _quantity = 1;
                            });
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 18),
            Text(
              l10n.buyLessonsStepLesson,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            if (_vehicleId == null)
              Text(
                l10n.buyLessonsChooseVehicleFirst,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else if (classes == null)
              const SizedBox.shrink()
            else
              classes.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => ErrorView(
                  message: describeError(context, e),
                  onRetry: () => ref.invalidate(classesProvider(_vehicleId!)),
                ),
                data: (list) {
                  if (list.isEmpty) return Text(l10n.buyLessonsNoPackages);
                  final sorted = [...list]
                    ..sort((a, b) => _lessonOrder(a.lessonType).compareTo(_lessonOrder(b.lessonType)));
                  String? group;
                  final children = <Widget>[];
                  for (final c in sorted) {
                    final g = c.lessonType ?? '';
                    if (g != group) {
                      group = g;
                      final label = _lessonTypeLabel(l10n, g);
                      if (label != null) {
                        children.add(Padding(
                          padding: const EdgeInsets.only(top: 6, bottom: 4),
                          child: Text(
                            label,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ));
                      }
                    }
                    children.add(
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() {
                          _classId = c.id;
                          _quantity = 1;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: _classId == c.id
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _classId == c.id
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _classId == c.id ? Icons.radio_button_checked : Icons.radio_button_off,
                                size: 20,
                                color: _classId == c.id ? theme.colorScheme.primary : theme.colorScheme.outline,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.name ?? l10n.orderDetailLesson,
                                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    if (c.duration != null)
                                      Text(
                                        F.durationLabel(l10n, c.duration),
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                F.money(c.priceValue),
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
                },
              ),

            if (selectedClass != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.buyLessonsStepQuantity,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    visualDensity: VisualDensity.compact,
                  ),
                  Text('$_quantity', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  IconButton(
                    onPressed: () => setState(() => _quantity++),
                    icon: const Icon(Icons.add_circle_outline),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => _addToCart(selectedClass!),
                  icon: const Icon(Icons.add_shopping_cart_outlined),
                  label: Text(l10n.buyLessonsAddItem),
                ),
              ),
            ],

            if (_cart.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                l10n.orderDetailSectionLessons,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    for (final (i, item) in _cart.indexed) ...[
                      if (i > 0) const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.drivingClass.name ?? l10n.orderDetailLesson,
                                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    '${l10n.orderDetailLessonCount(item.quantity)} · ${F.money(_itemTotal(item.drivingClass, item.quantity))}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: item.quantity > 1 ? () => setState(() => item.quantity--) : null,
                              icon: const Icon(Icons.remove_circle_outline, size: 20),
                            ),
                            Text('${item.quantity}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () => setState(() => item.quantity++),
                              icon: const Icon(Icons.add_circle_outline, size: 20),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () => setState(() => _cart.removeAt(i)),
                              icon: const Icon(Icons.delete_outline, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Totaal',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          Text(
                            F.money(_cartTotal()),
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (isInstructor) ...[
              const SizedBox(height: 16),
              Text(
                l10n.buyLessonsStepStudent,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              _DashboardStudentPicker(
                selectedId: _studentId,
                onChanged: (id) => setState(() => _studentId = id),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.buyLessonsStepPaymentInstructor,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'digital',
                    label: Text(l10n.buyLessonsPaymentOnline),
                    icon: const Icon(Icons.credit_card_outlined),
                  ),
                  ButtonSegment(
                    value: 'balance',
                    label: Text(l10n.buyLessonsPaymentBalance),
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                  ),
                  ButtonSegment(
                    value: 'cash',
                    label: Text(l10n.buyLessonsPaymentCash),
                    icon: const Icon(Icons.payments_outlined),
                  ),
                ],
                selected: {_paymentType},
                onSelectionChanged: (v) => setState(() => _paymentType = v.first),
              ),
              const SizedBox(height: 8),
              Text(
                switch (_paymentType) {
                  'balance' => l10n.buyLessonsBalanceNote(F.money(user?.balance ?? 0)),
                  'cash' => l10n.buyLessonsCashNote,
                  _ => l10n.buyLessonsMollieNote,
                },
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ] else ...[
              const SizedBox(height: 16),
              Text(
                l10n.buyLessonsStepPaymentStudent,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'digital',
                    label: Text(l10n.buyLessonsPaymentOnline),
                    icon: const Icon(Icons.credit_card_outlined),
                  ),
                  ButtonSegment(
                    value: 'balance',
                    label: Text(l10n.buyLessonsPaymentBalance),
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                  ),
                  ButtonSegment(
                    value: 'cash',
                    label: Text(l10n.buyLessonsPaymentCash),
                    icon: const Icon(Icons.payments_outlined),
                  ),
                ],
                selected: {_paymentType},
                onSelectionChanged: (v) => setState(() => _paymentType = v.first),
              ),
              const SizedBox(height: 8),
              Text(
                switch (_paymentType) {
                  'balance' => l10n.buyLessonsBalanceNote(F.money(user?.balance ?? 0)),
                  'cash' => l10n.buyLessonsCashNote,
                  _ => l10n.buyLessonsMollieNote,
                },
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],

            const SizedBox(height: 16),
            FilledButton(
              onPressed: canSubmit ? _submit : null,
              child: _busy
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4))
                  : Text(
                      _cart.isEmpty
                          ? l10n.buyLessonsChoosePackage
                          : (isInstructor
                              ? '${l10n.confirm} — ${F.money(_cartTotal())}'
                              : l10n.buyLessonsPayButton(F.money(_cartTotal()))),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  int _lessonOrder(String? type) => switch (type) {
        'trial' => 0,
        'base' => 1,
        'pack' => 2,
        'exam' => 3,
        _ => 99,
      };

  String? _lessonTypeLabel(AppLocalizations l10n, String type) => switch (type) {
        'trial' => l10n.buyLessonsLessonTypeTrial,
        'base' => l10n.buyLessonsLessonTypeBase,
        'pack' => l10n.buyLessonsLessonTypePack,
        'exam' => l10n.buyLessonsLessonTypeExam,
        _ => null,
      };

  double _itemTotal(DrivingClass c, int quantity) => (c.priceValue ?? 0) * quantity;

  double _cartTotal() => _cart.fold<double>(0, (sum, item) => sum + _itemTotal(item.drivingClass, item.quantity));

  void _addToCart(DrivingClass selectedClass) {
    setState(() {
      final existing = _cart.indexWhere((item) => item.drivingClass.id == selectedClass.id);
      if (existing >= 0) {
        _cart[existing].quantity += _quantity;
      } else {
        _cart.add(_DashCartItem(drivingClass: selectedClass, quantity: _quantity));
      }
      _quantity = 1;
    });
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (_cart.isEmpty) return;
    final user = ref.read(currentUserProvider);
    final isInstructor = user?.isInstructor == true;
    setState(() => _busy = true);
    try {
      final result = await ref.read(ordersRepositoryProvider).create(
            paymentType: _paymentType,
            items: [
              for (final item in _cart)
                (id: item.drivingClass.id, quantity: item.quantity),
            ],
            studentId: _studentId,
            redirectUrl: isInstructor ? null : paymentRedirectUrl(),
          );

      ref.invalidate(ordersListProvider);
      ref.read(authControllerProvider.notifier).refreshUser();

      final checkoutUrl = result.checkoutUrl;
      if (!isInstructor && checkoutUrl != null && checkoutUrl.isNotEmpty) {
        final uri = Uri.tryParse(checkoutUrl);
        if (uri != null) {
          await launchUrl(
            uri,
            mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
            webOnlyWindowName: kIsWeb ? '_self' : null,
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _cart.clear();
        _classId = null;
        _quantity = 1;
      });
      final orderId = result.orderId;
      if (orderId != null) {
        context.push('/orders/$orderId');
      } else {
        context.go('/orders');
      }
      showAppSnack(context, l10n.buyLessonsOrderPlaced);
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, describeError(context, e), error: true);
    } catch (e) {
      if (mounted) showAppSnack(context, describeError(context, e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _VehicleTypeCard extends StatelessWidget {
  const _VehicleTypeCard({
    required this.vehicle,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  final Vehicle vehicle;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  IconData _iconFor(Vehicle v) {
    final text = '${v.code ?? ''} ${v.name ?? ''}'.toLowerCase();
    if (text.contains('motor')) return Icons.two_wheeler_rounded;
    if (text.contains('brom') || text.contains('scooter') || text.contains('moped')) return Icons.moped_rounded;
    if (text.contains('vracht') || text.contains('truck')) return Icons.local_shipping_rounded;
    if (text.contains('bus')) return Icons.directions_bus_rounded;
    if (text.contains('aanhang') || text.contains('trailer') || text.contains('be')) return Icons.rv_hookup_rounded;
    return Icons.directions_car_filled_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg = selected ? color.withValues(alpha: 0.16) : scheme.surfaceContainerLow;
    final border = selected ? color : color.withValues(alpha: 0.35);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: border,
            width: selected ? 1.8 : 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 18,
                color: selected ? color : scheme.outline.withValues(alpha: 0.6),
              ),
            ),
            Expanded(
              child: Center(
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: selected ? 0.22 : 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _iconFor(vehicle),
                    size: 26,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              vehicleTypeLabel(context.l10n, vehicle),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardStudentPicker extends ConsumerWidget {
  const _DashboardStudentPicker({required this.selectedId, required this.onChanged});

  final int? selectedId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final students = ref.watch(myStudentsProvider);
    return students.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => ErrorView(
        message: describeError(context, e),
        onRetry: () => ref.invalidate(myStudentsProvider),
      ),
      data: (list) {
        if (list.isEmpty) {
          return Card(child: Padding(padding: const EdgeInsets.all(12), child: Text(l10n.buyLessonsNoStudents)));
        }
        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true,
                value: selectedId,
                hint: Text(l10n.buyLessonsChooseStudent),
                items: [
                  for (final User s in list)
                    DropdownMenuItem(value: s.id, child: Text(s.displayName(l10n))),
                ],
                onChanged: onChanged,
              ),
            ),
          ),
        );
      },
    );
  }
}
class _DesktopHintCard extends StatelessWidget {
  const _DesktopHintCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: scheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ticket-style planning card for lesson lists and timeline.
class PlanningTile extends StatelessWidget {
  const PlanningTile({super.key, required this.planning, this.trailing});

  final Planning planning;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final start = planning.startDate;
    final end = planning.endDate;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        mouseCursor: SystemMouseCursors.click,
        onTap: () => context.push('/planning/${planning.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Ticket Date Pill
              Container(
                width: 58,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.4),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      start == null ? '–' : F.dayLabel(l10n, start),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      start == null ? '' : F.time(start),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            planning.drivingClass?.name ?? l10n.dashboardLessonFallback,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.planningNumber(planning.id),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (end != null && start != null)
                          '${F.time(start)} – ${F.time(end)}',
                        if (planning.instructor != null)
                          planning.instructor!.displayName(l10n),
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: trailing ??
                    StatusChip(
                      label: planning.statusLabel(l10n),
                      tone: PlanningTone.forStatus(planning.status),
                    ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.outline,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
