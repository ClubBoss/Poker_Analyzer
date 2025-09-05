# tools/validate_content.py
import json, sys
from pathlib import Path
from spec import CONTENT_DIR, TOKENS, SIZE_TOKENS, FAMILY_TOKENS, \
                 STATIC_HINTS, DYNAMIC_HINTS, JSONL_LINE_RE, \
                 REQUIRES_CHKCHK, REQUIRES_BLOCKERS_OR_FV75, REQUIRES_SCARE, \
                 EVIDENCE_WORDS, CHKCHK_WORDS, SOFT_STATIC_TARGETS, SOFT_DYNAMIC_TARGETS

WARN, ERR = "WARN","ERR"
issues = []

def add(issue_type, path, msg, line=None):
    where = f"{path}" + (f":{line}" if line else "")
    issues.append((issue_type, where, msg))

def read_text(p: Path) -> str:
    try: return p.read_text(encoding="utf-8")
    except Exception as e:
        add(ERR, p, f"read error: {e}")
        return ""

def check_theory(p: Path):
    txt = read_text(p)
    if not txt: return
    # обязательные маркеры
    required = ["What it is","Why it matters"]
    for r in required:
        if r not in txt:
            add(WARN, p, f"missing section: {r}")
    # в теории должны фигурировать базовые семейства и 33/50/75
    for req in ["size_down_dry","size_up_wet","small_cbet_33","half_pot_50","big_bet_75"]:
        if req not in txt:
            add(WARN, p, f"missing mention: {req}")
    # запрет офф-три размеров
    bad_sizes = ["quarter","pot ","1/3 pot","2/3","66%","80%","pot-size","overbet","x pot"]
    if any(bs in txt for bs in bad_sizes):
        add(WARN, p, f"possible off-tree sizing mention found")

def each_jsonl(path: Path):
    txt = read_text(path).splitlines()
    for i, line in enumerate(txt, 1):
        if not line.strip(): continue
        if not JSONL_LINE_RE.match(line):
            add(ERR, path, "malformed JSONL line", i); continue
        try:
            yield i, json.loads(line)
        except Exception as e:
            add(ERR, path, f"json parse error: {e}", i)

def contains_any(text: str, words:set[str]) -> bool:
    low = text.lower()
    return any(w.lower() in low for w in words)

def check_demos(p: Path):
    for ln, obj in each_jsonl(p):
        for key in ("id","spot_kind","steps"):
            if key not in obj: add(ERR, p, f"missing key: {key}", ln)
        if "steps" in obj and not isinstance(obj["steps"], list):
            add(ERR, p, "steps must be list[str]", ln)
        # мягкие проверки контекста
        steps = " | ".join(obj.get("steps", []))
        if contains_any(steps, STATIC_HINTS) and contains_any(steps, SOFT_DYNAMIC_TARGETS):
            add(WARN, p, "dynamic-style target on static hints (review)", ln)
        if contains_any(steps, DYNAMIC_HINTS) and contains_any(steps, SOFT_STATIC_TARGETS):
            add(WARN, p, "static-style target on dynamic hints (review)", ln)
        # probe_turns требует chk-chk в шагах
        if "probe_turns" in steps and not contains_any(steps, CHKCHK_WORDS):
            add(WARN, p, "probe_turns without chk-chk sequence mention", ln)

def check_drills(p: Path):
    for ln, obj in each_jsonl(p):
        for key in ("id","spot_kind","question","target","rationale"):
            if key not in obj: add(ERR, p, f"missing key: {key}", ln)
        tgt = obj.get("target","")
        if tgt and tgt not in TOKENS:
            add(ERR, p, f"unknown target token: {tgt}", ln)
        q = obj.get("question","")
        rat = obj.get("rationale","")
        body = f"{q} || {rat}"

        # жёсткие гейты
        if tgt in REQUIRES_CHKCHK and not contains_any(body, CHKCHK_WORDS):
            add(WARN, p, f"'{tgt}' without chk-chk mention", ln)
        if tgt in REQUIRES_BLOCKERS_OR_FV75 and not contains_any(body, EVIDENCE_WORDS):
            add(WARN, p, f"'{tgt}' without blockers/Fv75 evidence mention", ln)
        if tgt in REQUIRES_SCARE and "scare" not in body.lower():
            add(WARN, p, f"'{tgt}' without 'scare' mention", ln)

        # мягкие рекомендации по тексту вопроса vs таргету
        if tgt in SOFT_STATIC_TARGETS and contains_any(body, DYNAMIC_HINTS):
            add(WARN, p, "static target on dynamic hints (review)", ln)
        if tgt in SOFT_DYNAMIC_TARGETS and contains_any(body, STATIC_HINTS):
            add(WARN, p, "dynamic target on static hints (review)", ln)

def main():
    for mod in CONTENT_DIR.glob("*/*"):
        if mod.name != "v1": continue
        theory = mod / "theory.md"
        demos  = mod / "demos.jsonl"
        drills = mod / "drills.jsonl"
        if theory.exists(): check_theory(theory)
        if demos.exists():  check_demos(demos)
        if drills.exists(): check_drills(drills)

    errs = [i for i in issues if i[0]==ERR]
    warns= [i for i in issues if i[0]==WARN]

    for t, where, msg in issues:
        print(f"[{t}] {where} :: {msg}")

    print(f"\nSummary: {len(errs)} errors, {len(warns)} warnings")
    sys.exit(1 if errs else 0)

if __name__ == "__main__":
    main()