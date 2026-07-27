# Kubernetes Dashboard（历史参考）

- 镜像版本极旧（v1.8.3），**禁止**用于生产。
- 已移除 `anonymous-proxy-rbac.yml`（曾将 `system:anonymous` 与 Dashboard 代理绑定，并将 ServiceAccount 绑定 `cluster-admin`）。
- 如需 UI，请使用现行 Dashboard 版本，并配置 SSO / 最小权限 RBAC。
