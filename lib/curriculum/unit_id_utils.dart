// Append-only. ASCII-only.
// Rich track/unit ID SSOT and helpers.

// Canonical labels
const String kPackL1 = 'L1';
const String kPackL2 = 'L2';
const String kPackBridge = 'BRIDGE';
const String kPackCheckpoint = 'CHECKPOINT';
const String kPackBoss = 'BOSS';

// Per-module practice IDs: <moduleId>_l1, <moduleId>_l2
List<String> practiceIdsFor(String moduleId) => [
  '${moduleId}_l1',
  '${moduleId}_l2',
];

// Bridge between two modules in same branch: bridge_<branch>_<aIdx>_<bIdx>
// Example: bridge_core_02_03
String bridgeId({
  required String branch,
  required int aIdx,
  required int bIdx,
}) =>
    'bridge_${branch}_${aIdx.toString().padLeft(2, '0')}_${bIdx.toString().padLeft(2, '0')}';

// Unit checkpoint: checkpoint_<branch>_unit_<u>
String checkpointId({required String branch, required int unit}) =>
    'checkpoint_${branch}_unit_${unit.toString().padLeft(2, '0')}';

// Branch boss: boss_<branch>
String bossId(String branch) => 'boss_${branch}';
