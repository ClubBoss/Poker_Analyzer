#!/usr/bin/env python3
"""
JSONL guard for drills files.

Validates and minimally auto-fixes JSONL content per line.

Behavior:
- Skips blank lines.
- Tries json.loads(line). If it fails, applies safe fixers and retries:
  1) Strip UTF-8 BOM (only at file start) and trailing spaces
  2) Remove trailing commas before '}' or ']'
  3) Insert missing comma between "spot_kind": "..." and "steps":

Exit codes:
- 0 if all lines in all files are valid after optional fixes
- 1 if any invalid line remains (prints precise diagnostics)

Stdlib only. ASCII-friendly output.
"""

from __future__ import annotations

import argparse
import glob
import json
import os
import re
import sys
from pathlib import Path
from typing import Iterable, List, Tuple


TRAILING_COMMA_RE = re.compile(r",\s*([}\]])")
MISSING_COMMA_SPOT_STEPS_RE = re.compile(r'("spot_kind"\s*:\s*"[^"]+")\s*("steps"\s*:)')


def _expand_paths(inputs: Iterable[str]) -> List[Path]:
    paths: List[Path] = []
    for item in inputs:
        # Expand glob patterns; keep order stable; de-dupe while preserving order
        matched = glob.glob(item)
        if not matched:
            matched = [item]
        for m in matched:
            p = Path(m)
            if p.exists() and p.is_file():
                if p not in paths:
                    paths.append(p)
    return paths


def _format_bad(path: Path, line_no: int, col_no: int, msg: str, line: str) -> str:
    caret = " " * (max(col_no, 1) - 1) + "^"
    # Normalize message to a single line
    reason = msg.strip().splitlines()[0]
    return f"BAD {path}:{line_no}:{col_no} -> {reason}\n{line}\n{caret}"


def _try_parse(line: str) -> Tuple[bool, str, int]:
    try:
        json.loads(line)
        return True, "", 1
    except json.JSONDecodeError as e:
        # e.colno is 1-based
        return False, e.msg, e.colno or 1


def _process_file(path: Path, fix: bool) -> Tuple[int, bool]:
    """Validate a single file.

    Returns (bad_count, changed)
    """
    original_text = path.read_text(encoding="utf-8")
    lines = original_text.splitlines(keepends=True)
    out_lines: List[str] = []
    bad = 0
    changed = False

    saw_bom = False
    if lines:
        first = lines[0]
        if first.startswith("\ufeff"):
            saw_bom = True
            lines[0] = first.replace("\ufeff", "", 1)

    for idx, raw in enumerate(lines, start=1):
        # Keep the original newline, operate on the content only
        if raw.endswith("\r\n"):
            nl = "\r\n"
            body = raw[:-2]
        elif raw.endswith("\n") or raw.endswith("\r"):
            nl = raw[-1]
            body = raw[:-1]
        else:
            nl = ""
            body = raw

        if body.strip() == "":
            out_lines.append(body + nl)
            continue

        # Try original first
        ok, msg, col = _try_parse(body)
        candidate = body

        # Apply fixers in order only if needed
        if not ok:
            # 1) strip trailing spaces (BOM already handled above)
            fixed1 = candidate.rstrip(" \t")
            ok, msg, col = _try_parse(fixed1)
            if ok:
                candidate = fixed1
            else:
                # 2) remove trailing commas
                fixed2 = TRAILING_COMMA_RE.sub(r"\1", fixed1)
                ok, msg, col = _try_parse(fixed2)
                if ok:
                    candidate = fixed2
                else:
                    # 3) insert missing comma between spot_kind and steps
                    fixed3 = MISSING_COMMA_SPOT_STEPS_RE.sub(r"\1, \2", fixed2)
                    ok, msg, col = _try_parse(fixed3)
                    if ok:
                        candidate = fixed3

        if ok:
            if candidate != body or saw_bom:
                changed = True
            out_lines.append(candidate + nl)
        else:
            # Report precise error, show the latest candidate used for parsing
            print(_format_bad(path, idx, col, msg, candidate), file=sys.stderr)
            bad += 1
            out_lines.append(body + nl)

    if fix and changed and bad == 0:
        # Write backup, then the fixed content
        bak = path.with_suffix(path.suffix + ".bak")
        try:
            if not bak.exists():
                bak.write_text(original_text, encoding="utf-8")
        except Exception:
            # If backup fails, do not block the fix; proceed to write
            pass
        Path(path).write_text("".join(out_lines), encoding="utf-8")

    return bad, changed


def validate_paths(paths: List[str], fix: bool) -> int:
    files = _expand_paths(paths)
    if not files:
        return 0
    any_bad = 0
    for p in files:
        bad, _ = _process_file(Path(p), fix=fix)
        any_bad += bad
    return 0 if any_bad == 0 else 1


def main(argv: List[str]) -> int:
    parser = argparse.ArgumentParser(
        prog="jsonl_guard",
        description="Validate and minimally auto-fix JSONL drills files.",
        add_help=True,
    )
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--fix", action="store_true", help="apply safe fixes (default)")
    mode.add_argument("--check", action="store_true", help="do not modify files")
    parser.add_argument(
        "paths",
        nargs="*",
        help="paths or globs; default: content/*/v1/drills.jsonl",
    )
    args = parser.parse_args(argv)

    if args.check:
        fix = False
    else:
        fix = True

    inputs = args.paths if args.paths else ["content/*/v1/drills.jsonl"]
    rc = validate_paths(inputs, fix=fix)
    if rc == 0:
        print("OK")
    return rc


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

