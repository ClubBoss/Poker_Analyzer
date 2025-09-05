# tools/autofix_content.py
from pathlib import Path
import re
from spec import CONTENT_DIR

REPLACERS = [
    # нормализация chk–chk / check—check → chk-chk
    (re.compile(r"chk[\-–—]chk|check[\-–—]check", re.I), "chk-chk"),
    # Fv75 / Fv 75 / FV75 → Fv75
    (re.compile(r"\bF\s*V\s*75\b", re.I), "Fv75"),
    (re.compile(r"\bF\s*V\s*50\b", re.I), "Fv50"),
    # пробелы/дефисы
    (re.compile(r"\bturn\s*probe\b", re.I), "probe_turns"),
    # частые опечатки токенов
    (re.compile(r"\bsize-?down-?dry\b", re.I), "size_down_dry"),
    (re.compile(r"\bsize-?up-?wet\b", re.I), "size_up_wet"),
    (re.compile(r"\bsmall[\s_]?cbet[\s_]?33\b", re.I), "small_cbet_33"),
    (re.compile(r"\bhalf[\s_]?pot[\s_]?50\b", re.I), "half_pot_50"),
    (re.compile(r"\bbig[\s_]?bet[\s_]?75\b", re.I), "big_bet_75"),
]

def fix_file(p: Path):
    s = p.read_text(encoding="utf-8")
    orig = s
    for pat, repl in REPLACERS:
        s = pat.sub(repl, s)
    if s != orig:
        p.write_text(s, encoding="utf-8")
        return True
    return False

def main():
    changed = 0
    for mod in CONTENT_DIR.glob("*/*"):
        if mod.name != "v1": continue
        for f in (mod/"theory.md", mod/"demos.jsonl", mod/"drills.jsonl"):
            if f.exists() and fix_file(f):
                print(f"[fixed] {f}")
                changed += 1
    print(f"\nAutofix done. Files changed: {changed}")

if __name__ == "__main__":
    main()