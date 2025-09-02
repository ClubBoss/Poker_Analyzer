#!/usr/bin/env python3
# Normalize dispatcher and auto-fill empty allowlists permanently.
#
# Usage:
#   python3 tooling/fix_dispatcher_format.py --check prompts/dispatcher/_ALL.txt
#   python3 tooling/fix_dispatcher_format.py --in-place prompts/dispatcher/_ALL.txt
#
# Policy:
# - 2-space indent for list items.
# - Tabs -> spaces, strip trailing spaces, LF only.
# - Ensure both blocks exist per module in exact order with no blank lines between:
#     module_id, short_scope, spotkind_allowlist, target_tokens_allowlist
# - spotkind_allowlist: list kinds, no blank lines inside or after the list.
# - target_tokens_allowlist: if empty, must be exactly 'none' (no blank line after).
# - If a block has 0 items -> insert the default item (spot: l2_core_rules_check, tokens: none).
# - Idempotent. Atomic replace. One .bak per run.

from __future__ import annotations
import argparse, os, sys, tempfile
import re
from itertools import zip_longest

SPOT_HDR = "spotkind_allowlist:"
TGT_HDR  = "target_tokens_allowlist:"
SPOT_DEFAULT = "l2_core_rules_check"
TGT_DEFAULT  = "none"

def _normalize(lines: list[str]):
    # Join to text for easier block splitting and capture original blocks for change tracking
    raw_text = "".join(s if s.endswith("\n") else s + "\n" for s in lines)
    raw_text = raw_text.replace("\r\n", "\n").replace("\r", "\n")

    # Split into blocks by module_id line
    mod_re = re.compile(r"^module_id:\s*([a-z0-9_]+)\s*$", re.M)
    matches = list(mod_re.finditer(raw_text))
    if not matches:
        # nothing to do
        return raw_text, [], 0

    out_lines: list[str] = []
    modules_changed: list[str] = []

    def strip_trailing_spaces(s: str) -> str:
        return "\n".join(ln.rstrip().replace("\t", "    ") for ln in s.splitlines()) + ("\n" if s.endswith("\n") else "")

    def parse_block(block_text: str) -> dict:
        # Normalize tabs/spaces and strip trailing spaces for parsing
        norm = block_text.replace("\t", "    ")
        lines = [ln.rstrip("\n\r ") for ln in norm.splitlines()]
        mid = None
        short = None
        spot: list[str] = []
        tgt: list[str] = []
        state = None  # 'spot' | 'tgt' | None
        for ln in lines:
            if not ln:
                # No blank lines inside blocks: skip
                continue
            if ln.startswith("module_id:"):
                mid = ln.split(":", 1)[1].strip()
                state = None
                continue
            if ln.startswith("short_scope:"):
                short = ln.split(":", 1)[1].strip()
                state = None
                continue
            if ln.strip() == SPOT_HDR or ln.startswith(SPOT_HDR):
                state = 'spot'
                continue
            if ln.strip() == TGT_HDR or ln.startswith(TGT_HDR):
                state = 'tgt'
                continue
            # items inside current list
            if state == 'spot':
                item = ln.strip().rstrip(":")
                if item and (not spot or spot[-1] != item):
                    spot.append(item)
            elif state == 'tgt':
                item = ln.strip().rstrip(":")
                if item and (not tgt or tgt[-1] != item):
                    tgt.append(item)
            else:
                # ignore stray lines
                pass
        if not short:
            short = "TODO"
        if not spot:
            spot = [SPOT_DEFAULT]
        if not tgt:
            tgt = [TGT_DEFAULT]
        return {"module_id": mid or "", "short": short, "spot": spot, "tgt": tgt}

    def render_block(data: dict) -> list[str]:
        lines: list[str] = []
        lines.append(f"module_id: {data['module_id']}\n")
        lines.append(f"short_scope: {data['short']}\n")
        lines.append(SPOT_HDR + "\n")
        for it in data['spot']:
            lines.append(f"  {it}\n")
        lines.append(TGT_HDR + "\n")
        for it in data['tgt']:
            lines.append(f"  {it}\n")
        return lines

    # Iterate blocks
    for idx, m in enumerate(matches):
        start = m.start()
        end = matches[idx + 1].start() if idx + 1 < len(matches) else len(raw_text)
        block_text = raw_text[start:end]
        original_block_norm = strip_trailing_spaces(block_text)
        data = parse_block(block_text)
        rendered = render_block(data)
        # no blank lines between modules
        out_lines.extend(rendered)
        if "".join(rendered) != original_block_norm:
            if data["module_id"]:
                modules_changed.append(data["module_id"])

    normalized_text = "".join(out_lines)
    # compute line delta roughly
    lines_changed = sum(1 for a,b in zip_longest(raw_text.splitlines(True), normalized_text.splitlines(True)) if (a or "") != (b or ""))
    return normalized_text, modules_changed, lines_changed

def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("path")
    g = p.add_mutually_exclusive_group()
    g.add_argument("--check", action="store_true")
    g.add_argument("--in-place", dest="in_place", action="store_true")
    args = p.parse_args()
    mode = "check" if args.check or not args.in_place else "in_place"

    with open(args.path, "r", encoding="ascii", newline="\n") as f:
        original = f.read().splitlines(True)

    normalized, modules_changed, lines_changed = _normalize(original)

    if mode == "check":
        if modules_changed or normalized != "".join(original):
            for mid in modules_changed: print(mid)
            return 1
        return 0

    if normalized != "".join(original):
        bak = args.path + ".bak"
        if not os.path.exists(bak):
            with open(bak, "w", encoding="ascii", newline="\n") as bf:
                bf.writelines(original)
        fd, tmp = tempfile.mkstemp(dir=os.path.dirname(args.path) or ".")
        try:
            with os.fdopen(fd, "w", encoding="ascii", newline="\n") as tf:
                tf.write(normalized)
            os.replace(tmp, args.path)
        finally:
            if os.path.exists(tmp): os.unlink(tmp)
        print(f"modules_touched={len(modules_changed)}, lines_changed={lines_changed}")
    else:
        print("modules_touched=0, lines_changed=0")
    return 0

if __name__ == "__main__":
    sys.exit(main())
