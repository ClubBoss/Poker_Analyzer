import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/pack_library_round_trip_validator_service.dart';
import '../services/training_pack_library_importer.dart';

class TrainingPackImportValidatorScreen extends StatefulWidget {
  const TrainingPackImportValidatorScreen({super.key});

  @override
  State<TrainingPackImportValidatorScreen> createState() =>
      _TrainingPackImportValidatorScreenState();
}

class _TrainingPackImportValidatorScreenState
    extends State<TrainingPackImportValidatorScreen> {
  String? _directory;
  RoundTripResult? _result;
  bool _loading = false;
  int _packCount = 0;

  Future<void> _pickDirectory() async {
    final dir = await FilePicker.platform.getDirectoryPath();
    if (dir != null) {
      setState(() {
        _directory = dir;
        _result = null;
        _packCount = 0;
      });
    }
  }

  Future<void> _validate() async {
    final dir = _directory;
    if (dir == null || _loading) return;
    setState(() {
      _loading = true;
      _result = null;
    });

    final importer = TrainingPackLibraryImporter();
    final packs = await importer.loadFromDirectory(dir);
    final initialErrors = List<String>.from(importer.errors);

    final service = PackLibraryRoundTripValidatorService(
      importer: TrainingPackLibraryImporter(),
    );
    final rt = service.validate(packs);
    final errors = [...initialErrors, ...rt.errors];

    if (!mounted) return;
    setState(() {
      _packCount = packs.length;
      _result = RoundTripResult(success: errors.isEmpty, errors: errors);
      _loading = false;
    });
  }

  void _copyLog() {
    final text = _result?.errors.join('\n') ?? '';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Скопировано')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Validator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              onPressed: _pickDirectory,
              icon: const Icon(Icons.folder_open),
              label: Text(_directory ?? 'Выбрать каталог'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _directory == null || _loading ? null : _validate,
              child: const Text('Validate'),
            ),
            const SizedBox(height: 16),
            if (_loading) const CircularProgressIndicator(),
            if (_result != null && !_loading) ...[
              Row(
                children: [
                  Icon(
                    _result!.success ? Icons.check_circle : Icons.error,
                    color: _result!.success ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _result!.success
                        ? 'Успех: $_packCount паков'
                        : 'Ошибок: ${_result!.errors.length}',
                  ),
                  const Spacer(),
                  if (!_result!.success)
                    TextButton(
                      onPressed: _copyLog,
                      child: const Text('Copy log'),
                    ),
                ],
              ),
              if (!_result!.success)
                Expanded(
                  child: ListView(
                    children: [
                      for (final e in _result!.errors)
                        ListTile(
                          leading: const Icon(Icons.error, color: Colors.red),
                          title: Text(e),
                        ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
