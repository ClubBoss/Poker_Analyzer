# tooling/sync_dispatcher_allowlists.py
#!/usr/bin/env python3
"""
Rebuild prompts/dispatcher/_ALL.txt from SSOT, preserving real data and fixing empties.

Rules:
- Order modules exactly as in tooling/curriculum_ids.dart (SSOT).
- Keep existing short_scope if present else "TODO".
- spotkind_allowlist: keep if non-empty else ["l2_core_rules_check"].
- target_tokens_allowlist: if tooling/allowlists/target_tokens_allowlist_<id>.txt exists,
  use its non-empty, de-duplicated tokens; else keep existing if non-empty; else ["none"].
- 2-space indent for list items. LF line endings. Tabs → spaces.
- Idempotent. Supports --check and --in-place.
"""
from __future__ import annotations
import argparse, re, sys, os, pathlib, tempfile
from typing import List, Dict, Tuple

ROOT = pathlib.Path(__file__).resolve().parents[1]
DISP = ROOT / "prompts" / "dispatcher" / "_ALL.txt"
SSOT = ROOT / "tooling" / "curriculum_ids.dart"
ALLOWLIST_DIR = ROOT / "tooling" / "allowlists"

SPOT_DEFAULT = "l2_core_rules_check"
TGT_DEFAULT = "none"

ID_PATTERNS = (
    "core_", "cash_", "mtt_", "icm_", "hu_", "math_", "live_", "online_", "exploit_", "donk_", "spr_"
)
ID_EXTRAS = {
    "hand_review_and_annotation_standards",
    "review_workflow_and_study_routines",
    "database_leakfinder_playbook",
}

def read_text(p: pathlib.Path) -> str:
    return p.read_text(encoding="utf-8", errors="ignore") if p.exists() else ""

def parse_ssot_ids(ssot_text: str) -> List[str]:
    ids: List[str] = []
    seen = set()
    # захватываем строки в кавычках
    for m in re.finditer(r"""['"]([a-z0-9_]+)['"]""", ssot_text):
        t = m.group(1)
        if t.startswith(ID_PATTERNS) or t in ID_EXTRAS:
            if t not in seen:
                ids.append(t); seen.add(t)
    return ids

def parse_dispatcher(disp_text: str) -> Dict[str, dict]:
    res: Dict[str, dict] = {}
    if not disp_text.strip():
        return res
    # разрезаем на блоки по module_id
    blocks = re.split(r'(?m)^(?=module_id:\s*)', disp_text)
    for b in blocks:
        if not b.strip(): continue
        m = re.match(r'(?m)^module_id:\s*(\S+)\s*$', b)
        if not m:  # попробуем с переносом
            m = re.match(r'(?m)^module_id:\s*(\S+)\s*\n', b)
        if not m: continue
        mid = m.group(1)
        # short_scope
        ms = re.search(r'(?m)^short_scope:\s*(.*)$', b)
        short = (ms.group(1).strip() if ms else "TODO") or "TODO"
        # collect lists
        def collect(section: str) -> List[str]:
            mm = re.search(rf'(?m)^{section}\s*$([\s\S]*?)(?=^module_id:|^spotkind_allowlist:|^target_tokens_allowlist:|\Z)', b)
            out: List[str] = []
            if mm:
                for ln in mm.group(1).splitlines():
                    s = ln.replace("\t", "    ").strip()
                    if s and not s.endswith(":"):
                        if not out or out[-1] != s:
                            out.append(s)
            return out
        spot = collect("spotkind_allowlist:")
        tgt  = collect("target_tokens_allowlist:")
        res[mid] = {"short": short, "spot": spot, "tgt": tgt}
    return res

def read_target_allowlist(mid: str) -> List[str]:
    f = ALLOWLIST_DIR / f"target_tokens_allowlist_{mid}.txt"
    if not f.exists(): return []
    out: List[str] = []
    for ln in f.read_text(encoding="utf-8", errors="ignore").splitlines():
        s = ln.strip()
        if not s or s.startswith("#"): continue
        if not out or out[-1] != s:
            out.append(s)
    return out

def build_dispatcher(ids: List[str], old: Dict[str, dict]) -> str:
    lines: List[str] = []
    for mid in ids:
        prev = old.get(mid, {"short":"TODO", "spot":[], "tgt":[]})
        short = prev["short"] or "TODO"
        spot_items: List[str] = prev["spot"][:]
        tgt_items:  List[str] = prev["tgt"][:]

        if not spot_items:
            spot_items = [SPOT_DEFAULT]

        file_targets = read_target_allowlist(mid)
        if file_targets:
            tgt_items = file_targets
        elif not tgt_items:
            tgt_items = [TGT_DEFAULT]

        lines.append(f"module_id: {mid}\n")
        lines.append(f"short_scope: {short}\n")
        lines.append("spotkind_allowlist:\n")
        for it in spot_items:
            lines.append(f"  {it}\n")
        lines.append("\n")
        lines.append("target_tokens_allowlist:\n")
        for it in tgt_items:
            lines.append(f"  {it}\n")
        lines.append("\n")
    return "".join(lines)

def normalize_lf(s: str) -> str:
    return s.replace("\r\n", "\n").replace("\r", "\n")

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("path", nargs="?", default=str(DISP))
    g = ap.add_mutually_exclusive_group()
    g.add_argument("--check", action="store_true")
    g.add_argument("--in-place", dest="in_place", action="store_true")
    args = ap.parse_args()

    disp_path = pathlib.Path(args.path)
    ssot_text = read_text(SSOT)
    ids = parse_ssot_ids(ssot_text)
    if not ids:
        print("ERROR: no module ids parsed from SSOT", file=sys.stderr)
        return 2

    old = parse_dispatcher(read_text(disp_path))
    new_text = normalize_lf(build_dispatcher(ids, old))

    if args.in_place:
        if not disp_path.parent.exists():
            disp_path.parent.mkdir(parents=True, exist_ok=True)
        # атомарная запись
        fd, tmp = tempfile.mkstemp(dir=str(disp_path.parent))
        os.close(fd)
        pathlib.Path(tmp).write_text(new_text, encoding="utf-8", newline="\n")
        os.replace(tmp, disp_path)
        print(f"dispatcher rebuilt: modules={len(ids)} (from SSOT)")
        return 0
    else:
        # check mode: diff by length only to be concise
        cur = read_text(disp_path)
        changed = normalize_lf(cur) != new_text
        print("CHANGED" if changed else "OK")
        return 1 if changed else 0

if __name__ == "__main__":
    sys.exit(main())