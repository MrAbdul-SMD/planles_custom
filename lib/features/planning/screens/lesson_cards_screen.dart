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

  bool _isSelfReflection(LessonCardQuestion q) {
    final name = q.category?.name?.toLowerCase() ?? '';
    return q.category?.id == 2 ||
        name.contains('zelfreflect') ||
        name.contains('self reflection') ||
        name.contains('self-reflection');
  }

  bool _canAnswer(LessonCardQuestion q) {
    if (_isInstructor) return true;
    return _isSelfReflection(q);
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

      // Instructors can answer all lesson-card questions. Students may answer only
      // self-reflection questions, but must be able to view all questions/answers
      // in read-only form. For legacy responses that distinguish by
      // `category.type` (student/instructor), keep that split.
      final hasTypedCategories =
          questions.any((q) => (q.category?.type ?? '').isNotEmpty);
      final wanted = _isInstructor ? 'instructor' : 'student';
      final mine = hasTypedCategories
          ? questions
              .where((q) => q.category?.type == wanted || q.category == null)
              .toList()
          : questions;

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
            (a.dirty || (a.text.isNotEmpty && a.question.text != a.text)))
          {
            'questionId': a.question.id,
            'text': a.text,
            if (a.score != null) 'score': a.score,
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
    const otherCategory = '__other__';
    const otherSub = '__other__';

    for (final answer in _answers) {
      final category = answer.question.category?.name ?? otherCategory;
      final subCategory = answer.question.subCategory?.name ?? otherSub;
      grouped
          .putIfAbsent(category, () => <String, List<_Answer>>{})
          .putIfAbsent(subCategory, () => <_Answer>[])
          .add(answer);
    }

    final widgets = <Widget>[];
    var index = 0;

    grouped.forEach((category, subGroups) {
      final total = subGroups.values.fold<int>(0, (s, l) => s + l.length);
      final answered = subGroups.values.fold<int>(
        0,
        (s, l) =>
            s +
            l.where((a) => a.text.trim().isNotEmpty || a.score != null).length,
      );

      widgets.add(
        Card(
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            initiallyExpanded: widgets.isEmpty,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            title: Text(
              category == otherCategory ? '-' : category,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(
              '$answered/$total',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            children: [
              for (final entry in subGroups.entries) ...[
                if (entry.key != otherSub)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        entry.key,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                for (final answer in entry.value) ...[
                  () {
                    index++;
                    return _QuestionCard(
                      index: index,
                      answer: answer,
                      controller: _controllers[answer.question.id]!,
                      editable: _canAnswer(answer.question),
                    );
                  }(),
                  const SizedBox(height: 8),
                ],
              ],
            ],
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
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      children: [
                        if (_answers.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                            child: Text(
                              '$answered/${_answers.length}',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ..._buildGroupedAnswers(theme),
                      ],
                    ),
      bottomNavigationBar: !hasEditable
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(l10n.lessonCardSave),
                ),
              ),
            ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.index,
    required this.answer,
    required this.controller,
    this.editable = true,
  });

  final int index;
  final _Answer answer;
  final TextEditingController controller;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            answer.question.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          if (editable)
            TextField(
              controller: controller,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                isDense: true,
                hintText: l10n.lessonCardAnswerLabel,
                border: const OutlineInputBorder(),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                controller.text.trim().isEmpty ? '—' : controller.text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: controller.text.trim().isEmpty
                      ? theme.colorScheme.outline
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${l10n.lessonCardScoreLabel}:',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final score in const [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            label: Text('$score'),
                            selected: answer.score == score,
                            onSelected: editable
                                ? (_) {
                                    answer.score = score;
                                    answer.dirty = true;
                                    (context as Element).markNeedsBuild();
                                  }
                                : null,
                          ),
                        ),
                      ChoiceChip(
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        label: const Text('–'),
                        selected: answer.score == null,
                        onSelected: editable
                            ? (_) {
                                answer.score = null;
                                answer.dirty = true;
                                (context as Element).markNeedsBuild();
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
