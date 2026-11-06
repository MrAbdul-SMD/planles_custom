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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final questions = await ref
          .read(planningRepositoryProvider)
          .lessonCards(widget.planningId);
      final wanted = _isInstructor ? 'instructor' : 'student';
      final mine = questions
          .where((q) => q.category?.type == wanted || q.category == null)
          .toList();

      _answers
        ..clear()
        ..addAll(mine.map(_Answer.new));
      for (final a in _answers) {
        _controllers[a.question.id] = TextEditingController(text: a.text)
          ..addListener(() {
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
        if (a.dirty || (a.text.isNotEmpty && a.question.text != a.text))
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
                for (final (i, answer) in _answers.indexed) ...[
                  _QuestionCard(
                    index: i + 1,
                    answer: answer,
                    controller: _controllers[answer.question.id]!,
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
      bottomNavigationBar: _answers.isEmpty
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
  });

  final int index;
  final _Answer answer;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final sub = answer.question.subCategory?.name;

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        answer.question.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (sub != null && sub != answer.question.title)
                        Text(
                          sub,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
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
                    onSelected: (_) {
                      answer.score = score;
                      answer.dirty = true;
                      (context as Element).markNeedsBuild();
                    },
                  ),
                ChoiceChip(
                  label: const Text('–'),
                  selected: answer.score == null,
                  onSelected: (_) {
                    answer.score = null;
                    answer.dirty = true;
                    (context as Element).markNeedsBuild();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
