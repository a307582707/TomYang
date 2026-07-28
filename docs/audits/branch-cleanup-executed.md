# Task 74 — 远程分支清理执行记录

**执行时间:** 2026-07-28（UTC+8）
**依据:** `docs/audits/branch-cleanup-inventory.md`；本任务清单视作维护者执行确认。

## 删除前 — 主仓
```
origin/archive/dangerous-manifests
origin/audit/compat-matrix-v2
origin/audit/k8s-compatibility
origin/audit/k8s-correctness
origin/audit/k8s-security
origin/audit/observability
origin/audit/observability-completeness
origin/chore/repository-audit-fixes
origin/ci/dangerous-patterns
origin/ci/doc-quality
origin/ci/static-checks
origin/ci/static-check-tests
origin/ci/static-layers
origin/ci/wiki-link-check
origin/docs/branch-cleanup-inventory
origin/docs/codeowners
origin/docs/contributing
origin/docs/final-acceptance
origin/docs/hygiene-acceptance
origin/docs/issue-templates
origin/docs/license-audit
origin/docs/maintenance-inventory
origin/docs/naming-normalization-map
origin/docs/pr2-cleanup-record
origin/docs/pr-template
origin/docs/quarterly-review
origin/docs/task32-dependency-graph
origin/docs/task33-ha-test
origin/docs/task34-pki
origin/docs/task35-rbac
origin/docs/task36-podsec
origin/docs/task37-resources
origin/docs/task38-probes
origin/docs/task39-scheduling
origin/docs/task41-ingress
origin/docs/task42-cni-adr
origin/docs/task43-service-dns
origin/docs/task44-pull
origin/docs/task45-shell
origin/docs/task46-dr
origin/docs/task47-fault
origin/docs/task48-release
origin/docs/task60-etcd-runbook
origin/docs/task61-images
origin/docs/task64-security-plan
origin/docs/task65-obs-persist
origin/docs/task67-infra-align
origin/docs/task68-audits-index
origin/docs/task70-cert-rotation
origin/docs/task71-control-plane-mode
origin/docs/upgrade-readme
origin/docs/wiki-task5-ia
origin/docs/wiki-task6-infra
origin/docs/wiki-task7-archive
origin/examples/current-baseline
origin/examples/task40-netpol
origin/examples/task59-nginx
origin/examples/task66-baseline-fill
origin/examples/task72-secrets
origin/feat/config-render
origin/feat/placeholder-catalog
origin/fix/contributing-codeowners-links
origin/fix/dangerous-patterns-self-match
origin/master
origin/rename/alertmanager-dir
origin/rename/metrics-kubedns-files
origin/scripts/cert-expiry
```

## 将删除 — 主仓（保留 master）

- `archive/dangerous-manifests`
- `audit/compat-matrix-v2`
- `audit/k8s-compatibility`
- `audit/k8s-correctness`
- `audit/k8s-security`
- `audit/observability`
- `audit/observability-completeness`
- `chore/repository-audit-fixes`
- `ci/dangerous-patterns`
- `ci/doc-quality`
- `ci/static-check-tests`
- `ci/static-checks`
- `ci/static-layers`
- `ci/wiki-link-check`
- `docs/branch-cleanup-inventory`
- `docs/codeowners`
- `docs/contributing`
- `docs/final-acceptance`
- `docs/hygiene-acceptance`
- `docs/issue-templates`
- `docs/license-audit`
- `docs/maintenance-inventory`
- `docs/naming-normalization-map`
- `docs/pr-template`
- `docs/pr2-cleanup-record`
- `docs/quarterly-review`
- `docs/task32-dependency-graph`
- `docs/task33-ha-test`
- `docs/task34-pki`
- `docs/task35-rbac`
- `docs/task36-podsec`
- `docs/task37-resources`
- `docs/task38-probes`
- `docs/task39-scheduling`
- `docs/task41-ingress`
- `docs/task42-cni-adr`
- `docs/task43-service-dns`
- `docs/task44-pull`
- `docs/task45-shell`
- `docs/task46-dr`
- `docs/task47-fault`
- `docs/task48-release`
- `docs/task60-etcd-runbook`
- `docs/task61-images`
- `docs/task64-security-plan`
- `docs/task65-obs-persist`
- `docs/task67-infra-align`
- `docs/task68-audits-index`
- `docs/task70-cert-rotation`
- `docs/task71-control-plane-mode`
- `docs/upgrade-readme`
- `docs/wiki-task5-ia`
- `docs/wiki-task6-infra`
- `docs/wiki-task7-archive`
- `examples/current-baseline`
- `examples/task40-netpol`
- `examples/task59-nginx`
- `examples/task66-baseline-fill`
- `examples/task72-secrets`
- `feat/config-render`
- `feat/placeholder-catalog`
- `fix/contributing-codeowners-links`
- `fix/dangerous-patterns-self-match`
- `rename/alertmanager-dir`
- `rename/metrics-kubedns-files`
- `scripts/cert-expiry`

## 将删除 — Wiki

- `wiki/ia-restructure`
- `wiki/infra-consistency`
- `wiki/archive-banners`

## 保留

- 主仓 `master`
- Wiki `master`
- Wiki tag `backup/wiki-master-20260727`
