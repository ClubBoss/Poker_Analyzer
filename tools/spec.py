# tools/spec.py
from pathlib import Path
import re

REPO_ROOT = Path(__file__).resolve().parents[1]
CONTENT_DIR = REPO_ROOT / "content"

TOKENS = {
    # preflop ladders
    "3bet_ip_9bb","3bet_oop_12bb","4bet_ip_21bb","4bet_oop_24bb",
    # postflop sizes
    "small_cbet_33","half_pot_50","big_bet_75",
    # families/labels
    "size_up_wet","size_down_dry",
    # concepts / actions
    "protect_check_range","delay_turn","probe_turns",
    "double_barrel_good","triple_barrel_scare",
    "call","fold","overfold_exploit",
}
SIZE_TOKENS = {"small_cbet_33","half_pot_50","big_bet_75"}
FAMILY_TOKENS = {"size_up_wet","size_down_dry"}

# Heuristics: текстовые якоря, чтобы проверять «логичность» таргета
STATIC_HINTS = {"static","A83r","K72r","Q84r","K74r"}
DYNAMIC_HINTS = {"dynamic","wet","JT9ss","T98ss","986ss","JT9s","975ss","986s"}

# простой JSONL валидатор
JSONL_LINE_RE = re.compile(r"^\s*\{.*\}\s*$")

# «гейт» для корректности упоминаний перед таргетами
REQUIRES_CHKCHK = {"probe_turns"}
REQUIRES_BLOCKERS_OR_FV75 = {"big_bet_75","double_barrel_good","triple_barrel_scare","call"}
REQUIRES_SCARE = {"triple_barrel_scare"}

# что считать «доказательством»
EVIDENCE_WORDS = {"blocker","blockers","Fv75","Fv50","evidence","spike","nut","top blocker","nut blocker"}
CHKCHK_WORDS = {"chk-chk","chk–chk","check-check","check—check"}

# мягкие рекомендации по связке «таргет ↔ контекст»
SOFT_STATIC_TARGETS = {"small_cbet_33","size_down_dry"}
SOFT_DYNAMIC_TARGETS = {"half_pot_50","size_up_wet","big_bet_75","double_barrel_good","triple_barrel_scare"}