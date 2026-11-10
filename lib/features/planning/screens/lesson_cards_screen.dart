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
    final widgets = <Widget>[];
    String? currentCategory;
    String? currentSubCategory;
    var index = 0;

    for (final answer in _answers) {
      index++;
      final category = answer.question.category?.name;
      final subCategory = answer.question.subCategory?.name;

      if (category != null && category != currentCategory) {
        currentCategory = category;
        currentSubCategory = null;
        widgets.add(
          Padding(
            padding: EdgeInsets.only(top: widgets.isEmpty ? 0 : 12, bottom: 8),
            child: Text(
              category,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
      }

      if (subCategory != null && subCategory != currentSubCategory) {
        currentSubCategory = subCategory;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Text(
              subCategory,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }

      widgets.add(
        _QuestionCard(
          index: index,
          answer: answer,
          controller: _controllers[answer.question.id]!,
          editable: _canAnswer(answer.question),
        ),
      );
      widgets.add(const SizedBox(height: 12));
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

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
          ? ErrorView(message: describeError(context, _error!), onRetry: _load)
          : _answers.isEmpty
          ? EmptyState(
              icon: Icons.fact_check_outlined,
              title: l10n.lessonCardEmptyTitle,
              subtitle: l10n.lessonCardEmptySubtitle,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Text(
                  _isInstructor
                      ? l10n.lessonCardInstructorIntro
                      : l10n.lessonCardStudentIntro,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                ..._buildGroupedAnswers(theme),
              ],
            ),
      bottomNavigationBar: _answers.isEmpty || !_answers.any((a) => _canAnswer(a.question))
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : Text(l10n.lessonCardSave),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    '$index',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    answer.question.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              enabled: editable,
              readOnly: !editable,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l10n.lessonCardAnswerLabel,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.lessonCardScoreLabel,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final score in const [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
                  ChoiceChip(
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
                ChoiceChip(
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
          ],
        ),
      ),
    );
  }
}
