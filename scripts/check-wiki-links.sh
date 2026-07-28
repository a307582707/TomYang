#!/usr/bin/env bash
# Task 62 — Wiki internal link check (read-only).
# Clones https://github.com/a307582707/TomYang.wiki.git to a temp dir (public, no token).
# Network failure → exit 0 with skip note unless WIKI_CHECK_STRICT=1.
# Fixture mode: WIKI_FIXTURE_DIR=scripts/testdata/wiki-links/good bash scripts/check-wiki-links.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO_SLUG="a307582707/TomYang"
WIKI_URL="https://github.com/${REPO_SLUG}.wiki.git"
STRICT="${WIKI_CHECK_STRICT:-0}"

skip() {
  echo "WIKI_CHECK_SKIP: $*"
  if [[ "$STRICT" == "1" ]]; then
    echo "WIKI_CHECK_STRICT=1 → treating skip as failure"
    exit 1
  fi
  exit 0
}

WIKI_DIR=""
CLEANUP=0
if [[ -n "${WIKI_FIXTURE_DIR:-}" ]]; then
  WIKI_DIR="$(cd "$WIKI_FIXTURE_DIR" && pwd)"
  echo "wiki_check_mode=fixture dir=$WIKI_DIR"
else
  WIKI_DIR="$(mktemp -d "${TMPDIR:-/tmp}/tomyang-wiki.XXXXXX")"
  CLEANUP=1
  trap '[[ "$CLEANUP" -eq 1 ]] && rm -rf "$WIKI_DIR"' EXIT
  echo "wiki_check_mode=clone url=$WIKI_URL"
  if ! git clone --depth 1 "$WIKI_URL" "$WIKI_DIR" >/tmp/wiki-clone.out 2>&1; then
    cat /tmp/wiki-clone.out || true
    skip "wiki clone failed (network or access); not failing CI"
  fi
fi

python3 - "$WIKI_DIR" "$ROOT" "$REPO_SLUG" <<'PY'
import re, sys
from pathlib import Path
from urllib.parse import unquote

wiki = Path(sys.argv[1])
repo_root = Path(sys.argv[2])
repo_slug = sys.argv[3]

link_re = re.compile(r"\[([^\]]*)\]\(([^)]+)\)")
WIKI_SUFFIXES = {".md", ".markdown", ".asciidoc", ".adoc", ".org"}

# GFM-ish: strip punctuation for ascii; keep CJK; spaces -> -
def slugify(text: str) -> str:
    t = text.strip().lower()
    t = re.sub(r"[\"'`]", "", t)
    t = re.sub(r"\s+", "-", t)
    t = re.sub(r"[^\w\u4e00-\u9fff\-]", "", t, flags=re.UNICODE)
    t = re.sub(r"-+", "-", t).strip("-")
    return t

pages = {}
for p in wiki.rglob("*"):
    if not p.is_file() or p.name.startswith("."):
        continue
    if p.suffix.lower() not in WIKI_SUFFIXES:
        continue
    key = p.stem
    pages[key] = p
    pages[key.replace(" ", "-")] = p
    pages[key.replace("-", " ")] = p
    pages[unquote(key)] = p
    pages[unquote(key).replace(" ", "-")] = p

# Known false-positive patterns (warn only; never promoted to errors)
IGNORE_WARN_SUBSTRINGS = (
    "heuristic miss for Chinese anchor",
)

errors = []
warnings = []
checked = 0
repo_path_checked = 0

heading_re = re.compile(r"^(#{1,6})\s+(.+?)\s*$", re.M)
# Ignore fenced code for link extraction (reduce false positives)
fence_re = re.compile(r"```.*?```", re.S)

repo_path_re = re.compile(
    rf"https?://github\.com/{re.escape(repo_slug)}/(tree|blob)/([^)\s#]+)",
    re.I,
)

def page_exists(name: str) -> bool:
    n = unquote(name.strip()).strip()
    candidates = {n, n.replace(" ", "-"), n.replace("-", " "), unquote(n)}
    for c in list(candidates):
        if c in pages:
            return True
    low = {k.lower(): v for k, v in pages.items()}
    return any(c.lower() in low for c in candidates)

