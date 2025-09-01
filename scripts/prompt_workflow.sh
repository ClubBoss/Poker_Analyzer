#!/usr/bin/env bash
set -euo pipefail

# --- helpers ---------------------------------------------------------------

need() {
  command -v "$1" >/dev/null 2>&1 || { echo "missing: $1" >&2; return 127; }
}

soft_need() {
  command -v "$1" >/dev/null 2>&1
}

clip_in() {
  # stdin -> clipboard (best-effort)
  if soft_need pbcopy; then
    pbcopy
    return 0
  elif soft_need xclip; then
    xclip -selection clipboard
    return 0
  elif soft_need xsel; then
    xsel --clipboard --input
    return 0
  else
    # no clipboard tool; just pass-through
    cat >/dev/null
    echo "clipboard tool not found; skipped copying" >&2
    return 0
  fi
}

ensure_file_dir() {
  local p="$1"; mkdir -p "$(dirname "$p")"
}

# --- your functions, hardened ---------------------------------------------

# ensure dispatcher block for MODULE
ensure_dispatcher_block() {
  local m="$1" disp="prompts/dispatcher/_ALL.txt"
  ensure_file_dir "$disp"
  touch "$disp"
  if grep -q "^module_id: ${m}$" "$disp"; then return 0; fi
  cat >> "$disp" <<EOF
module_id: ${m}
short_scope: TODO short scope
spotkind_allowlist:
l2_core_rules_check
target_tokens_allowlist:
none
EOF
}

# sync target allowlist from drills -> dispatcher
sync_allowlist_into_dispatcher() {
  local m="$1" drills="content/${m}/v1/drills.jsonl" dst="tooling/allowlists/target_tokens_allowlist_${m}.txt" disp="prompts/dispatcher/_ALL.txt"
  ensure_file_dir "$dst"
  ensure_file_dir "$disp"
  touch "$disp"
  if [ -f "$drills" ]; then
    if soft_need perl; then
      perl -ne 'print "$1\n" if /"target"\s*:\s*"([^"]+)"/' "$drills" | LC_ALL=C sort -u > "$dst" || echo none > "$dst"
    else
      echo "perl not found; writing 'none' into $dst" >&2
      echo none > "$dst"
    fi
  else
    echo none > "$dst"
  fi
  awk 'NF' "$dst" | LC_ALL=C sort -u > "$dst.tmp" && mv "$dst.tmp" "$dst"

  if soft_need perl; then
    ID="$m" DST="$dst" perl -0777 -pe '
      BEGIN { $/ = undef }
      my $id  = $ENV{ID}; my $dst = $ENV{DST};
      open my $fh, "<", $dst or die "$dst: $!";
      my $t = do { local $/; <$fh> };
      $t =~ s/\r//g; $t =~ s/^\s+|\s+$//g; $t =~ s/\n+/\n/g;
      s{(^module_id:\s*\Q$id\E[\s\S]*?target_tokens_allowlist:\s*)(?:[\s\S]*?)(?=(?:\nmodule_id:|\z))}
       {$1 . $t . "\n"}egm;
    ' "$disp" > /tmp/_disp.$$ && mv /tmp/_disp.$$ "$disp"
  else
    echo "perl not found; dispatcher allowlist not injected" >&2
  fi
}

# force spotkind_allowlist to two-line form with default kind
normalize_spotkind() {
  local m="$1" disp="prompts/dispatcher/_ALL.txt"
  touch "$disp"
  if soft_need perl; then
    perl -0777 -pe "s/(module_id:\\s*${m}[\\s\\S]*?spotkind_allowlist:)[ \\t]*l2_core_rules_check\\s*/\\1\nl2_core_rules_check\n/s" "$disp" > /tmp/_disp.$$ && mv /tmp/_disp.$$ "$disp"
    perl -0777 -pe "s/(module_id:\\s*${m}[\\s\\S]*?^spotkind_allowlist:\\s*$)/\\1\nl2_core_rules_check/m" "$disp" > /tmp/_disp.$$ && mv /tmp/_disp.$$ "$disp"
  else
    echo "perl not found; normalize_spotkind skipped" >&2
  fi
}

