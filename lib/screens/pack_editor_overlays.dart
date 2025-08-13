part of 'pack_editor_core.dart';

Future<void> showSavedHandViewer(BuildContext context, SavedHand hand) async {
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(hand.name),
      content: const Text('Saved-hand viewing not implemented.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

Future<void> showImportExportDialog(
    BuildContext context, PackEditorCore core) async {
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Import / Export'),
      content: const Text('Import and export dialogs are placeholders.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
