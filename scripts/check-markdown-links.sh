#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
python3 - <<'PY'
import re, sys
from pathlib import Path
root=Path('.')
# Check relative markdown links that look like local files
link_re=re.compile(r'\[([^\]]+)\]\(([^)]+)\)')
missing=[]
checked=0
for md in list(root.glob('*.md'))+list((root/'docs').rglob('*.md'))+list((root/'wiki').rglob('*.md')):
    text=md.read_text(encoding='utf-8', errors='replace')
    for m in link_re.finditer(text):
        url=m.group(2).strip()
        if url.startswith('http') or url.startswith('#') or url.startswith('mailto:'):
            continue
        if 'github.com' in url:
            continue
        path=url.split('#')[0]
        if not path:
            continue
        checked+=1
        target=(md.parent/path).resolve()
        try:
            target.relative_to(root.resolve())
        except ValueError:
            continue
        if not target.exists():
            missing.append(f"{md}: broken local link {url}")
print(f"local_md_links_checked={checked}")
if missing:
    print('\n'.join(missing)); sys.exit(1)
print('markdown local links ok')
PY
