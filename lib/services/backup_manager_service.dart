import 'dart:async';
import 'package:flutter/material.dart';

import 'auto_backup_service.dart';
import 'backup_file_manager.dart';
import 'backup_import_export_service.dart';
import 'debug_panel_preferences.dart';
import 'evaluation_queue_serializer.dart';
import 'evaluation_queue_service.dart';
import 'backup_snapshot_service.dart';

/// Coordinates backup-related services such as automatic backups,
/// manual import/export operations and snapshot utilities.
class BackupManagerService {
  BackupManagerService({
    required this.queueService,
    required this.debugPrefs,
    BackupFileManager? fileManager,
    EvaluationQueueSerializer? serializer,
    AutoBackupService? autoBackupService,
    BackupImportExportService? importExportService,
    BackupSnapshotService? snapshotService,
  }) : fileManager = fileManager ?? BackupFileManager(),
       serializer = serializer ?? const EvaluationQueueSerializer() {
    this.autoBackupService =
        autoBackupService ??
        AutoBackupService(
          queueService: queueService,
          fileManager: this.fileManager,
          serializer: this.serializer,
        );
    this.importExportService =
        importExportService ??
        BackupImportExportService(
          queueService: queueService,
          fileManager: this.fileManager,
          serializer: this.serializer,
          debugPanelCallback: () => debugPanelCallback?.call(),
        );
    this.snapshotService =
        snapshotService ??
        BackupSnapshotService(
          queueService: queueService,
          fileManager: this.fileManager,
          serializer: this.serializer,
          debugPanelCallback: () => debugPanelCallback?.call(),
        );

    // Start automatic backups and schedule initial cleanup tasks.
    unawaited(this.autoBackupService.startAutoBackupTimer());
    unawaited(this.autoBackupService.cleanupOldAutoBackups());
    unawaited(this.importExportService.cleanupOldEvaluationBackups());
    unawaited(this.snapshotService.cleanupOldEvaluationSnapshots());
  }

  final EvaluationQueueService queueService;
  final DebugPanelPreferences debugPrefs;
  final BackupFileManager fileManager;
  final EvaluationQueueSerializer serializer;

  late final AutoBackupService autoBackupService;
  late final BackupImportExportService importExportService;
  late final BackupSnapshotService snapshotService;

  VoidCallback? debugPanelCallback;

  static const String backupsFolder = BackupFileManager.backupsFolder;
  static const String autoBackupsFolder = BackupFileManager.autoBackupsFolder;
  static const String snapshotsFolder = BackupFileManager.snapshotsFolder;
  static const String exportsFolder = BackupFileManager.exportsFolder;

  Future<void> startAutoBackupTimer() =>
      autoBackupService.startAutoBackupTimer();
  void dispose() => autoBackupService.dispose();

  Future<void> exportEvaluationQueue(BuildContext context) =>
      importExportService.exportEvaluationQueue(context);

  Future<void> exportFullQueueState(BuildContext context) =>
      importExportService.exportFullQueueState(context);

  Future<void> importFullQueueState(BuildContext context) =>
      importExportService.importFullQueueState(context);

  Future<void> restoreFullQueueState(BuildContext context) =>
      importExportService.restoreFullQueueState(context);

  Future<void> backupEvaluationQueue(BuildContext context) =>
      importExportService.backupEvaluationQueue(context);

  Future<void> quickBackupEvaluationQueue(BuildContext context) =>
      importExportService.quickBackupEvaluationQueue(context);

  Future<void> importQuickBackups(BuildContext context) =>
      importExportService.importQuickBackups(context);

  Future<void> exportArchive(
    BuildContext context,
    String subfolder,
    String prefix,
  ) => importExportService.exportArchive(context, subfolder, prefix);

  Future<void> exportAllEvaluationBackups(BuildContext context) =>
      importExportService.exportAllEvaluationBackups(context);

  Future<void> exportAutoBackups(BuildContext context) =>
      importExportService.exportAutoBackups(context);

  Future<void> restoreFromAutoBackup(BuildContext context) =>
      importExportService.restoreFromAutoBackup(context);

  Future<void> bulkImportEvaluationQueue(BuildContext context) =>
      importExportService.bulkImportEvaluationQueue(context);

  Future<void> bulkImportEvaluationBackups(BuildContext context) =>
      importExportService.bulkImportEvaluationBackups(context);

  Future<void> bulkImportAutoBackups(BuildContext context) =>
      importExportService.bulkImportAutoBackups(context);

  Future<void> cleanupOldEvaluationSnapshots() =>
      snapshotService.cleanupOldEvaluationSnapshots();

  Future<void> saveQueueSnapshot(
    Map<String, dynamic> state, {
    bool showNotification = true,
    bool snapshotRetentionEnabled = true,
  }) => snapshotService.saveQueueSnapshot(
    state,
    showNotification: showNotification,
    snapshotRetentionEnabled: snapshotRetentionEnabled,
  );

  Future<dynamic> loadLatestQueueSnapshot() =>
      snapshotService.loadLatestQueueSnapshot();

  Future<void> exportSnapshots(BuildContext context) =>
      snapshotService.exportSnapshots(context);

  Future<void> importEvaluationQueueSnapshot(BuildContext context) =>
      snapshotService.importEvaluationQueueSnapshot(context);

  Future<void> bulkImportEvaluationSnapshots(BuildContext context) =>
      snapshotService.bulkImportEvaluationSnapshots(context);
}
