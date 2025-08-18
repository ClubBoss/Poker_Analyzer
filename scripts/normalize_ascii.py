import sys, pathlib

FILES = list(pathlib.Path("docs/_archive").rglob("*.md"))

MAP = {
    "\u2018": "'", "\u2019": "'", "\u201A": "'", "\u201B": "'",
    "\u201C": '"', "\u201D": '"', "\u201E": '"',
    "\u2013": "-",  # en dash
    "\u2014": "-",  # em dash
    "\u2212": "-",  # minus
    "\u2026": "...",  # ellipsis
    "\u00A0": " ",  # no-break space
    "\u2009": " ", "\u200A": " ", "\u200B": "",  # thin / hair / zero-width
}

def normalize_text(s: str) -> str:
    return "".join(MAP.get(ch, ch) for ch in s)

changed = False
for p in FILES:
    text = p.read_text(encoding="utf-8", errors="ignore")
    new  = normalize_text(text)
    if new != text:
        p.write_text(new, encoding="utf-8")
        print(f"normalized: {p}")
        changed = True

sys.exit(0)
