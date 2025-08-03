import 'package:flutter/material.dart';

import '../../models/v2/training_pack_spot.dart';
import 'hand_editor_controller.dart';
import 'hand_editor_form.dart';
import 'hand_editor_service.dart';
import '../../utils/snackbar_util.dart';

class HandEditorScreen extends StatefulWidget {
  final TrainingPackSpot spot;
  const HandEditorScreen({super.key, required this.spot});

  @override
  State<HandEditorScreen> createState() => _HandEditorScreenState();
}

class _HandEditorScreenState extends State<HandEditorScreen> {
  late final HandEditorController _controller;
  final _service = HandEditorService();

  @override
  void initState() {
    super.initState();
    _controller = HandEditorController(widget.spot);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    _controller.update();
    final err = _controller.validate();
    if (err != null) {
      SnackbarUtil.showMessage(context, err);
      return;
    }
    widget.spot.editedAt = DateTime.now();
    await _service.saveSpot(widget.spot);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Hand'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _save)],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => HandEditorForm(controller: _controller),
      ),
    );
  }
}
