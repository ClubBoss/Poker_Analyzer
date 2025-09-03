import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

/// Validates that the dispatcher’s leading module blocks (prefix)
/// match `modules_done` sorted by the SSOT order from
/// `tooling/curriculum_ids.dart`. Also enforces spacing rules:
/// - No blank empty lines between blocks
/// - No blank lines inside a block
void main() {
  const ssotPath = 'tooling/curriculum_ids.dart';
  const statusPath = 'curriculum_status.json';
  const dispatcherPath = 'prompts/dispatcher/_ALL.txt';

  final missingReasons = <String>[];
  if (!File(ssotPath).existsSync()) {
    missingReasons.add('missing $ssotPath');
  }
  if (!File(statusPath).existsSync()) {
    missingReasons.add('missing $statusPath');
  }
  if (!File(dispatcherPath).existsSync()) {
    missingReasons.add('missing $dispatcherPath');
  }
  final skipReason = missingReasons.isEmpty ? null : missingReasons.join(', ');

  test(
    'dispatcher prefix equals modules_done (SSOT-sorted); spacing rules enforced',
    () {
      // Read files (ASCII-only) and parse.
      final ssotContent = _readAscii(ssotPath);
      final statusContent = _readAscii(statusPath);
      final dispatcherContent = _readAscii(dispatcherPath);

      final ssotOrder = _parseSsotOrder(ssotContent);
      expect(ssotOrder, isNotEmpty, reason: 'No IDs parsed from $ssotPath');

      final modulesDone = _parseModulesDone(statusContent);
      // modules_done may be empty; still validate spacing rules below.

      // Validate modules_done are present in SSOT.
      final unknown = modulesDone.where((m) => !ssotOrder.contains(m)).toList();
      expect(
        unknown,
        isEmpty,
        reason:
            'modules_done contains IDs not in SSOT ($ssotPath): ${unknown.join(', ')}',
      );

      final dispatcherLines = dispatcherContent
          .split('\n')
          .map((l) {
            // tolerate \r\n endings
            if (l.endsWith('\r')) return l.substring(0, l.length - 1);
            return l;
          })
          .toList(growable: false);

      // Parse dispatcher blocks and enforce spacing rules.
      final parseResult = _parseDispatcher(dispatcherLines);
      final spacingViolations = parseResult.spacingViolations;
      expect(
        spacingViolations,
        isEmpty,
        reason:
            'Spacing violations in $dispatcherPath:\n- ${spacingViolations.join('\n- ')}',
      );

      // Expected: modules_done sorted by SSOT order.
      final expectedPrefix = ssotOrder
          .where((id) => modulesDone.contains(id))
          .toList(growable: false);

      // Actual: take the first N module_id values from dispatcher, where N is expectedPrefix.length.
      final actualModuleIds = parseResult.moduleIds;
      expect(
        actualModuleIds.length >= expectedPrefix.length,
        isTrue,
        reason:
            'Dispatcher has fewer module blocks (${actualModuleIds.length}) than modules_done (${expectedPrefix.length}).',
      );
      final actualPrefix = actualModuleIds
          .take(expectedPrefix.length)
          .toList(growable: false);

      // Compare sequences with helpful diff if mismatch.
      if (!_listsEqual(actualPrefix, expectedPrefix)) {
        // Find first mismatch index, if any.
        final max = expectedPrefix.length;
        int? firstMismatch;
        for (var i = 0; i < max; i++) {
          if (actualPrefix[i] != expectedPrefix[i]) {
            firstMismatch = i;
            break;
          }
        }
        fail(
          'Dispatcher prefix does not match modules_done (SSOT-sorted).\n'
          'first_mismatch_index: ${firstMismatch ?? 'n/a'}\n'
          'expected_prefix(${expectedPrefix.length}): ${expectedPrefix.join(', ')}\n'
          'actual_prefix  (${actualPrefix.length}): ${actualPrefix.join(', ')}',
        );
      }

      // After all assertions pass, print NEXT for live_* skeletons.
      // If any of the tracked live_* IDs are not in modules_done, print all missing
      // in the requested order. Otherwise, fall back to DONE.
      // Note: append-only list; order matters for output.
      const trackedLiveIds = <String>[
        'live_tells_and_dynamics',
        'live_etiquette_and_procedures',
        'live_full_ring_adjustments',
        'live_special_formats_straddle_bomb_ante',
        'live_table_selection_and_seat_change',
        'live_chip_handling_and_bet_declares',
        'live_speech_timing_basics',
        'live_rake_structures_and_tips',
        'live_floor_calls_and_dispute_resolution',
        'live_session_log_and_review',
        'live_security_and_game_integrity',
      ];
      final missingLive = trackedLiveIds
          .where((id) => !modulesDone.contains(id))
          .toList(growable: false);
      if (missingLive.isNotEmpty) {
        print('NEXT: ${missingLive.join(', ')}');
      } else {
        print('NEXT: DONE');
      }
    },
    skip: skipReason,
  );
}

