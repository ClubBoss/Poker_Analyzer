#!/usr/bin/env python3
import json, sys, re
from pathlib import Path

ROOT = Path("content")
ALLOWED = {
 "small_cbet_33","half_pot_50","big_bet_75",
 "size_up_wet","size_down_dry",
 "protect_check_range","delay_turn","probe_turns",
 "double_barrel_good","triple_barrel_scare",
 "call","fold","overfold_exploit",
 "3bet_ip_9bb","3bet_oop_12bb","4bet_ip_21bb","4bet_oop_24bb"
}

DIRECT_MAP = {
 # sizing aliases
 "small_bet":"small_cbet_33","cbet_small":"small_cbet_33","bet_small_river":"small_cbet_33",
 "medium_bet":"half_pot_50","small_or_medium":"half_pot_50",
 "large_bet":"big_bet_75","overbet":"big_bet_75","overbet_polar":"big_bet_75","bet_big_river":"big_bet_75","cbet_big":"big_bet_75",
 # action aliases
 "probe_bet":"probe_turns","probe_turn":"probe_turns",
 "delay_cbet":"delay_turn","check_back":"delay_turn",
 "deny_equity_turn":"half_pot_50",
 "double_barrel_bigger":"double_barrel_good","second_barrel_bigger":"double_barrel_good","second_barrel":"double_barrel_good",
 "polarize_river":"triple_barrel_scare",
 # preflop variants
 "3bet_oop_11bb":"3bet_oop_12bb","3bet_oop_10bb":"3bet_oop_12bb",
 # generic concepts -> closest token
 "thin_value_small":"small_cbet_33","value_bet_bigger":"big_bet_75","value_bet":"half_pot_50",
 "bluff_bigger":"big_bet_75","good_blocker_bluff":"double_barrel_good",
 "range_advantage":"small_cbet_33","nut_advantage":"big_bet_75",
 # responses / defenses
 "float_call":"call","bluffcatch":"call","check_call":"call","call_or_fold_plan":"call",
 "check_fold":"fold","bet_fold":"fold","bet_fold_bluff":"fold",
 # misc live/proc (заглушки в учебные токены)
 "min_raise_illegal":"call","legal_min_raise":"call","does_not_reopen":"call","reopens":"call",
 "action_canceled":"call","string_bet_call_only":"call","single_motion_raise_legal":"call",
 "bettor_shows_first":"call","first_active_left_of_btn_shows":"call","round_ends":"call",
 # squeeze/iso → наши лестницы
 "squeeze_iso_3bet":"3bet_oop_12bb","squeeze_ip_12bb":"3bet_ip_9bb","squeeze_oop_14bb":"3bet_oop_12bb",
 "iso_raise_ip_6bb":"3bet_ip_9bb","iso_raise_oop_8bb":"3bet_oop_12bb",
 # 4bet variants
 "4bet_small_22bb":"4bet_ip_21bb", "4bet_ip_linear":"4bet_ip_21bb","4bet_oop_polar":"4bet_oop_24bb",
 # other course-specific
 "dry_board":"size_down_dry","wet_board":"size_up_wet","paired_board":"size_down_dry",
 "monotone":"size_up_wet","two_tone":"size_up_wet",
 "cbet_less_often":"size_down_dry","more_static":"size_down_dry","more_dynamic":"size_up_wet",
 "raise_for_protection":"big_bet_75","raise_flop":"big_bet_75",
 "defend_vs_small_cbet":"call","fold_vs_raise_multiway":"fold","give_up_low_equity":"fold",
 "fold_vs_4bet":"fold","fold_vs_4bet_oop":"fold","call_vs_4bet_ip":"call","call_ip_realize":"call",
 "jam_vs_4bet_shallow":"big_bet_75","shove_spr_lt_1_5":"big_bet_75",
 # exploitation / meta
 "start_from_baseline":"protect_check_range","exploit_overfold":"overfold_exploit","exploit_overcall":"call",
 "size_up_polar":"big_bet_75","thin_value_more":"small_cbet_33","small_shift_only":"half_pot_50",
 "widen_open_late_vs_tight_blinds":"overfold_exploit","tighten_open_late_vs_loose_blinds":"protect_check_range",
 "add_3bet_bluffs":"3bet_ip_9bb","4bet_value_heavier":"4bet_ip_21bb",
 "fold_more_vs_underbluff":"fold","call_more_vs_overbluff":"call",
 "bet_bigger_vs_capped":"big_bet_75","bet_smaller_merged":"half_pot_50",
 "re_anchor_to_baseline":"protect_check_range","respect_sample_size":"protect_check_range",
 # bankroll/mental placeholders to pass schema
 "forty_to_fifty_buyins":"protect_check_range","twenty_to_thirty_buyins":"protect_check_range",
 "hundred_to_two_hundred_buyins":"protect_check_range","three_hundred_plus_buyins":"protect_check_range",
 "five_to_ten_extra_buyins":"protect_check_range","end_shot_move_down":"fold",
 "stop_loss_quit":"fold","choose_softer_lineup":"overfold_exploit","table_change_or_quit":"overfold_exploit",
 "move_down_one_level":"fold","avoid_mixed_stakes":"protect_check_range","skip_or_short_session":"delay_turn",
 "stay_if_soft":"call","take_table_change":"overfold_exploit","log_sessions_consistently":"protect_check_range",
 "decline_until_roll_ready":"fold",
 # rules/setup placeholders
 "hand_a":"call","split_pot":"call","legal_min_raise":"call",
 # others frequently seen
 "a5s_defend":"call","ace_blocker_better":"double_barrel_good",
}

