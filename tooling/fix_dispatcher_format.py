#!/usr/bin/env python3
"""Normalize dispatcher prompt lists.

This tiny fixer normalizes spacing in ``prompts/dispatcher/_ALL.txt`` so the
validator stops reporting empty ``spotkind_allowlist`` entries.

Usage examples for CI:
  Check: python3 tooling/fix_dispatcher_format.py --check prompts/dispatcher/_ALL.txt
  Fix:   python3 tooling/fix_dispatcher_format.py --in-place prompts/dispatcher/_ALL.txt
"""

from __future__ import annotations

import argparse
import os
import sys
import tempfile
from itertools import zip_longest


def _normalize(lines: list[str]):
    result: list[str] = []
    modules_changed: list[str] = []
    current_module: str | None = None
    module_changed = False
    state: str | None = None  # None, 'spot', 'target'
    prev_item: str | None = None

    def finish_module():
        nonlocal module_changed
        if current_module and module_changed and current_module not in modules_changed:
            modules_changed.append(current_module)
        module_changed = False

    i = 0
    while i < len(lines):
        orig_line = lines[i]
        if not orig_line.endswith("\n"):
            orig_line += "\n"
        line = orig_line.rstrip("\n")
        if "\t" in line:
            line = line.replace("\t", "    ")
        stripped = line.rstrip(" ")
        if stripped != line:
            line = stripped
            module_changed = True
        # blank lines
        if line == "":
            if not result:
                if orig_line != "\n":
                    module_changed = True
            elif result[-1] != "\n":
                result.append("\n")
                if orig_line != "\n":
                    module_changed = True
            else:
                if orig_line != "\n":
                    module_changed = True
            i += 1
            continue
        # headers
        if line.startswith("module_id:"):
            finish_module()
            if result and result[-1] != "\n":
                result.append("\n")
                module_changed = True
            current_module = line.split(":", 1)[1].strip()
            out = f"module_id: {current_module}"
            if line != out:
                module_changed = True
            result.append(out + "\n")
            state = None
            prev_item = None
            i += 1
            continue
        if line.startswith("short_scope:"):
            out = "short_scope: " + line.split(":", 1)[1].strip()
            if out != line:
                module_changed = True
            result.append(out + "\n")
            i += 1
            continue
        if line.startswith("spotkind_allowlist:"):
            if result and result[-1] != "\n":
                result.append("\n")
                module_changed = True
            result.append("spotkind_allowlist:\n")
            if line != "spotkind_allowlist:":
                module_changed = True
            state = "spot"
            prev_item = None
            i += 1
            continue
        if line.startswith("target_tokens_allowlist:"):
            if result and result[-1] != "\n":
                result.append("\n")
                module_changed = True
            result.append("target_tokens_allowlist:\n")
            if line != "target_tokens_allowlist:":
                module_changed = True
            state = "target"
            prev_item = None
            i += 1
            continue
        if state in {"spot", "target"}:
            item = line.lstrip()
            out = "  " + item
            norm = out.strip()
            if norm == prev_item:
                module_changed = True
            else:
                if out != line:
                    module_changed = True
                result.append(out + "\n")
                prev_item = norm
            i += 1
            continue
        # passthrough lines
        if line != orig_line.rstrip("\n"):
            module_changed = True
        result.append(line + "\n")
        i += 1
    finish_module()
    lines_changed = sum(1 for o, n in zip_longest(lines, result) if (o or "") != (n or ""))
    return "".join(result), modules_changed, lines_changed


def main() -> int:
    parser = argparse.ArgumentParser(description="Normalize dispatcher format")
    parser.add_argument("path", help="path to _ALL.txt")
    parser.add_argument("--check", action="store_true", help="only check for compliance")
    parser.add_argument("--in-place", action="store_true", dest="in_place", help="rewrite file in place")
    args = parser.parse_args()
    if args.check and args.in_place:
        parser.error("choose either --check or --in-place")
    mode = "in_place" if args.in_place else "check"

    with open(args.path, "r", encoding="ascii", newline="\n") as f:
        original = f.read().splitlines(True)
    normalized, modules_changed, lines_changed = _normalize(original)

    if mode == "check":
        if modules_changed or normalized != "".join(original):
            for mid in modules_changed:
                print(mid)
            return 1
        return 0
    # in-place
    if normalized != "".join(original):
        bak = args.path + ".bak"
        if not os.path.exists(bak):
            with open(bak, "w", encoding="ascii", newline="\n") as bf:
                bf.writelines(original)
        fd, tmp = tempfile.mkstemp(dir=os.path.dirname(args.path))
        try:
            with os.fdopen(fd, "w", encoding="ascii", newline="\n") as tf:
                tf.write(normalized)
            os.replace(tmp, args.path)
        finally:
            if os.path.exists(tmp):
                os.unlink(tmp)
        print(f"modules_touched={len(modules_changed)}, lines_changed={lines_changed}")
    else:
        print("modules_touched=0, lines_changed=0")
    return 0


if __name__ == "__main__":
    sys.exit(main())