// Utilities

String _readAscii(String path) {
  final bytes = File(path).readAsBytesSync();
  for (var i = 0; i < bytes.length; i++) {
    final b = bytes[i];
    if (b > 0x7F) {
      throw TestFailure(
        'Non-ASCII byte 0x${b.toRadixString(16)} at offset $i in $path',
      );
    }
  }
  return utf8.decode(bytes, allowMalformed: false);
}

List<String> _parseSsotOrder(String ssotContent) {
  // Regex extracts the array body: curriculumIds = [ ... ];
  final listMatch = RegExp(
    r'curriculumIds\s*=\s*\[(.*?)\];',
    dotAll: true,
    multiLine: true,
  ).firstMatch(ssotContent);
  if (listMatch == null) return const [];
  final body = listMatch.group(1)!;
  // Extract each "id" token in order; ASCII-only ids.
  final idRe = RegExp(r'"([a-z0-9_]+)"');
  final ids = <String>[];
  for (final m in idRe.allMatches(body)) {
    ids.add(m.group(1)!);
  }
  return ids;
}

List<String> _parseModulesDone(String statusContent) {
  try {
    final jsonMap = json.decode(statusContent);
    if (jsonMap is Map && jsonMap['modules_done'] is List) {
      return List<String>.from(jsonMap['modules_done']);
    }
  } catch (e) {
    throw TestFailure('Invalid JSON in curriculum_status.json: $e');
  }
  throw TestFailure(
    'Missing or invalid modules_done in curriculum_status.json',
  );
}

class _DispatcherParseResult {
  _DispatcherParseResult(this.moduleIds, this.spacingViolations);
  final List<String> moduleIds;
  final List<String> spacingViolations;
}

_DispatcherParseResult _parseDispatcher(List<String> lines) {
  final moduleIds = <String>[];
  final violations = <String>[];

  bool inBlock = false;
  int? currentBlockStartLine; // 1-based
  String? prevLine;

  for (var i = 0; i < lines.length; i++) {
    final raw = lines[i];
    final line = raw; // already normalized to no trailing \r

    final isModuleHeader = line.startsWith('module_id: ');
    final isBlank = line.trim().isEmpty;

    if (isModuleHeader) {
      // Between-block blank line check: previous physical line cannot be blank if we were inside a block.
      if (inBlock && (prevLine != null && prevLine.trim().isEmpty)) {
        violations.add('Blank line between blocks before line ${i + 1}');
      }

      // Capture module_id value.
      final id = line.substring('module_id: '.length).trim();
      if (id.isEmpty) {
        violations.add('Empty module_id at line ${i + 1}');
      } else {
        moduleIds.add(id);
      }

      // Start new block.
      inBlock = true;
      currentBlockStartLine = i + 1;
    } else if (isBlank) {
      if (inBlock) {
        // Allow a single trailing newline at EOF; otherwise, any blank line
        // while inside a block is a violation.
        final isLastPhysicalLine = (i == lines.length - 1);
        if (!isLastPhysicalLine) {
          final start = currentBlockStartLine ?? (i + 1);
          violations.add(
            'Blank line inside block starting at line $start (at line ${i + 1})',
          );
        }
      }
    } else {
      // Non-blank, non-header line inside a block is fine. Outside blocks we ignore.
    }

    prevLine = line;
  }

  return _DispatcherParseResult(moduleIds, violations);
}

bool _listsEqual(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
