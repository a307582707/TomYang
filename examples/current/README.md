# examples/current — 现代 Kubernetes 示例基线

**目标:** 为海曦现网提供可读、可改的现代清单骨架。
**明确不覆盖:** 仓库根下 `k8s/` 历史自建清单（1.11 时代教材）。

| 子目录 | 用途 |
|--------|------|
| `apps/` | 工作负载示例（`apps/v1`）；含 `nginx/` kustomize |
| `ingress/` | `networking.k8s.io/v1` Ingress |
| `networkpolicy/` | 默认拒绝 + 常见放行 |
| `observability/` | Prometheus/Grafana PVC 骨架；`logging/` Fluent Bit（非 EFK） |
| `security/` | PSA 标签、Secret 注入说明、禁匿名等 |
| `runtime/` | containerd + kubelet 节点侧片段 |

## 使用原则

1. 先读 Wiki [INFRA-01](https://github.com/a307582707/TomYang/wiki/INFRA-01-本仓HA控制面与节点接入) 确认端口拓扑（VIP `:8443` → apiserver `:5443`）。
2. 将 `{{ PLACEHOLDER }}` 换成现网值；**不要**把本目录与 `k8s/archived/` 混用。
3. 镜像标签请按现网发行版钉扎（示例中的版本仅为占位；nginx 示例固定 `1.27.5`）。
4. 需要对照旧实现时，只读 `k8s/` / `k8s/archived/`，勿 apply 归档目录。

## 与历史仓的关系

```text
k8s/                  → 历史参考（可能 EOL / 已移除 API）
k8s/archived/         → 禁止部署的高风险反例
examples/current/     → 现代基线（本目录）
```

## 建议试用顺序

1. `runtime/README.md`（确认 CRI / cgroup）
2. `security/README.md`（PSA / Secret / 无匿名高权）
3. `apps/nginx/` 或 `apps/demo-web.yml` → `ingress/` → `networkpolicy/`
4. `observability/`（再选现网监控发行版）

端到端连通性（空集群）：见 [E2E.md](./E2E.md)。
