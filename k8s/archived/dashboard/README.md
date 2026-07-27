# Kubernetes Dashboard（历史归档）

> **禁止生产部署。** 统一说明见 [`../ARCHIVED.md`](../ARCHIVED.md)。

- 镜像版本极旧（v1.8.3）。
- 已移除 `anonymous-proxy-rbac.yml`（曾将 `system:anonymous` 与 Dashboard 代理绑定，并将 ServiceAccount 绑定 `cluster-admin`）。
- 如需 UI，请使用现行 Dashboard 版本，并配置 SSO / 最小权限 RBAC。
