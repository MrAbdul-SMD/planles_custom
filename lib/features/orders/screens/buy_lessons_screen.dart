import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets.dart';
import '../../auth/models/user.dart';
import '../../auth/providers/auth_provider.dart';
import '../../students/providers/directory_providers.dart';
import '../models/order.dart';
import '../providers/orders_providers.dart';

/// Buy a driving class: pick vehicle → class → quantity → payment method.
/// Instructors additionally pick for which student.
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final vehicles = ref.watch(vehiclesProvider);
    final user = ref.watch(currentUserProvider);
    final isInstructor = user?.isInstructor == true;
    final theme = Theme.of(context);

    AsyncValue<List<DrivingClass>>? classes;
    if (_vehicleId != null) classes = ref.watch(classesProvider(_vehicleId!));
    final classList = classes?.value ?? const <DrivingClass>[];

    DrivingClass? selectedClass;
    for (final c in classList) {
      if (c.id == _classId) selectedClass = c;
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.buyLessonsTitle)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            onPressed:
                (_busy ||
                    selectedClass == null ||
                    (isInstructor && _studentId == null))
                ? null
                : _submit,
            child: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : Text(
                    selectedClass == null
                        ? l10n.buyLessonsChoosePackage
                        : l10n.buyLessonsPayButton(
                            F.money(_total(selectedClass)),
                          ),
                  ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SectionHeader(l10n.buyLessonsStepVehicle),
              vehicles.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => ErrorView(
                  message: describeError(context, e),
                  onRetry: () => ref.invalidate(vehiclesProvider),
                ),
                data: (list) => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final v in list)
                      ChoiceChip(
                        label: Text(
                          v.name ?? l10n.buyLessonsVehicleFallback(v.id),
                        ),
                        selected: _vehicleId == v.id,
                        onSelected: (_) {
                          setState(() {
                            _vehicleId = v.id;
                            _classId = null;
                            _quantity = 1;
                          });
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SectionHeader(l10n.buyLessonsStepLesson),
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
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => ErrorView(
                    message: describeError(context, e),
                    onRetry: () => ref.invalidate(classesProvider(_vehicleId!)),
                  ),
                  data: (list) {
                    if (list.isEmpty) {
                      return Text(l10n.buyLessonsNoPackages);
                    }
                    return Column(
                      children: [
                        for (final c in list) ...[
                          _ClassOption(
                            drivingClass: c,
                            selected: _classId == c.id,
                            onTap: () => setState(() {
                              _classId = c.id;
                              _quantity = 1;
                            }),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    );
                  },
                ),

              if (selectedClass != null) ...[
                const SizedBox(height: 16),
                SectionHeader(l10n.buyLessonsStepQuantity),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedClass.name ?? l10n.orderDetailLesson,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          '$_quantity',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _quantity++),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.buyLessonsTotalLine(
                    F.minutesLabel(
                      l10n,
                      (selectedClass.durationMinutes ?? 0) * _quantity,
                    ),
                    F.money(_total(selectedClass)),
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],

              if (isInstructor) ...[
                const SizedBox(height: 24),
                SectionHeader(l10n.buyLessonsStepStudent),
                _StudentPicker(
                  selectedId: _studentId,
                  onChanged: (id) => setState(() => _studentId = id),
                ),
              ],

              const SizedBox(height: 24),
              SectionHeader(
                isInstructor
                    ? l10n.buyLessonsStepPaymentInstructor
                    : l10n.buyLessonsStepPaymentStudent,
              ),
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
                ],
                selected: {_paymentType},
                onSelectionChanged: (v) =>
                    setState(() => _paymentType = v.first),
              ),
              const SizedBox(height: 12),
              Text(
                _paymentType == 'balance'
                    ? l10n.buyLessonsBalanceNote(F.money(user?.balance ?? 0))
                    : l10n.buyLessonsMollieNote,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.buyLessonsAfterPurchase,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _total(DrivingClass c) => (c.priceValue ?? 0) * _quantity;

  Future<void> _submit() async {
    final l10n = context.l10n;
    final classId = _classId;
    if (classId == null) return;
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(ordersRepositoryProvider)
          .create(
            paymentType: _paymentType,
            items: [(id: classId, quantity: _quantity)],
            studentId: _studentId,
            redirectUrl: 'planles://payment',
          );

      ref.invalidate(ordersListProvider);
      ref.read(authControllerProvider.notifier).refreshUser();

      final url = result.checkoutUrl;
      if (url != null) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }

      if (!mounted) return;
      final orderId = result.orderId;
      if (orderId != null) {
        context.go('/orders/$orderId');
      } else {
        context.go('/orders');
      }
      if (mounted) {
        showAppSnack(
          context,
          url == null
              ? l10n.buyLessonsOrderPlaced
              : l10n.buyLessonsCompletePayment,
        );
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
