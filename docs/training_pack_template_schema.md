# Training Pack Template Schema

## outputVariants

`outputVariants` splits a template into multiple deterministic outputs. It is a map where each key identifies a variant and its value contains constraint overrides. The map form is canonical and keys are written in alphabetical order.

### Migration from list-form

Legacy templates used a list of variants:

```yaml
outputVariants:
  - targetStreet: flop
  - targetStreet: turn
```

Run `dart run tool/migrate_output_variants.dart --write` to convert to the map form.

```yaml
seed: 7
outputVariants:
  flop:
    targetStreet: flop
    seed: 1
    boardConstraints:
      - targetStreet: flop
  turn:
    targetStreet: turn
    seed: 2
    boardConstraints:
      - targetStreet: turn
```

Each variant may override high-level fields such as `targetStreet` or
`boardConstraints` and can provide its own `seed`.

## seed

The optional `seed` field at the template or variant level makes spot and pack
IDs deterministic. Runs with the same seed produce identical IDs and ordering.