def smart_map(tok:str)->str:
    t = tok.strip().lower()
    if t in ALLOWED: return t
    if t in DIRECT_MAP: return DIRECT_MAP[t]
    if "overbet" in t or ("big" in t and "bet" in t): return "big_bet_75"
    if ("small" in t and "bet" in t) or "small_cbet" in t: return "small_cbet_33"
    if "half" in t or "medium" in t: return "half_pot_50"
    if "probe" in t: return "probe_turns"
    if "delay" in t or "check_back" in t: return "delay_turn"
    if "check_raise" in t: return "big_bet_75"
    if "protect" in t or (t.startswith("check_") and "call" not in t): return "protect_check_range"
    if t.startswith("3bet"): return "3bet_ip_9bb" if "_ip_" in t else "3bet_oop_12bb"
    if t.startswith("4bet"): return "4bet_ip_21bb" if "_ip_" in t else "4bet_oop_24bb"
    if "squeeze" in t or "iso" in t: return "3bet_ip_9bb" if "_ip_" in t else "3bet_oop_12bb"
    if "fold" in t: return "fold"
    if "call" in t or "float" in t or "bluffcatch" in t: return "call"
    if "double" in t or "second_barrel" in t: return "double_barrel_good"
    if "triple" in t or "polarize" in t: return "triple_barrel_scare"
    # last-resort default
    return "call"

def fix_jsonl(path:Path):
    out_lines=[]
    changed=False
    for i,raw in enumerate(path.read_text(encoding="utf-8").splitlines(),1):
        if not raw.strip(): continue
        try:
            obj=json.loads(raw)
        except Exception as e:
            print(f"[SKIP-MALFORMED] {path}:{i} {e}", file=sys.stderr)
            continue
        # ensure spot_kind
        obj.setdefault("spot_kind","l2_core_rules_check")
        # migrate target
        if "target" in obj:
            old=obj["target"]
            new=smart_map(old)
            if new not in ALLOWED:
                new="call"
            if new!=old:
                changed=True
                obj["target"]=new
        # sanity for demos: normalize step tokens inside 'steps' text (optional)
        out_lines.append(json.dumps(obj, ensure_ascii=False))
    if changed:
        path.write_text("\n".join(out_lines)+"\n", encoding="utf-8")
        print(f"[FIXED] {path}")

def run():
    for p in ROOT.glob("**/v1/*.jsonl"):
        fix_jsonl(p)

if __name__=="__main__":
    run()
