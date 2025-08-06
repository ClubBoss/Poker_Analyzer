import 'package:flutter/material.dart';
import '../services/lazy_pack_loader_service.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'pack_card.dart';
import 'training_pack_template_tooltip_widget.dart';

/// Paginated list that only renders a subset of packs at a time.
/// Uses [LazyPackLoaderService] to avoid loading full pack data until needed.
class TrainingPackListWidget extends StatefulWidget {
  const TrainingPackListWidget({super.key, required this.loader, this.pageSize = 50, this.onOpen});

  final LazyPackLoaderService loader;
  final int pageSize;
  final void Function(TrainingPackTemplateV2)? onOpen;

  @override
  State<TrainingPackListWidget> createState() => _TrainingPackListWidgetState();
}

class _TrainingPackListWidgetState extends State<TrainingPackListWidget> {
  final ScrollController _controller = ScrollController();
  final List<TrainingPackTemplateV2> _visible = [];
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    _loadMore();
    _controller.addListener(() {
      if (_controller.position.pixels >= _controller.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  void _loadMore() {
    final all = widget.loader.templates;
    if (_offset >= all.length) return;
    setState(() {
      _visible.addAll(all.skip(_offset).take(widget.pageSize));
      _offset = _visible.length;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _open(TrainingPackTemplateV2 tpl) async {
    if (widget.onOpen != null) {
      await widget.onOpen!(tpl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _controller,
      itemCount: _visible.length,
      itemBuilder: (context, index) {
        final tpl = _visible[index];
        return TrainingPackTemplateTooltipWidget(
          template: tpl,
          child: PackCard(
            template: tpl,
            onTap: () => _open(tpl),
          ),
        );
      },
    );
  }
}
