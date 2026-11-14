import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/deep_links.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets.dart';
import '../../auth/models/user.dart';
import '../../auth/providers/auth_provider.dart';
import '../../students/providers/directory_providers.dart';
import '../models/order.dart';
import '../providers/orders_providers.dart';

class _CartItem {
  _CartItem({required this.drivingClass, required this.quantity});

  final DrivingClass drivingClass;
  int quantity;
}

/// Buy driving classes: pick vehicle → class, add to cart, choose payment.
class BuyLessonsScreen extends ConsumerStatefulWidget {
  const BuyLessonsScreen({super.key});

  @override
  ConsumerState<BuyLessonsScreen> createState() => _BuyLessonsScreenState();
}

class _BuyLessonsScreenState extends ConsumerState<BuyLessonsScreen> {
  int? _vehicleId;
  int? _classId;
  int _quantity = 1;
  String _paymentType = 'digital';
  int? _studentId;
  bool _busy = false;
  final List<_CartItem> _cart = [];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final isInstructor = user?.isInstructor == true;
    final vehicles = ref.watch(vehiclesProvider);

    AsyncValue<List<DrivingClass>>? classes;
    if (_vehicleId != null) classes = ref.watch(classesProvider(_vehicleId!));
    final classList = classes?.value ?? const <DrivingClass>[];
    DrivingClass? selectedClass;
    for (final c in classList) {
      if (c.id == _classId) selectedClass = c;
    }

    final canSubmit = !_busy && _cart.isNotEmpty && (!isInstructor || _studentId != null);

