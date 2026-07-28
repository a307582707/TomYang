# Changelog

本文件记录 **本教材仓库（TomYang）自身** 的版本变更，**不是**上游 Kubernetes 发行版 changelog。

版本规则、Tag 约定与发布检查单见 [`docs/RELEASE.md`](docs/RELEASE.md)。
`v0.1.0` 维护者 tag 步骤见 [`docs/release/v0.1.0.md`](docs/release/v0.1.0.md)。

## 版本号说明（摘要）

- **仓库版本**（本 CHANGELOG）：`MAJOR.MINOR.PATCH`（SemVer 语义针对文档/清单教材结构）。
- **上游 Kubernetes 版本**：在 `docs/MAINTENANCE.md` 与清单镜像标签中单独台账（例如教材控制面曾钉 `v1.11.1`），**不得**与仓库 SemVer 混用同一数字冒充「集群已升级」。
- **v0.1.0 定位：** 历史教材（`k8s/`）与现代示例（`examples/current/`）**并存**的文档基线；**不**声称生产就绪部署。

---

## [Unreleased]

### Added

- （待下一 MINOR：如 Fluent Bit logging 示例、台账自动检查、kubeconform 等合入后写入）

### Changed

- （无）

---

## [0.1.0] — 2026-07-28

### Added

- **归档隔离：** `k8s/archived/`（Dashboard、EFK、metrics-server、WeaveScope、kube-dns 等）与 `ARCHIVED.md`；旧 ExtraAddons/addons 路径 stub/跳转。
- **现代示例基线：** `examples/current/`（apps、ingress、networkpolicy、observability、security、runtime）。
- **静态检查：** `scripts/run-static-checks.sh` 及子检查（YAML、密钥、危险模式、归档隔离、现代示例、Wiki 链接等）。
- **维护与审计：** `docs/MAINTENANCE.md` 组件台账；`docs/audits/` 索引与多份验收/安全/兼容报告。
- **Runbook 与 DR 索引：** `docs/runbooks/`、`docs/disaster-recovery/`。
- **Wiki 结构：** 操作长文迁至 GitHub Wiki；本仓 README/SSOT 指向 Wiki INFRA/SRE 分区。
- **发布文档：** `docs/RELEASE.md`、本 CHANGELOG、`docs/release/v0.1.0.md`（含 maintainer `git tag` 命令；**tag 由维护者合入后手动创建**）。

### Changed

- 根 `README.md`：导航至 Wiki、现代示例、审计、台账；明确禁止直接 apply 的路径。
- `k8s/ExtraAddons/` 与部分 addons：高风险栈迁入 archived，推荐入口改指向 `examples/current/` 与 Wiki。

### Security

- 删除/隔离匿名高权 RBAC 推荐路径；`scripts/check-dangerous-patterns.sh` 防 insecure kubelet / docker.sock 等模式回流。
- 归档 EFK（ES 6.2 + privileged init）与旧 Dashboard 标记**禁止部署**。

### Notes

- 上游 K8s / etcd / Calico 等组件版本仍以仓内历史清单与 `docs/MAINTENANCE.md` 为准；新集群需按现网发行版重建，**不得**将本仓库 tag 解读为集群升级完成。
- **非生产就绪：** 本 release 仅标记教材仓库组织方式与检查体系就绪，现网变更仍须独立变更流程与验收。

[Unreleased]: https://github.com/a307582707/TomYang/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/a307582707/TomYang/releases/tag/v0.1.0
