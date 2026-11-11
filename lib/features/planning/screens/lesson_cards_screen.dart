import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/planning.dart';
import '../providers/planning_providers.dart';

/// The lesson card: one screen per planning, questions grouped by category.
/// Students fill in the `student` questions, instructors the `instructor`
/// ones — the API rejects the wrong combination.
class LessonCardsScreen extends ConsumerStatefulWidget {
  const LessonCardsScreen({super.key, required this.planningId});

  final int planningId;

  @override
  ConsumerState<LessonCardsScreen> createState() => _LessonCardsScreenState();
}

class _Answer {
  _Answer(this.question);

  final LessonCardQuestion question;
  late String text = question.text ?? '';
  late int? score = question.score;
  bool dirty = false;
}

class _LessonCardsScreenState extends ConsumerState<LessonCardsScreen> {
  final List<_Answer> _answers = [];
  final Map<int, TextEditingController> _controllers = {};
  final Map<String, bool> _expandedCategories = {};
  bool _loading = true;
  bool _saving = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _isInstructor => ref.read(currentUserProvider)?.isInstructor == true;

  bool _isStudentType(LessonCardQuestion q) {
    final type = q.category?.type?.toLowerCase();
    if (type == 'student') return true;
    if (type == 'instructor') return false;

    final name = q.category?.name?.toLowerCase() ?? '';
    final subName = q.subCategory?.name?.toLowerCase() ?? '';
    if (name.contains('zelfreflect') ||
        name.contains('self reflection') ||
        name.contains('self-reflection') ||
        subName.contains('zelfreflect') ||
        subName.contains('self reflection') ||
        subName.contains('self-reflection')) {
      return true;
    }

    // Fallback for known sample data when API type is not provided.
    return q.category?.id == 2;
  }

  bool _isInstructorType(LessonCardQuestion q) => !_isStudentType(q);

  bool _canAnswer(LessonCardQuestion q) {
    if (_isInstructor) return _isInstructorType(q);
    return _isStudentType(q);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final questions = await ref
          .read(planningRepositoryProvider)
          .lessonCards(widget.planningId);

      // Instructors update instructor-type categories, students update
      // student-type (self-reflection) categories. Everyone can view all
      // questions and answers in read-only form when not editable.
      final mine = questions;

      _answers
        ..clear()
        ..addAll(mine.map(_Answer.new));
      for (final c in _controllers.values) {
        c.dispose();
      }
      _controllers.clear();
      for (final a in _answers) {
        _controllers[a.question.id] = TextEditingController(text: a.text)
          ..addListener(() {
            if (!_canAnswer(a.question)) return;
            a.text = _controllers[a.question.id]!.text;
            a.dirty = true;
          });
      }
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e;
        });
      }
    }
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final payload = <Map<String, dynamic>>[
      for (final a in _answers)
        if (_canAnswer(a.question) &&
            (a.dirty ||
                a.text != (a.question.text ?? '') ||
                a.score != a.question.score))
          {
            'questionId': a.question.id,
            'text': a.text,
            'score': a.score,
          },
    ];

    if (payload.isEmpty) {
      showAppSnack(context, l10n.lessonCardFillFirst, error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(planningRepositoryProvider)
          .answerLessonCards(widget.planningId, payload);
      if (mounted) {
        showAppSnack(context, l10n.lessonCardSaved);
        await _load();
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

  List<Widget> _buildGroupedAnswers(ThemeData theme) {
    final grouped = <String, Map<String, List<_Answer>>>{};
    const uncategorized = '—';

    for (final answer in _answers) {
      final category = answer.question.category?.name ?? uncategorized;
      final subCategory = answer.question.subCategory?.name ?? uncategorized;
      grouped
          .putIfAbsent(category, () => <String, List<_Answer>>{})
          .putIfAbsent(subCategory, () => <_Answer>[])
          .add(answer);
    }

    final widgets = <Widget>[];
    var categoryIndex = 0;

    grouped.forEach((category, subGroups) {
      categoryIndex++;
      final total = subGroups.values.fold<int>(0, (s, l) => s + l.length);
      final answered = subGroups.values.fold<int>(
        0,
        (s, l) =>
            s +
            l.where((a) => a.text.trim().isNotEmpty || a.score != null).length,
      );
      final categoryKey =
          'lesson-cat-$categoryIndex-${category.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}';
      final expanded = _expandedCategories.putIfAbsent(
        category,
        () => categoryIndex == 1,
      );

      final first =
          subGroups.values.isNotEmpty && subGroups.values.first.isNotEmpty
              ? subGroups.values.first.first.question
              : null;
      final studentType = first != null && _isStudentType(first);
      final accent = studentType
          ? theme.colorScheme.secondary
          : theme.colorScheme.primary;
      final accentContainer = studentType
          ? theme.colorScheme.secondaryContainer
          : theme.colorScheme.primaryContainer;
      final onAccentContainer = studentType
          ? theme.colorScheme.onSecondaryContainer
          : theme.colorScheme.onPrimaryContainer;
      final progress = total == 0 ? 0.0 : answered / total;

      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              key: ValueKey(categoryKey),
              initiallyExpanded: expanded,
              onExpansionChanged: (value) {
                setState(() => _expandedCategories[category] = value);
              },
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              shape: const RoundedRectangleBorder(),
              collapsedShape: const RoundedRectangleBorder(),
              iconColor: accent,
              collapsedIconColor: theme.colorScheme.onSurfaceVariant,
              title: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: accentContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      studentType
                          ? Icons.self_improvement_rounded
                          : Icons.fact_check_rounded,
                      size: 18,
                      color: onAccentContainer,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      category,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  _TypePill(
                    label: studentType ? 'Student' : 'Instructor',
                    color: accentContainer,
                    textColor: onAccentContainer,
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8, left: 44),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: theme
                                  .colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.7),
                              valueColor: AlwaysStoppedAnimation<Color>(accent),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '$answered/$total',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              children: [
                for (final entry in subGroups.entries) ...[
                  if (entry.key != uncategorized || subGroups.length > 1)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(2, 8, 2, 6),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 16,
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.key == uncategorized ? category : entry.key,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  for (final (i, answer) in entry.value.indexed)
                    _QuestionRow(
                      answer: answer,
                      controller: _controllers[answer.question.id]!,
                      editable: _canAnswer(answer.question),
                    ),
                  if (entry.key != subGroups.keys.last)
                    const SizedBox(height: 4),
                ],
              ],
            ),
          ),
        ),
      );
    });

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final hasEditable = _answers.any((a) => _canAnswer(a.question));
    final answered = _answers
        .where((a) => a.text.trim().isNotEmpty || a.score != null)
        .length;
    final total = _answers.length;
    final progress = total == 0 ? 0.0 : answered / total;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.lessonCardTitle),
        actions: [
          IconButton(
            tooltip: l10n.lessonCardRefresh,
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorView(
                  message: describeError(context, _error!),
                  onRetry: _load,
                )
              : _answers.isEmpty
                  ? EmptyState(
                      icon: Icons.fact_check_outlined,
                      title: l10n.lessonCardEmptyTitle,
                      subtitle: l10n.lessonCardEmptySubtitle,
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _isInstructor
                                        ? Icons.assignment_ind_rounded
                                        : Icons.edit_note_rounded,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _isInstructor
                                          ? 'Update instructor categories'
                                          : 'Update self-reflection (student) categories',
                                      style:
                                          theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$answered/$total',
                                    style:
                                        theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 8,
                                  backgroundColor: theme
                                      .colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                hasEditable
                                    ? 'Editable items are highlighted. Others are read-only.'
                                    : 'Read-only view.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        ..._buildGroupedAnswers(theme),
                      ],
                    ),
      bottomNavigationBar: !hasEditable
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.4),
                    ),
                  ),
                ),
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(l10n.lessonCardSave),
                ),
              ),
            ),
    );
  }
}

