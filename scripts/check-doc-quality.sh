#!/usr/bin/env bash
# Markdown quality heuristics — warn by default; DOC_QUALITY_STRICT=1 to fail.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
python3 - <<'PY'
import os, re, sys
from pathlib import Path
strict=os.environ.get('DOC_QUALITY_STRICT')=='1'
issues=[]
md_files=list(Path('.').glob('*.md'))+list(Path('docs').rglob('*.md'))+list(Path('examples').rglob('*.md'))
for p in md_files:
  if 'testdata' in p.parts: continue
  text=p.read_text(encoding='utf-8', errors='replace')
  lines=text.splitlines()
  h1=[i for i,l in enumerate(lines) if re.match(r'^# ', l)]
  if len(h1)>1:
    issues.append(f'{p}: multiple H1 ({len(h1)})')
  # fenced blocks without language
  fences=[i for i,l in enumerate(lines) if l.strip().startswith('```')]
  for idx in range(0,len(fences),2):
    open_line=lines[fences[idx]].strip()
    if open_line=='```':
      issues.append(f'{p}:{fences[idx]+1}: code fence missing language')
  # bare github raw-ish http links without markdown - informational
  for i,l in enumerate(lines,1):
    if re.search(r'(?<!\()https?://\S+', l) and not re.search(r'\[.*\]\(https?://', l):
      if 'http' in l and '[' not in l:
        issues.append(f'{p}:{i}: possible bare URL')
print(f'doc_quality_findings={len(issues)}')
for x in issues[:80]:
  print(x)
if strict and issues:
  sys.exit(1)
print('doc quality check done (warn-only unless DOC_QUALITY_STRICT=1)')
PY
