# Changelog

本文件记录 **本教材仓库（TomYang）自身** 的版本变更，**不是**上游 Kubernetes 发行版 changelog。

版本规则、Tag 约定与发布检查单见 [`docs/RELEASE.md`](docs/RELEASE.md)。

## 版本号说明（摘要）

- **仓库版本**（本 CHANGELOG）：`MAJOR.MINOR.PATCH`（SemVer 语义针对文档/清单教材结构）。
- **上游 Kubernetes 版本**：在 `docs/MAINTENANCE.md` 与清单镜像标签中单独台账（例如教材控制面曾钉 `v1.11.1`），**不得**与仓库 SemVer 混用同一数字冒充「集群已升级」。

---

## [Unreleased]

### Added

- Task 40：`examples/current/networkpolicy/` 流量矩阵与 NetworkPolicy 示例；`docs/audits/networkpolicy-design.md`
- Task 41：`docs/audits/ingress-migration.md`
- Task 42：`docs/adr/ADR-001-cni-selection.md`
- Task 43：`docs/audits/service-dns-audit.md`
- Task 44：`docs/audits/pull-script-modernization.md`；`scripts/pull-images-modern.sh.design.md`（不覆盖 `pull.sh`）
- Task 45：`docs/audits/shell-quality-audit.md`
- Task 46：`docs/disaster-recovery/README.md`
- Task 47：`docs/audits/fault-injection-catalog.md`
- Task 48：`CHANGELOG.md`；`docs/RELEASE.md`

### Changed

- （无仓库行为变更；历史 `k8s/` 清单未因本批文档任务改写）

### Security

- DR 索引指向 Wiki SRE-07（Token 泄露应急）；Shell 审计强调勿倾倒 `vsphere.sh` / `.env` 秘密

---

## [0.1.0] — 2026-07-27

### Added

- 初始 CHANGELOG 骨架与 Unreleased 文档任务条目（教材仓库版本 `0.1.0` 起记）

### Notes

- 上游 K8s / etcd / Calico 等组件版本仍以仓内清单与 `docs/MAINTENANCE.md` 为准，不在本版本号中表达。
