#!/usr/bin/env bash
# Task 89 — Validate docs/MAINTENANCE.md ledger freshness and archived-path notes.
# Usage:
#   bash scripts/check-maintenance-ledger.sh           # human-readable; exit 1 on hard failures
#   bash scripts/check-maintenance-ledger.sh --json    # machine-readable summary (stdout)
# Env:
#   MAINTENANCE_LEDGER_FILE — override ledger path (default docs/MAINTENANCE.md)
#   MAINTENANCE_LEDGER_STRICT_ISSUES=1 — fail if 高风险 rows lack #NN tracking reference
#   TODAY — override date YYYY-MM-DD (tests)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

LEDGER="${MAINTENANCE_LEDGER_FILE:-docs/MAINTENANCE.md}"
JSON=0
if [[ "${1:-}" == "--json" ]]; then
  JSON=1
fi

if [[ ! -f "$LEDGER" ]]; then
  echo "missing ledger: $LEDGER" >&2
  exit 1
fi

python3 - "$LEDGER" "$JSON" <<'PY'
import json, re, sys
from datetime import date, datetime
from pathlib import Path

ledger_path = Path(sys.argv[1])
json_mode = sys.argv[2] == "1"
text = ledger_path.read_text(encoding="utf-8")
today_s = __import__("os").environ.get("TODAY") or date.today().isoformat()
today = date.fromisoformat(today_s)

findings = {"ok": True, "ledger": str(ledger_path), "as_of": today_s, "checks": []}

def add(severity, code, message, detail=None):
    entry = {"severity": severity, "code": code, "message": message}
    if detail is not None:
        entry["detail"] = detail
    findings["checks"].append(entry)
    if severity in ("fail", "error"):
        findings["ok"] = False

# --- Global next review ---
m = re.search(r"\*\*下次统一复查:\*\*\s*(\d{4}-\d{2}-\d{2})", text)
if not m:
    add("fail", "missing_global_review_date", "MAINTENANCE.md missing **下次统一复查:** YYYY-MM-DD")
    global_next = None
else:
    global_next = date.fromisoformat(m.group(1))
    if global_next < today:
        add("fail", "global_review_overdue", f"Global next review overdue: {global_next} < {today}")
    else:
        add("ok", "global_review_scheduled", f"Global next review: {global_next}")

# --- Component table ---
table_start = text.find("## 2. 组件台账")
if table_start < 0:
    add("fail", "missing_component_table", "Section ## 2. 组件台账 not found")
    rows = []
else:
    section = text[table_start:]
    lines = section.splitlines()
    rows = []
    for line in lines:
        if not line.startswith("|") or line.startswith("|------") or "组件 |" in line:
            continue
        parts = [p.strip() for p in line.strip("|").split("|")]
        if len(parts) >= 8 and parts[0] != "组件":
            rows.append(parts)

archived_markers = (
    "k8s/archived/",
    "ExtraAddons/efk",
    "ExtraAddons/dashboard",
    "ExtraAddons/WeaveScope",
    "addons/metrics-server",
    "addons/Kubedns",
    "addons/kube-dns",
)

overdue_components = []
archived_without_note = []
high_risk_no_issue = []

for parts in rows:
    component = parts[0]
    current_ver = parts[1] if len(parts) > 1 else ""
    risk = parts[4] if len(parts) > 4 else ""
    next_review = parts[7] if len(parts) > 7 else ""
    migration = parts[8] if len(parts) > 8 else ""
    row_blob = " | ".join(parts)

    if re.fullmatch(r"\d{4}-\d{2}-\d{2}", next_review):
        nr = date.fromisoformat(next_review)
        if nr < today:
            overdue_components.append({"component": component, "next_review": next_review})

    for marker in archived_markers:
        if marker in row_blob:
            if not any(k in row_blob for k in ("归档", "禁止", "已迁")):
                archived_without_note.append({"component": component, "marker": marker})
            break

    if risk == "高":
        has_issue = bool(re.search(r"#\d+", row_blob))
        is_archived_forbidden = "禁止" in migration or "禁止" in row_blob or "k8s/archived/" in current_ver
        if not has_issue and not is_archived_forbidden:
            high_risk_no_issue.append({"component": component, "risk": risk})

if overdue_components:
    add("fail", "component_review_overdue", "One or more components past next review date", overdue_components)
else:
    add("ok", "component_reviews_current", "No component next-review dates overdue")

if archived_without_note:
    add("fail", "archived_path_without_note", "Archived path references missing 归档/禁止 note", archived_without_note)
else:
    add("ok", "archived_paths_annotated", "Archived path references include archival notes")

strict_issues = __import__("os").environ.get("MAINTENANCE_LEDGER_STRICT_ISSUES") == "1"
if high_risk_no_issue:
    sev = "fail" if strict_issues else "warn"
    add(sev, "high_risk_missing_issue", "High-risk rows without #NN tracking reference (consider GitHub Issue)", high_risk_no_issue)
else:
    add("ok", "high_risk_tracked", "High-risk rows have issue ref or archived-forbidden note")

findings["summary"] = {
    "global_next_review": global_next.isoformat() if global_next else None,
    "components_parsed": len(rows),
    "overdue_count": len(overdue_components),
    "archived_path_gaps": len(archived_without_note),
    "high_risk_untracked": len(high_risk_no_issue),
}

if json_mode:
    print(json.dumps(findings, ensure_ascii=False, indent=2))
else:
    print(f"maintenance_ledger={ledger_path}")
    print(f"as_of={today_s}")
    if global_next:
        print(f"global_next_review={global_next}")
    print(f"components_parsed={len(rows)}")
    for c in findings["checks"]:
        prefix = c["severity"].upper()
        print(f"{prefix} [{c['code']}] {c['message']}")
        if "detail" in c:
            for item in c["detail"]:
                print(f"  - {item}")
    if findings["ok"]:
        print("maintenance ledger check ok")
    else:
        print("maintenance ledger check FAILED", file=sys.stderr)

sys.exit(0 if findings["ok"] else 1)
PY
