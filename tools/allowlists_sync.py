#!/usr/bin/env python3
import sys, json, pathlib
from typing import List

ROOT = pathlib.Path(".")
CONTENT = ROOT / "content"
ALLOWDIR = ROOT / "tooling" / "allowlists"

# Allow importing sibling tools without making tools/ a package
if str((ROOT / "tools").resolve()) not in sys.path:
    sys.path.append(str((ROOT / "tools").resolve()))
try:
    import jsonl_guard  # type: ignore
except Exception:
    jsonl_guard = None  # Fallback: still run, but parsing errors will be surfaced below

def is_ascii(s: str) -> bool:
    try:
        s.encode("ascii")
        return True
    except:
        return False

def collect_targets(drills_path: pathlib.Path):
    out = []
    for idx, ln in enumerate(drills_path.read_text(encoding="utf-8").splitlines(), start=1):
        ln = ln.strip()
        if not ln:
            continue
        try:
            obj = json.loads(ln)
        except json.JSONDecodeError as e:
            col = getattr(e, "colno", 1) or 1
            # Mirror guard message style
            caret = " " * (col - 1) + "^"
            msg = f"BAD {drills_path}:{idx}:{col} -> {e.msg}\n{ln}\n{caret}"
            print(msg)
            sys.exit(1)
        t = obj.get("target","")
        if t:
            out.append(t)
    return sorted(set(out))

def sync(mode: str) -> int:
    errors = []
    # Validate drills with the JSONL guard first (auto-fix by default)
    drill_files: List[str] = [str(p) for p in CONTENT.glob("*/v1/drills.jsonl")]
    if jsonl_guard is not None and drill_files:
        rc = jsonl_guard.validate_paths(drill_files, fix=True)
        if rc != 0:
            return rc
    for drills in CONTENT.glob("*/v1/drills.jsonl"):
        module = drills.parts[1]  # content/<module>/v1/...
        targets = collect_targets(drills)
        if not targets:
            errors.append(f"[no-targets] content/{module}/v1/drills.jsonl")
            continue
        ALLOWDIR.mkdir(parents=True, exist_ok=True)
        allow = ALLOWDIR / f"target_tokens_allowlist_{module}.txt"
        want = "\n".join(targets) + "\n"
        have = allow.read_text(encoding="utf-8") if allow.exists() else ""
        if not is_ascii(want):
            errors.append(f"[non-ascii] {allow}")
        if mode == "--check":
            if want != have:
                errors.append(f"[outdated] {allow} (run tools/allowlists_sync.py --write)")
        else:
            allow.write_text(want, encoding="utf-8")
    if mode == "--check" and errors:
        print("\n".join(errors))
        return 1
    return 0

if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "--check"
    if mode not in ("--check","--write"):
        print("usage: tools/allowlists_sync.py [--check|--write]"); sys.exit(2)
    sys.exit(sync(mode))