for md in sorted({p for p in pages.values()}):
    raw = md.read_text(encoding="utf-8", errors="replace")
    text = fence_re.sub("", raw)
    headings = [m.group(2) for m in heading_re.finditer(raw)]
    anchors = {slugify(h) for h in headings}

    for m in link_re.finditer(text):
        url = m.group(2).strip()
        # skip external non-wiki, mailto, pure anchors handled below
        if url.startswith("mailto:") or url.startswith("http://") or url.startswith("https://"):
            # repo path refs
            for rm in repo_path_re.finditer(url):
                repo_path_checked += 1
                kind, rel = rm.group(1), rm.group(2)
                # strip branch prefix: main/path or master/path
                parts = rel.split("/", 1)
                if len(parts) < 2:
                    errors.append(f"{md.name}: repo ref missing path: {url}")
                    continue
                rel_path = parts[1]
                target = repo_root / rel_path
                if not target.exists():
                    errors.append(f"{md.name}: missing repo path {rel_path} (from {url})")
            # wiki site links like .../wiki/Page-Name
            wm = re.search(rf"github\.com/{re.escape(repo_slug)}/wiki/([^)#\s]+)", url, re.I)
            if wm:
                checked += 1
                raw_target = unquote(wm.group(1))
                page = raw_target.split("#")[0]
                frag = raw_target.split("#")[1] if "#" in raw_target else ""
                if not page_exists(page):
                    errors.append(f"{md.name}: missing wiki page '{page}'")
                elif frag:
                    target_page = None
                    for k, v in pages.items():
                        if k.lower() == page.lower() or k.replace(" ", "-").lower() == page.replace(" ", "-").lower():
                            target_page = v
                            break
                    if target_page:
                        th_text = target_page.read_text(encoding="utf-8", errors="replace")
                        th = {slugify(m.group(2)) for m in heading_re.finditer(th_text)}
                        if slugify(frag) not in th and frag not in th:
                            warnings.append(f"{md.name}: possible broken Chinese/anchor '#{frag}' → {page}")
            continue

        if url.startswith("#"):
            checked += 1
            frag = unquote(url[1:])
            if slugify(frag) not in anchors and frag not in anchors:
                # Chinese anchors: accept if any heading slug contains the frag chars
                if re.search(r"[\u4e00-\u9fff]", frag):
                    if not any(frag in a or a in slugify(frag) for a in anchors):
                        warnings.append(f"{md.name}: heuristic miss for Chinese anchor #{frag}")
                else:
                    warnings.append(f"{md.name}: missing local anchor #{frag}")
            continue

        # relative wiki page link: Page-Name or ./Page
        if "://" in url:
            continue
        checked += 1
        path, _, frag = url.partition("#")
        path = unquote(path.strip())
        frag = unquote(frag) if frag else ""
        if not path:
            continue
        # ignore pure file downloads outside wiki
        page = Path(path).stem if any(path.endswith(s) for s in WIKI_SUFFIXES) else path
        page = page.lstrip("./")
        if not page_exists(page):
            errors.append(f"{md.name}: missing internal page '{page}' (link {url})")
        elif frag:
            # resolve target headings
            target_page = None
            for k, v in pages.items():
                if k.lower() == page.lower() or k.replace(" ", "-").lower() == page.lower():
                    target_page = v
                    break
            if target_page:
                th_text = target_page.read_text(encoding="utf-8", errors="replace")
                th = {slugify(m.group(2)) for m in heading_re.finditer(th_text)}
                if slugify(frag) not in th and frag not in th:
                    if re.search(r"[\u4e00-\u9fff]", frag):
                        warnings.append(f"{md.name}: possible broken Chinese anchor '{page}#{frag}'")
                    else:
                        warnings.append(f"{md.name}: missing anchor '{page}#{frag}'")

print(f"wiki_pages={len(set(pages.values()))}")
print(f"wiki_links_checked={checked}")
print(f"repo_path_refs_checked={repo_path_checked}")
for w in warnings:
    if any(s in w for s in IGNORE_WARN_SUBSTRINGS):
        print(f"IGNORE {w}")
    else:
        print(f"WARN {w}")
if errors:
    print("WIKI_LINK_ERRORS: wiki internal link check failed")
    print(f"wiki_error_count={len(errors)}")
    print("ERRORS:")
    for i, e in enumerate(errors, 1):
        print(f"  [{i}] {e}")
    print("hint: fix wiki page name/anchor or add fixture under scripts/testdata/wiki-links/good/")
    sys.exit(1)
print("wiki link check ok")
PY
