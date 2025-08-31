#!/usr/bin/env bash
set -euo pipefail
infile="${1:?usage: bin/apply_gen.sh <gen.txt>}"

awk '
function dir_of(p,  i){ i=length(p); while(i>0 && substr(p,i,1)!="/") i--; return (i>1)? substr(p,1,i-1) : "." }
BEGIN{ inblock=0; path="" }
{ sub(/\r$/,"") }  # CRLF -> LF

# Заголовок: content/…/…/file
$0 ~ /^content\/[A-Za-z0-9_\/.-]+$/ {
  # закрыть предыдущий блок (если был)
  inblock=0; path=""
  path=$0
  dir=dir_of(path)
  system("mkdir -p \"" dir "\"")
  system(": > \"" path "\"")   # truncate
  inblock=1
  next
}

# Внутри блока: игнорируем любые строки с ```
inblock && $0 ~ /^[[:space:]]*```/ { next }

# Пишем контент
inblock { print $0 >> path; next }

END{
  if (inblock && path=="") { print "ERROR: parsing ended unexpectedly" > "/dev/stderr"; exit 2 }
}
' "$infile"
