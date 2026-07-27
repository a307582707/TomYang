# security — 安全基线

## 硬性禁止

- 恢复或新建 `anonymous-proxy` / `system:anonymous` → Dashboard（或任意）高权绑定
- ServiceAccount 直接绑 `cluster-admin`（除非破例变更单）
- 将 `k8s/archived/**` 纳入默认安装

## 示例

| 文件 | 说明 |
|------|------|
| `networkpolicy-default-deny-ingress.yml` | 命名空间级默认拒绝 Ingress |
| `psa-namespace-labels.yml` | Pod Security Admission 标签占位 |
| `secret-injection-note.md` | Secret 外置注入约定 |

部署前确认 CNI 支持 NetworkPolicy。更完整的策略见 `examples/current/networkpolicy/`。
应用标签与 netpol：`apps/nginx` 使用 `app: nginx`，对应 `20-allow-ingress-to-app.yml` 的 `APP_LABEL`。
