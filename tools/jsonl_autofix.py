# tools/jsonl_autofix.py
import re, json, glob, pathlib

def fix_line(s:str)->str:
    # normalize quotes
    s = s.replace("“","\"").replace("”","\"").replace("„","\"")
    s = s.replace("’","'").replace("‘","'")
    # remove trailing commas before } ]
    s = re.sub(r',\s*([}\]])', r'\1', s)
    # single-quoted KEYS -> double
    s = re.sub(r"(?P<prefix>[{,\s])'([A-Za-z0-9_]+)'\s*:", r'\g<prefix>"\2":', s)
    # single-quoted string VALUES -> double (keeps escapes)
    s = re.sub(r':\s*\'([^\'\\]*(?:\\.[^\'\\]*)*)\'', r': "\1"', s)
    # Python literals -> JSON
    s = re.sub(r'\bTrue\b', 'true', s)
    s = re.sub(r'\bFalse\b', 'false', s)
    s = re.sub(r'\bNone\b', 'null', s)
    return s

def try_json(s):
    try: json.loads(s); return True
    except: return False

changed=0; still_bad=[]
for p in glob.glob('content/**/d*.jsonl', recursive=True):
    path=pathlib.Path(p)
    lines=path.read_text(encoding='utf-8').splitlines()
    out=[]
    for i,ln in enumerate(lines,1):
        s=ln.rstrip('\n')
        if not s.strip():
            out.append(s); continue
        if try_json(s):
            out.append(s); continue
        s2 = fix_line(s)
        if s2!=s and try_json(s2):
            out.append(s2); changed+=1
        else:
            out.append(s2); still_bad.append((p,i,s2))
    path.write_text('\n'.join(out)+'\n', encoding='utf-8')

print(f'patched: {changed} lines')
if still_bad:
    print('\nSTILL BAD:')
    for p,i,s in still_bad:
        print(f'{p}:{i}\n{s}\n')
