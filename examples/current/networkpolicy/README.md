# networkpolicy — 命名空间流量基线示例

**任务:** Task 40
**目标:** 在 `examples/current/` 下提供可读、可改的 NetworkPolicy 骨架；**不**覆盖 `k8s/` 历史清单，**不**当作现网一键 apply。

## 前提

1. CNI 必须支持 Kubernetes NetworkPolicy（本仓教材 CNI 见 `k8s/addons/calico/`；Flannel 默认**不**执行 NetworkPolicy）。选型结论见 [ADR-001](../../../docs/adr/ADR-001-cni-selection.md)。
2. 将 `{{ PLACEHOLDER }}` 换成现网值；勿把本目录与 `k8s/archived/` 混用。
3. 控制面静态 Pod（`k8s/master/manifests/`）通常使用 `hostNetwork`，命名空间 NetworkPolicy **基本管不到**它们；见下文「控制面说明」。

## 文件一览

| 文件 | 作用 |
|------|------|
| [TRAFFIC-MATRIX.md](./TRAFFIC-MATRIX.md) | 允许/拒绝流量矩阵 |
| `00-default-deny.yml` | 默认拒绝 Ingress + Egress |
| `10-allow-dns.yml` | 放行到集群 DNS（UDP/TCP 53） |
| `20-allow-ingress-to-app.yml` | 放行 Ingress Controller → 应用 |
| `30-allow-prometheus-scrape.yml` | 放行 Prometheus 抓取（通用标签） |
| `40-allow-grafana-to-datasource.yml` | 放行 Grafana → 数据源（通用） |
| `50-allow-fluent-bit-to-log-backend.yml` | 放行 fluent-bit → 日志后端（通用） |
| [docs/audits/networkpolicy-design.md](../../../docs/audits/networkpolicy-design.md) | 设计摘要与验证 Pod（非生产 apply） |

## 建议试用顺序（仅沙箱 / 实验命名空间）

1. 选定实验 Namespace，替换所有 `{{ TARGET_NAMESPACE }}` 等占位符。
2. apply `00-default-deny.yml` → 再 apply `10-allow-dns.yml`。
3. 按业务需要叠加 `20` / `30` / `40` / `50`。
4. 用设计文档中的验证 Pod 做连通性检查；**不要**在生产命名空间直接套用本目录 YAML。

## 与历史仓的关系

```text
examples/current/security/networkpolicy-default-deny-ingress.yml
  → 仅 Ingress 默认拒绝（更窄）
examples/current/networkpolicy/   （本目录）
  → Ingress+Egress 默认拒绝 + 常见放行样例
k8s/                              → 历史参考，勿混 apply
```

## 控制面说明（hostNetwork）

| 组件路径 | 典型网络模式 | NetworkPolicy 影响 |
|----------|--------------|-------------------|
| `k8s/master/manifests/etcd.yml` 等静态 Pod | 多为 hostNetwork | 策略几乎不生效；依赖主机防火墙 / 安全组 |
| `k8s/addons/kube-proxy/`、CNI DaemonSet | hostNetwork / 特权 | 策略覆盖有限 |
| 业务 Pod（无 hostNetwork） | 集群 Pod 网 | 本目录策略适用 |

详情与验证建议见 [networkpolicy-design.md](../../../docs/audits/networkpolicy-design.md)。
