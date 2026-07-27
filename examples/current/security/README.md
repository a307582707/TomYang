# security — 安全基线

## 硬性禁止

- 恢复或新建 `anonymous-proxy` / `system:anonymous` → Dashboard（或任意）高权绑定
- ServiceAccount 直接绑 `cluster-admin`（除非破例变更单）
- 将 `k8s/archived/**` 纳入默认安装

## 示例

`networkpolicy-default-deny-ingress.yml`：命名空间级默认拒绝 Ingress（按需放行）。
部署前确认 CNI 支持 NetworkPolicy。
