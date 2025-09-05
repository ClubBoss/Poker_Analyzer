#!/usr/bin/env python3
from pathlib import Path
NEED = ["size_down_dry","size_up_wet","small_cbet_33","half_pot_50","big_bet_75"]
for md in Path("content").glob("**/v1/theory.md"):
    txt = md.read_text(encoding="utf-8")
    if not all(k in txt for k in NEED):
        txt = txt.rstrip()+"\n\n_This module uses the fixed families and sizes: size_down_dry, size_up_wet; small_cbet_33, half_pot_50, big_bet_75._\n"
        md.write_text(txt, encoding="utf-8")
        print(f"[MENTIONS] {md}")