    Widget sectionTitle(String text, {String? subtitle, IconData? icon}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final vehicleSection = _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          sectionTitle(l10n.buyLessonsStepVehicle, icon: Icons.directions_car_filled_outlined),
          vehicles.when(
            loading: () => const _InlineLoading(),
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
              ];
              return LayoutBuilder(
                builder: (context, box) {
                  final cols = box.maxWidth >= 560 ? 4 : (box.maxWidth >= 360 ? 3 : 2);
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: list.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.0,
                    ),
                    itemBuilder: (context, i) {
                      final v = list[i];
                      return _VehicleTypeCard(
                        vehicle: v,
                        selected: _vehicleId == v.id,
                        color: palette[i % palette.length],
                        onTap: () => setState(() {
                          _vehicleId = v.id;
                          _classId = null;
                          _quantity = 1;
                        }),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );

    final lessonSection = _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          sectionTitle(l10n.buyLessonsStepLesson, icon: Icons.inventory_2_outlined),
          if (_vehicleId == null)
            _HintBox(text: l10n.buyLessonsChooseVehicleFirst)
          else if (classes == null)
            const SizedBox.shrink()
          else
            classes.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => ErrorView(
                message: describeError(context, e),
                onRetry: () => ref.invalidate(classesProvider(_vehicleId!)),
              ),
              data: (list) {
                if (list.isEmpty) return Text(l10n.buyLessonsNoPackages);
                const order = <String, int>{'trial': 0, 'base': 1, 'pack': 2, 'exam': 3};
                final sorted = [...list]
                  ..sort((a, b) => (order[a.lessonType] ?? 99).compareTo(order[b.lessonType] ?? 99));
                String? currentGroup;
                final children = <Widget>[];
                for (final c in sorted) {
                  final group = c.lessonType ?? '';
                  if (group != currentGroup) {
                    currentGroup = group;
                    final label = switch (group) {
                      'trial' => l10n.buyLessonsLessonTypeTrial,
                      'base' => l10n.buyLessonsLessonTypeBase,
                      'pack' => l10n.buyLessonsLessonTypePack,
                      'exam' => l10n.buyLessonsLessonTypeExam,
                      _ => null,
                    };
                    if (label != null) {
                      children.add(Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 6),
                        child: Text(
                          label,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ));
                    }
                  }
                  children.add(_ClassOption(
                    drivingClass: c,
                    selected: _classId == c.id,
                    onTap: () => setState(() {
                      _classId = c.id;
                      _quantity = 1;
                    }),
                  ));
                  children.add(const SizedBox(height: 8));
                }
                return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
              },
            ),
          if (selectedClass != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    selectedClass.name ?? l10n.orderDetailLesson,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.buyLessonsTotalLine(
                      F.minutesLabel(l10n, (selectedClass.durationMinutes ?? 0) * _quantity),
                      F.money(_itemTotal(selectedClass, _quantity)),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _QtyButton(icon: Icons.remove, onTap: _quantity > 1 ? () => setState(() => _quantity--) : null),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text('$_quantity', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      ),
                      _QtyButton(icon: Icons.add, onTap: () => setState(() => _quantity++)),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () => _addToCart(selectedClass!),
                        icon: const Icon(Icons.add_shopping_cart_outlined, size: 18),
                        label: Text(l10n.buyLessonsAddItem),
                        style: FilledButton.styleFrom(minimumSize: const Size(0, 42)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    final cartSection = _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          sectionTitle(l10n.orderDetailSectionLessons, icon: Icons.shopping_cart_outlined),
          if (_cart.isEmpty)
            _HintBox(text: l10n.buyLessonsChoosePackage)
          else ...[
            for (final (i, item) in _cart.indexed) ...[
              if (i > 0) const Divider(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.drivingClass.name ?? l10n.orderDetailLesson,
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            l10n.orderDetailLessonCount(item.quantity),
                            if (item.drivingClass.duration != null) F.durationLabel(l10n, item.drivingClass.duration),
                            F.money(_itemTotal(item.drivingClass, item.quantity)),
                          ].whereType<String>().join(' · '),
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                        tooltip: l10n.delete,
                      ),
                    ],
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.buyLessonsTotalLine(F.minutesLabel(l10n, _cartTotalMinutes()), ''),
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    F.money(_cartTotal()),
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.primary),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    final paymentSection = _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isInstructor) ...[
            sectionTitle(l10n.buyLessonsStepStudent, icon: Icons.person_outline),
            _StudentPicker(selectedId: _studentId, onChanged: (id) => setState(() => _studentId = id)),
            const SizedBox(height: 16),
            sectionTitle(l10n.buyLessonsStepPaymentInstructor, icon: Icons.payments_outlined),
          ] else
            sectionTitle(l10n.buyLessonsStepPaymentStudent, icon: Icons.payments_outlined),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: 'digital', label: Text(l10n.buyLessonsPaymentOnline), icon: const Icon(Icons.credit_card_outlined)),
              ButtonSegment(value: 'balance', label: Text(l10n.buyLessonsPaymentBalance), icon: const Icon(Icons.account_balance_wallet_outlined)),
              ButtonSegment(value: 'cash', label: Text(l10n.buyLessonsPaymentCash), icon: const Icon(Icons.payments_outlined)),
            ],
            selected: {_paymentType},
            onSelectionChanged: (v) => setState(() => _paymentType = v.first),
          ),
          const SizedBox(height: 10),
          Text(
            switch (_paymentType) {
              'balance' => l10n.buyLessonsBalanceNote(F.money(user?.balance ?? 0)),
              'cash' => l10n.buyLessonsCashNote,
              _ => l10n.buyLessonsMollieNote,
            },
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.buyLessonsAfterPurchase,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );

    Widget submitArea({bool compact = false}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton(
            onPressed: canSubmit ? _submit : null,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
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
          if (!compact && _cart.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${l10n.orderDetailSectionLessons}: ${_cart.fold<int>(0, (s, i) => s + i.quantity)} · ${F.money(_cartTotal())}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.buyLessonsTitle),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/orders'),
          tooltip: l10n.cancel,
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1000;
          if (wide) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1320),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 7,
                        child: ListView(
                          children: [
                            vehicleSection,
                            const SizedBox(height: 16),
                            lessonSection,
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      SizedBox(
                        width: 420,
                        child: Column(
                          children: [
                            Expanded(
                              child: ListView(
                                children: [
                                  cartSection,
                                  const SizedBox(height: 16),
                                  paymentSection,
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            SafeArea(top: false, child: submitArea()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      vehicleSection,
                      const SizedBox(height: 14),
                      lessonSection,
                      const SizedBox(height: 14),
                      cartSection,
                      const SizedBox(height: 14),
                      paymentSection,
                      const SizedBox(height: 16),
                      SafeArea(top: false, child: submitArea(compact: true)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  double _itemTotal(DrivingClass c, int quantity) =>
      (c.priceValue ?? 0) * quantity;

  double _cartTotal() => _cart.fold<double>(
        0,
        (sum, item) => sum + _itemTotal(item.drivingClass, item.quantity),
      );

  int _cartTotalMinutes() => _cart.fold<int>(
        0,
        (sum, item) =>
            sum + (item.drivingClass.durationMinutes ?? 0) * item.quantity,
      );

  void _addToCart(DrivingClass selectedClass) {
    setState(() {
      final existing = _cart.indexWhere(
        (item) => item.drivingClass.id == selectedClass.id,
      );
      if (existing >= 0) {
        _cart[existing].quantity += _quantity;
      } else {
        _cart.add(_CartItem(drivingClass: selectedClass, quantity: _quantity));
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

      final orderId = result.orderId;
      final checkoutUrl = result.checkoutUrl;

      if (!isInstructor && checkoutUrl != null && checkoutUrl.isNotEmpty) {
        final uri = Uri.tryParse(checkoutUrl);
        if (uri != null) {
          await launchUrl(
            uri,
            mode: kIsWeb
                ? LaunchMode.platformDefault
                : LaunchMode.externalApplication,
            webOnlyWindowName: kIsWeb ? '_self' : null,
          );
        }
      }

      if (!mounted) return;
      if (orderId != null) {
        context.go('/orders/$orderId');
      } else {
        context.go('/orders');
      }
      showAppSnack(context, l10n.buyLessonsOrderPlaced);
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
}

class _ClassOption extends StatelessWidget {
  const _ClassOption({
    required this.drivingClass,
    required this.selected,
    required this.onTap,
  });

  final DrivingClass drivingClass;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      mouseCursor: SystemMouseCursors.click,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : Colors.transparent,
            width: 1.6,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    drivingClass.name ?? l10n.orderDetailLesson,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (drivingClass.duration != null)
                        F.durationLabel(l10n, drivingClass.duration),
                      switch (drivingClass.lessonType) {
                        'trial' => l10n.buyLessonsLessonTypeTrial,
                        'base' => l10n.buyLessonsLessonTypeBase,
                        'pack' => l10n.buyLessonsLessonTypePack,
                        'exam' => l10n.buyLessonsLessonTypeExam,
                        _ => null,
                      },
                    ].where((e) => e != null).join(' · '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              F.money(drivingClass.priceValue),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentPicker extends ConsumerWidget {
  const _StudentPicker({required this.selectedId, required this.onChanged});

  final int? selectedId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final students = ref.watch(myStudentsProvider);

    return students.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => ErrorView(
        message: describeError(context, e),
        onRetry: () => ref.invalidate(myStudentsProvider),
      ),
      data: (list) {
        if (list.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.buyLessonsNoStudents),
            ),
          );
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
                    DropdownMenuItem(
                      value: s.id,
                      child: Text(s.displayName(l10n)),
                    ),
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
    if (text.contains('brom') || text.contains('scooter') || text.contains('moped')) {
      return Icons.moped_rounded;
    }
    if (text.contains('vracht') || text.contains('truck')) {
      return Icons.local_shipping_rounded;
    }
    if (text.contains('bus')) return Icons.directions_bus_rounded;
    if (text.contains('aanhang') || text.contains('trailer') || text.contains('be')) {
      return Icons.rv_hookup_rounded;
    }
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

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: child,
    );
  }
}

class _HintBox extends StatelessWidget {
  const _HintBox({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _InlineLoading extends StatelessWidget {
  const _InlineLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Ink(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon),
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
  }
}
