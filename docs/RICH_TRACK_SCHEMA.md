RICH TRACK SCHEMA (ASCII ONLY)

Purpose
- Define a single source of truth (SSOT) for rich training track IDs.
- Keep labels stable and append only. No renames, no reordering.
- Ensure IDs are ASCII only and human readable.

Unit Structure
- Each unit contains 6 modules.
- Practice packs exist per module to reinforce skills.

Pack Types
- L1: first practice pass for a module.
- L2: second practice pass for the same module.
- BRIDGE: a short connector between two modules within the same branch.
- CHECKPOINT: a small exam that validates progress across recent content.
- BOSS: a branch level challenge that concludes a branch.

Canonical Labels
- kPackL1: "L1"
- kPackL2: "L2"
- kPackBridge: "BRIDGE"
- kPackCheckpoint: "CHECKPOINT"
- kPackBoss: "BOSS"

ID Shapes
- Per module practice IDs (two per module):
  - <moduleId>_l1
  - <moduleId>_l2
  - Example: core_rules_and_setup_l1, core_rules_and_setup_l2

- Bridge IDs (within a branch between module indices a and b):
  - bridge_<branch>_<aa>_<bb>
  - Example: bridge_core_02_03

- Checkpoint IDs (within a branch for a unit index):
  - checkpoint_<branch>_unit_<uu>
  - Example: checkpoint_cash_unit_03

- Boss IDs (per branch):
  - boss_<branch>
  - Example: boss_mtt

Zero Padding Rules
- Module indices and unit indices use two digit zero padding.
- That is, 2 -> 02, 3 -> 03, etc.

When To Add Each Pack
- L1: add after introducing or revisiting a module, as the first practice.
- L2: add after L1 to deepen practice on the same module.
- BRIDGE: add when linking two closely related modules inside the same branch.
- CHECKPOINT: add at natural milestones within a branch, per unit.
- BOSS: add at the end of a branch.

Constraints
- ASCII only for all labels and generated IDs.
- Append only contract for canonical labels. Never rename or remove.
- Keep ID generation helpers in lib/curriculum/unit_id_utils.dart.

