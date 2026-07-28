# ADR-001：Ingress 控制器选型（Ingress NGINX）

- **状态:** Accepted（文档 / 示例范围）
- **任务:** Task 86
- **日期:** 2026-07-28
- **范围:** `examples/current/ingress/controller/` 与现代 `examples/current/apps/nginx`

## 背景

历史教材 `k8s/ExtraAddons/ingress-controller/ingress-controller.yml` 使用 **nginx-ingress-controller 0.17.0**（`extensions/v1beta1` 时代），与现网 **networking.k8s.io/v1** 及安全基线不兼容。

本仓库现代示例目录已采用 `networking.k8s.io/v1` Ingress（见 `examples/current/apps/nginx/ingress.yml`）。

## 决策

**选用 [Ingress NGINX Controller](https://kubernetes.github.io/ingress-nginx/)**（社区 `ingress-nginx` 项目），**不**在本任务引入 Gateway API 控制器。

| 候选 | 结论 |
|------|------|
| **Ingress NGINX** | **采用** — 与现有 nginx Ingress 注解、`IngressClass` 示例一致；Helm/官方 manifest 可跟踪现网 LTS |
| Gateway API（如 NGINX Gateway Fabric） | 不采用 — 需额外 CRD/Gateway 资源；留待独立 ADR 与现网 Gateway 成熟度评估 |

## 后果

- 安装与样例以 **IngressClass `nginx`**（名称可配置）为准。
- **禁止** 从 `k8s/ExtraAddons/ingress-controller/` 复制 0.17.0 清单到 `examples/current/`。
- TLS 终止使用 `kubernetes.io/tls` Secret（占位符骨架见 `tls-secret-placeholder.yml`）。
- 端到端验证链路：`controller/` → `examples/current/apps/nginx/`。

## 参考

- 历史反例：`k8s/ExtraAddons/ingress-controller/ingress-controller.yml`
- 现代应用 Ingress：`examples/current/apps/nginx/ingress.yml`
