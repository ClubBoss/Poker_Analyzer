Image Specs Generator

Purpose
- Create or update `spec.yml` for each module based on image placeholders in `theory.md`.
- Keeps existing items and their order; appends only missing slugs; fills empty captions.

Placeholders
- In `content/<module>/v1/theory.md`, images are marked as:
  - `[[IMAGE: slug | Caption]]`
- Parse order: first seen in the file.
- Slug rules: `a-z0-9_` only. Invalid slugs are reported and skipped.

YAML Shape
- File: `content/<module>/v1/spec.yml`
- Content (deterministic ordering):

  module: <module_id>
  images:
    - slug: <slug>
      caption: <caption from theory.md>
      engine: unknown   # allowed: mermaid | pyplot | external | unknown
      src: ""           # path to .mmd/.py or external URL; empty by default
      out: images/<slug>.svg
      status: todo      # allowed: todo | done
      notes: ""         # optional free text

- If the file already exists:
  - Keep existing items and their order.
  - Append only missing slugs (in the order found in theory.md).
  - Update `caption` only if it is empty.

CLI Usage
- From repo root:
  - Process all modules: `dart run tooling/gen_image_specs.dart`
  - Single module: `dart run tooling/gen_image_specs.dart core_board_textures`

Output & Exit Codes
- Prints a concise summary: `created=<n>, updated=<n>, unchanged=<n>, errors=<n>`
- Exit 0 on success, even when some modules have no images or contain invalid slugs.
- Exit 1 only on I/O or YAML write errors.

Local Formatting (if the wider repo has parse errors)
- `dart format tooling/gen_image_specs.dart`
- `dart run tooling/gen_image_specs.dart`
- `dart run tooling/gen_image_specs.dart core_board_textures`

Run Order
- Generate specs from theory.md placeholders:
  - `dart run tooling/gen_image_specs.dart`
- Create placeholder SVGs for all referenced slugs:
  - `dart run tooling/render_images_stub.dart`
- Insert Markdown image links under placeholders:
  - `dart run tooling/link_images_in_theory.dart`