class _QuestionRow extends StatefulWidget {
  const _QuestionRow({
    required this.answer,
    required this.controller,
    this.editable = true,
  });

  final _Answer answer;
  final TextEditingController controller;
  final bool editable;

  @override
  State<_QuestionRow> createState() => _QuestionRowState();
}

class _QuestionRowState extends State<_QuestionRow> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final answer = widget.answer;
    final controller = widget.controller;
    final editable = widget.editable;
    final hasContent = answer.text.trim().isNotEmpty || answer.score != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: editable
            ? theme.colorScheme.surface
            : theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: editable
              ? theme.colorScheme.primary.withValues(alpha: 0.18)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: hasContent
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  answer.question.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _ScoreControl(
                score: answer.score,
                editable: editable,
                onChanged: (value) {
                  setState(() {
                    answer.score = value;
                    answer.dirty = true;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (editable)
            TextField(
              controller: controller,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              minLines: 1,
              maxLines: 4,
              expands: false,
              style: theme.textTheme.bodyMedium,
              onChanged: (value) {
                if (!widget.editable) return;
                answer.text = value;
                answer.dirty = true;
              },
              decoration: InputDecoration(
                hintText: l10n.lessonCardAnswerLabel,
                filled: true,
                fillColor:
                    theme.colorScheme.surfaceContainerLowest.withValues(alpha: 0.8),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                controller.text.trim().isEmpty ? '—' : controller.text.trim(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: controller.text.trim().isEmpty
                      ? theme.colorScheme.outline
                      : theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ),
          if (!editable) ...[
            const SizedBox(height: 6),
            Text(
              'Read-only',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScoreControl extends StatelessWidget {
  const _ScoreControl({
    required this.score,
    required this.editable,
    required this.onChanged,
  });

  final int? score;
  final bool editable;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasScore = score != null;
    final bg = hasScore
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7);
    final fg = hasScore
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;

    if (!editable) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          score?.toString() ?? '–',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: fg,
          ),
        ),
      );
    }

    return PopupMenuButton<int?>(
      tooltip: 'Score',
      initialValue: score,
      onSelected: onChanged,
      itemBuilder: (context) => [
        const PopupMenuItem<int?>(value: null, child: Text('–  No score')),
        for (final s in const [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
          PopupMenuItem<int?>(value: s, child: Text('$s')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasScore
                ? Colors.transparent
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              score?.toString() ?? '–',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.unfold_more_rounded, size: 16, color: fg),
          ],
        ),
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
      ),
    );
  }
}
