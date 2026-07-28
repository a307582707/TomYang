#!/usr/bin/env bash
# Task 102 — Generate machine-readable image inventory from k8s/ + examples/.
# Does NOT pull images or invent digests. See docs/audits/image-supply-chain.md.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

OUT_JSON="${IMAGE_INVENTORY_JSON:-docs/audits/image-inventory.json}"
OUT_CSV="${IMAGE_INVENTORY_CSV:-docs/audits/image-inventory.csv}"
SCAN_DATE="$(date -u +%Y-%m-%d)"

python3 - "$ROOT" "$OUT_JSON" "$OUT_CSV" "$SCAN_DATE" <<'PY'
import csv
import json
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
out_json = Path(sys.argv[2])
out_csv = Path(sys.argv[3])
scan_date = sys.argv[4]

SCAN_ROOTS = ("k8s", "examples")
IMAGE_LINE_RE = re.compile(
    r"^\s*(- )?image:\s*(?:(['\"])(.+?)\2|(\S+))",
    re.M,
)
BASE_IMAGE_RE = re.compile(r"^\s*baseImage:\s*['\"]?([^'\"#\s]+)", re.M)
VERSION_RE = re.compile(r"^\s*version:\s*['\"]?([^'\"#\s]+)", re.M)
DIGEST_RE = re.compile(r"@sha256:[a-f0-9]{64}$", re.I)
PLACEHOLDER_RE = re.compile(r"\{\{.*\}\}")

HIGH_PATTERNS = (
    r"/archived/",
    r"kairen/",
    r"zhangguanzhang/",
    r":v1\.11",
    r"kube-apiserver",
    r"kube-controller-manager",
    r"kube-scheduler",
    r"kube-proxy-amd64",
    r"coreos/etcd",
    r"coredns/coredns:1\.",
    r"calico/",
    r"flannel",
    r"grafana/grafana:5",
    r"prometheus-operator",
    r"node-exporter:v0",
    r"kube-state-metrics",
    r"kubernetes-dashboard",
    r"elasticsearch",
    r"kibana",
    r"fluentd",
    r"weaveworks/scope",
    r"nginx-ingress-controller:0\.",
    r"external-dns:v0\.5",
    r"metrics-server-amd64",
    r"k8s-dns-",
    r"alpine:3\.6",
    r"haproxy:1\.7",
    r"keepalived:1\.3",
)
LOW_PATTERNS = (
    r"examples/current/.*nginx:1\.27",
    r"@sha256:",
)


def source_for(rel: str) -> str:
    if rel.startswith("examples/current/"):
        return "examples/current"
    if rel.startswith("k8s/"):
        return "k8s"
    return "unknown"


def classify_eol(path: str, image_ref: str, tag: str, digest: str) -> str:
    if PLACEHOLDER_RE.search(image_ref):
        return "unknown"
    hay = f"{path}|{image_ref}|{tag}"
    for pat in LOW_PATTERNS:
        if re.search(pat, hay, re.I):
            return "low"
    for pat in HIGH_PATTERNS:
        if re.search(pat, hay, re.I):
            return "high"
    if "/archived/" in path:
        return "high"
    if tag in ("", "unknown"):
        return "unknown"
    return "medium"


def parse_image_ref(raw: str) -> tuple[str, str, str]:
    raw = raw.strip().strip("'\"")
    if PLACEHOLDER_RE.search(raw):
        return raw, "", ""

    digest = ""
    ref = raw
    if "@" in raw:
        ref, digest_part = raw.rsplit("@", 1)
        if re.fullmatch(r"sha256:[a-f0-9]{64}", digest_part, re.I):
            digest = digest_part.lower()
        else:
            ref = raw

    tag = ""
    image = ref
    if ":" in ref and not ref.endswith(":"):
        image, tag = ref.rsplit(":", 1)
        if "/" in tag:
            image, tag = ref, ""
    return image, tag, digest


def split_docs(text: str) -> list[str]:
    return [d for d in re.split(r"^---\s*$", text, flags=re.M) if d.strip()]


entries: list[dict] = []
seen: set[tuple] = set()

for scan_root in SCAN_ROOTS:
    base = root / scan_root
    if not base.is_dir():
        continue
    for path in sorted(base.rglob("*")):
        if path.suffix.lower() not in {".yml", ".yaml"}:
            continue
        rel = path.relative_to(root).as_posix()
        text = path.read_text(encoding="utf-8", errors="replace")
        src = source_for(rel)

        for doc in split_docs(text):
            for m in IMAGE_LINE_RE.finditer(doc):
                raw = (m.group(3) or m.group(4) or "").strip()
                image, tag, digest = parse_image_ref(raw)
                if not digest:
                    digest = ""
                eol = classify_eol(rel, raw, tag, digest)
                key = (rel, raw, "image")
                if key in seen:
                    continue
                seen.add(key)
                is_ph = bool(PLACEHOLDER_RE.search(raw))
                entries.append(
                    {
                        "path": rel,
                        "image": image,
                        "tag": tag if tag or is_ph else "unknown",
                        "digest": digest if digest or is_ph else "unknown",
                        "eol_risk": eol,
                        "source": src,
                        "ref_type": "image",
                        "raw_ref": raw,
                    }
                )

            base_m = BASE_IMAGE_RE.search(doc)
            ver_m = VERSION_RE.search(doc)
            if base_m and ver_m:
                base_img = base_m.group(1).strip().strip("'\"")
                ver = ver_m.group(1).strip().strip("'\"")
                raw = f"{base_img}:{ver}"
                image, tag, digest = parse_image_ref(raw)
                eol = classify_eol(rel, raw, tag, digest)
                key = (rel, raw, "operator-baseimage")
                if key not in seen:
                    seen.add(key)
                    entries.append(
                        {
                            "path": rel,
                            "image": image,
                            "tag": tag or "unknown",
                            "digest": "unknown",
                            "eol_risk": eol,
                            "source": "operator-baseimage",
                            "ref_type": "operator-baseimage",
                            "raw_ref": raw,
                        }
                    )

entries.sort(key=lambda e: (e["path"], e["raw_ref"]))

payload = {
    "generated_by": "scripts/generate-image-inventory.sh",
    "scan_date": scan_date,
    "reference_doc": "docs/audits/image-supply-chain.md",
    "scan_roots": list(SCAN_ROOTS),
    "entry_count": len(entries),
    "entries": entries,
}

out_json.parent.mkdir(parents=True, exist_ok=True)
out_json.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

fieldnames = ["path", "image", "tag", "digest", "eol_risk", "source", "ref_type", "raw_ref"]
with out_csv.open("w", encoding="utf-8", newline="") as fh:
    writer = csv.DictWriter(fh, fieldnames=fieldnames, extrasaction="ignore")
    writer.writeheader()
    writer.writerows(entries)

print(f"image_inventory_json={out_json}")
print(f"image_inventory_csv={out_csv}")
print(f"image_inventory_entries={len(entries)}")
PY
