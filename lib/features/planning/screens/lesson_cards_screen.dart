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
      final categoryKey = 'lesson-cat-$categoryIndex-${category.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}';
      final expanded = _expandedCategories.putIfAbsent(
        category,
        () => categoryIndex == 1,
      );

      final first = subGroups.values.isNotEmpty &&
              subGroups.values.first.isNotEmpty
          ? subGroups.values.first.first.question
          : null;
      final studentType = first != null && _isStudentType(first);

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            clipBehavior: Clip.antiAlias,
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
              ),
              child: ExpansionTile(
                key: ValueKey(categoryKey),
                initiallyExpanded: expanded,
                onExpansionChanged: (value) {
                  setState(() => _expandedCategories[category] = value);
                },
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                collapsedShape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                backgroundColor: theme.colorScheme.surface,
                collapsedBackgroundColor: theme.colorScheme.surface,
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        category,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: studentType
                            ? theme.colorScheme.secondaryContainer
                            : theme.colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        studentType ? 'Student' : 'Instructor',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: studentType
                              ? theme.colorScheme.onSecondaryContainer
                              : theme.colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '$answered/$total',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final entry in subGroups.entries) ...[
                          if (entry.key != uncategorized || subGroups.length > 1)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8, top: 2),
                              child: Text(
                                entry.key == uncategorized ? category : entry.key,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          for (final (i, answer) in entry.value.indexed) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant,
                                  width: 1,
                                ),
                              ),
                              child: _QuestionRow(
                                answer: answer,
                                controller: _controllers[answer.question.id]!,
                                editable: _canAnswer(answer.question),
                              ),
                            ),
                            if (i != entry.value.length - 1)
                              const SizedBox(height: 6),
                          ],
                        ],
                      ],
                    ),
                  ),
                ],
              ),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.lessonCardTitle),
        actions: [
          if (_answers.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  '$answered/${_answers.length}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: l10n.lessonCardRefresh,
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: _answers.isEmpty
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(28),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _isInstructor
                          ? 'Update instructor categories'
                          : 'Update self-reflection (student) categories',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
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
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                      children: _buildGroupedAnswers(theme),
                    ),
      bottomNavigationBar: !hasEditable
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : Text(l10n.lessonCardSave),
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  answer.question.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (editable)
                DropdownButton<int?>(
                  value: answer.score,
                  isDense: true,
                  underline: const SizedBox.shrink(),
                  alignment: AlignmentDirectional.centerEnd,
                  icon: const Icon(Icons.expand_more, size: 18),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text('–', style: theme.textTheme.bodySmall),
                    ),
                    for (final s in const [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
                      DropdownMenuItem<int?>(
                        value: s,
                        child: Text('$s'),
                      ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      answer.score = value;
                      answer.dirty = true;
                    });
                  },
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: answer.score == null
                        ? theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.4)
                        : theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    answer.score?.toString() ?? '–',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: answer.score == null
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (editable)
            SizedBox(
              width: double.infinity,
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                minLines: 1,
                maxLines: 3,
                expands: false,
                style: theme.textTheme.bodySmall,
                onChanged: (value) {
                  if (!widget.editable) return;
                  answer.text = value;
                  answer.dirty = true;
                },
                decoration: InputDecoration(
                  isDense: true,
                  hintText: l10n.lessonCardAnswerLabel,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            )
          else if (answer.text.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                answer.text.trim(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