# compose prompt safely and copy
compose_prompt_copy() {
  local m="$1" tmp err
  need dart || { echo "Install Dart SDK to use compose_prompt_copy" >&2; return 1; }
  tmp="$(mktemp)"; err="$(mktemp)"
  if ! dart run tooling/compose_prompt_for_id.dart --id "$m" >"$tmp" 2>"$err"; then
    echo "compose failed:" >&2
    head -20 "$err" >&2 || true
    rm -f "$tmp" "$err"
    return 1
  fi
  cat "$tmp" | clip_in
  mv "$tmp" "/tmp/${m}.prompt"; rm -f "$err"
  echo "PROMPT READY -> /tmp/${m}.prompt"
}

# split model output from /tmp/MODULE.out into files
split_generated() {
  local m="$1" out="/tmp/${m}.out"
  [ -f "$out" ] || { echo "missing: $out" >&2; return 1; }
  mkdir -p "content/${m}/v1"
  awk -v m="${m}" '
    BEGIN{inblk=0;file=""}
    /^content\/.*\/theory\.md/    {file="content/" m "/v1/theory.md";    next}
    /^content\/.*\/demos\.jsonl/  {file="content/" m "/v1/demos.jsonl";  next}
    /^content\/.*\/drills\.jsonl/ {file="content/" m "/v1/drills.jsonl"; next}
    /^```/ {inblk=!inblk; next}
    { if(inblk && file!=""){ print $0 > file } }
  ' "$out"
  # tidy whitespace if files exist
  if ls content/${m}/v1/{theory.md,demos.jsonl,drills.jsonl} >/dev/null 2>&1; then
    if soft_need perl; then
      perl -pi -e 's/\r$//; s/[ \t]+$//' content/${m}/v1/{theory.md,demos.jsonl,drills.jsonl} 2>/dev/null || true
    fi
  else
    echo "no fenced code blocks found in $out" >&2
    return 1
  fi
}

# rebuild research/_ALL.prompts.txt block
rebuild_research_prompts_block() {
  local m="$1" prompts="prompts/research/_ALL.prompts.txt" tmp err
  need dart || { echo "Install Dart SDK to use rebuild_research_prompts_block" >&2; return 1; }
  ensure_file_dir "$prompts"; touch "$prompts"
  tmp="$(mktemp)"; err="$(mktemp)"
  if ! dart run tooling/compose_prompt_for_id.dart --id "$m" >"$tmp" 2>"$err"; then
    echo "compose failed:" >&2
    head -20 "$err" >&2 || true
    rm -f "$tmp" "$err"
    return 1
  fi
  awk -v id="$m" 'BEGIN{skip=0} /^GO MODULE:/{ if ($0 ~ "GO MODULE: " id "$"){skip=1; next} if (skip){skip=0}} !skip{print}' "$prompts" > /tmp/_all.prompts.clean.$$
  { cat /tmp/_all.prompts.clean.$$; printf 'GO MODULE: %s\n\n' "$m"; cat "$tmp"; printf '\n'; } > "$prompts"
  rm -f "$tmp" "$err" /tmp/_all.prompts.clean.$$
}

# mark module done
mark_done() {
  local m="$1"
  need python3 || { echo "python3 required for mark_done" >&2; return 1; }
  python3 - <<PY
import json,io,os,sys
p="curriculum_status.json"; m="${m}"
try:
  d=json.load(open(p,encoding="utf-8"))
except Exception:
  d={"schema":1,"modules_done":[]}
mods=d.get("modules_done",[])
if m not in mods: mods.append(m)
d["modules_done"]=mods
io.open(p,"w",encoding="utf-8").write(json.dumps(d,indent=2,ensure_ascii=False)+"\n")
PY
}

# --- CLI entrypoint --------------------------------------------------------

usage() {
  cat >&2 <<'U'
Usage:
  scripts/prompt_workflow.sh <module_id> <cmd>

Commands:
  ensure        -> ensure_dispatcher_block + normalize_spotkind
  sync          -> sync_allowlist_into_dispatcher
  compose       -> compose_prompt_copy
  split         -> split_generated
  research      -> rebuild_research_prompts_block
  done          -> mark_done
U
}

main() {
  local m="${1:-}"; local cmd="${2:-}"
  [ -n "${m}" ] && [ -n "${cmd}" ] || { usage; exit 2; }
  case "$cmd" in
    ensure)   ensure_dispatcher_block "$m"; normalize_spotkind "$m" ;;
    sync)     sync_allowlist_into_dispatcher "$m" ;;
    compose)  compose_prompt_copy "$m" ;;
    split)    split_generated "$m" ;;
    research) rebuild_research_prompts_block "$m" ;;
    done)     mark_done "$m" ;;
    *) usage; exit 2 ;;
  esac
}

# run only when executed, not when sourced
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  main "$@"
fi
