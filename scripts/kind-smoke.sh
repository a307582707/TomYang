#!/usr/bin/env bash
# Task 104 — Ephemeral kind smoke for examples/current (Phase A).
# Does NOT use production kubeconfig. See docs/audits/kind-smoke-design.md.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CLUSTER_NAME="${KIND_SMOKE_CLUSTER_NAME:-tomyang-smoke}"
SKIP_DELETE="${KIND_SMOKE_SKIP_DELETE:-0}"
NGINX_DIR="$ROOT/examples/current/apps/nginx"

cleanup() {
  if [[ "$SKIP_DELETE" == "1" ]]; then
    echo "KIND_SMOKE_SKIP_DELETE=1 — leaving cluster $CLUSTER_NAME"
    return
  fi
  kind delete cluster --name "$CLUSTER_NAME" 2>/dev/null || true
}
trap cleanup EXIT

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "missing required command: $1"
    exit 1
  }
}

need docker
need kind
need kubectl

echo "kind_smoke_phase=A cluster=$CLUSTER_NAME"

if ! kind get clusters 2>/dev/null | grep -qx "$CLUSTER_NAME"; then
  kind create cluster --name "$CLUSTER_NAME" --wait 120s
fi

kubectl cluster-info --context "kind-${CLUSTER_NAME}"

kubectl apply -f "$NGINX_DIR/deployment.yml" -f "$NGINX_DIR/service.yml"
kubectl rollout status deployment/nginx --timeout=120s

SVC_IP="$(kubectl get svc nginx -o jsonpath='{.spec.clusterIP}')"
kubectl run curl-smoke --rm -i --restart=Never --image=curlimages/curl:8.5.0 \
  --command -- curl -sf "http://${SVC_IP}/" >/dev/null

echo "PASS nginx deployment reachable via ClusterIP"

echo "--- Phase B (ingress) conceptual checklist ---"
echo "  1) Install ingress-nginx into kind cluster"
echo "  2) Render {{ INGRESS_CLASS_NAME }} / {{ NGINX_HOST }} then apply ingress.yml"
echo "  3) curl -H Host:... through ingress controller NodePort"
echo "--- Phase C (metrics) conceptual checklist ---"
echo "  1) Apply rendered metrics-server-skeleton or chart equivalent"
echo "  2) kubectl top nodes OR verify prometheus /metrics target (if CRDs present)"
echo "kind_smoke_stub_complete"
