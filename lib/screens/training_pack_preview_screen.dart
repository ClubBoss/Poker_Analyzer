import 'package:flutter/material.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_v2.dart';
import '../services/pack_favorite_service.dart';
import '../services/pack_rating_service.dart';
import '../services/training_pack_comments_service.dart';
import '../services/mini_lesson_library_service.dart';
import '../services/inline_theory_linker_service.dart';
import '../widgets/pack_insights_banner.dart';
import '../widgets/pack_recommendation_section.dart';
import 'mini_lesson_screen.dart';
import '../models/theory_mini_lesson_node.dart';
import 'training_session_screen.dart';

class TrainingPackPreviewScreen extends StatefulWidget {
  final TrainingPackTemplateV2 template;
  const TrainingPackPreviewScreen({super.key, required this.template});

  @override
  State<TrainingPackPreviewScreen> createState() =>
      _TrainingPackPreviewScreenState();
}

class _TrainingPackPreviewScreenState extends State<TrainingPackPreviewScreen> {
  late bool _favorite;
  int? _userRating;
  double? _average;
  String? _comment;
  TheoryMiniLessonNode? _lesson;
  final _linker = InlineTheoryLinkerService();

  @override
  void initState() {
    super.initState();
    _favorite = PackFavoriteService.instance.isFavorite(widget.template.id);
    _loadRating();
    _loadComment();
    _loadLesson();
  }

  Future<void> _loadRating() async {
    final r = await PackRatingService.instance.getUserRating(widget.template.id);
    final avg = await PackRatingService.instance.getAverageRating(widget.template.id);
    if (mounted) {
      setState(() {
        _userRating = r;
        _average = avg;
      });
    }
  }

  Future<void> _loadComment() async {
    final c = await TrainingPackCommentsService.instance
        .getComment(widget.template.id);
    if (mounted) setState(() => _comment = c);
  }

  Future<void> _toggleFavorite() async {
    await PackFavoriteService.instance.toggleFavorite(widget.template.id);
    if (mounted) setState(() => _favorite = !_favorite);
  }

  Future<void> _setRating(int r) async {
    await PackRatingService.instance.rate(widget.template.id, r);
    final avg = await PackRatingService.instance.getAverageRating(widget.template.id);
    if (mounted) {
      setState(() {
        _userRating = r;
        _average = avg;
      });
    }
  }

  Future<void> _editComment() async {
    final controller = TextEditingController(text: _comment);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Комментарий к паку'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Введите заметку'),
          maxLines: null,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    if (result != null) {
      await TrainingPackCommentsService.instance
          .saveComment(widget.template.id, result);
      if (mounted) setState(() => _comment = result);
    }
  }

  Future<void> _loadLesson() async {
    await MiniLessonLibraryService.instance.loadAll();
    for (final l in MiniLessonLibraryService.instance.all) {
      if (l.linkedPackIds.contains(widget.template.id)) {
        if (mounted) setState(() => _lesson = l);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template.name),
        actions: [
          IconButton(
            icon: Icon(_favorite ? Icons.star : Icons.star_border),
            color: _favorite ? Colors.amber : Colors.white,
            onPressed: _toggleFavorite,
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(widget.template.name,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          _buildRatingRow(),
          const SizedBox(height: 8),
          _buildCommentSection(),
          const SizedBox(height: 8),
          Text('Type: ${widget.template.trainingType.name}',
              style: const TextStyle(color: Colors.white70)),
          if (widget.template.tags.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Tags: ${widget.template.tags.join(', ')}',
                style: const TextStyle(color: Colors.white70)),
          ],
          if (widget.template.audience != null &&
              widget.template.audience!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Audience: ${widget.template.audience!}',
                style: const TextStyle(color: Colors.white70)),
          ],
          if (widget.template.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            _linker
                .link(
                  widget.template.description,
                  contextTags: widget.template.tags,
                )
                .toRichText(
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  linkStyle: const TextStyle(color: Colors.lightBlueAccent),
                ),
          ],
          if (widget.template.goal.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Goal: ${widget.template.goal}',
                style: const TextStyle(color: Colors.white70)),
          ],
          if (widget.template.positions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Positions: ${widget.template.positions.join(', ')}',
                style: const TextStyle(color: Colors.white70)),
          ],
          if (widget.template.meta.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Meta:', style: TextStyle(fontWeight: FontWeight.bold)),
            for (final e in widget.template.meta.entries)
              Text('${e.key}: ${e.value}',
                  style: const TextStyle(color: Colors.white70)),
          ],
          if (widget.template.spotCount > 0) ...[
            const SizedBox(height: 8),
            Text('Spots: ${widget.template.spotCount}',
                style: const TextStyle(color: Colors.white70)),
          ],
          if (widget.template.spots.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Примеры:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (final s in widget.template.spots.take(3))
              ListTile(
                title: Text(s.title.isEmpty ? 'Spot' : s.title),
                subtitle: Text('Tags: ${s.tags.join(', ')}'),
              ),
          ],
          PackInsightsBanner(templateId: widget.template.id),
          const SizedBox(height: 24),
          if (_lesson != null) ...[
            ElevatedButton(
              onPressed: () {
                final lesson = _lesson!;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MiniLessonScreen(lesson: lesson),
                  ),
                );
              },
              child: const Text('Повторить теорию'),
            ),
            const SizedBox(height: 12),
          ],
          ElevatedButton(
            onPressed: () {
              final pack = TrainingPackV2.fromTemplate(
                  widget.template, widget.template.id);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => TrainingSessionScreen(pack: pack),
                ),
              );
            },
            child: const Text('Начать тренировку'),
          ),
          PackRecommendationSection(template: widget.template),
        ],
      ),
    );
  }

  Widget _buildRatingRow() {
    return Row(
      children: [
        for (int i = 1; i <= 5; i++)
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              i <= (_userRating ?? 0) ? Icons.star : Icons.star_border,
              color: Colors.amber,
            ),
            onPressed: () => _setRating(i),
          ),
        if (_average != null) ...[
          const SizedBox(width: 8),
          Text(
            _average!.toStringAsFixed(1),
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ],
    );
  }

  Widget _buildCommentSection() {
    final hasComment = _comment != null && _comment!.isNotEmpty;
    return ListTile(
      leading: const Text('📝'),
      title: Text(hasComment ? 'Комментарий игрока' : 'Добавить комментарий'),
      subtitle: hasComment ? Text(_comment!) : null,
      trailing: hasComment ? const Icon(Icons.edit) : null,
      onTap: _editComment,
    );
  }
}
