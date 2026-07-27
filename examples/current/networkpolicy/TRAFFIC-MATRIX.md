# NetworkPolicy 流量矩阵（教材示例）

**范围:** `examples/current/networkpolicy/` 示例意图；标签与端口均为**通用占位**，非现网生产值。
**RPO/RTO、现网标签:** 以现网定义为准，本文不填写具体生产 CIDR / 账号。

## 图例

| 符号 | 含义 |
|------|------|
| DENY | 默认拒绝（`00-default-deny.yml`） |
| ALLOW | 显式 NetworkPolicy 放行 |
| N/A | hostNetwork / 控制面，命名空间策略通常无效 |

## Ingress（入站）

| 目标 Pod | 来源 | 端口 | 策略文件 | 说明 |
|----------|------|------|----------|------|
| 命名空间内任意 Pod | * | * | `00` | 默认 DENY |
| `app: {{ APP_LABEL }}` | Ingress Controller 命名空间 / 标签 `{{ INGRESS_POD_SELECTOR }}` | `{{ APP_PORT }}`（示例 80） | `20` | 仅允许控制器入站 |
| `{{ SCRAPE_TARGET_LABELS }}` | Prometheus 命名空间 / 标签 `{{ PROMETHEUS_POD_SELECTOR }}` | `{{ METRICS_PORT }}` | `30` | 指标抓取 |
| 其他 | 未列出 | * | — | 保持 DENY |

## Egress（出站）

| 源 Pod | 目标 | 端口 | 策略文件 | 说明 |
|--------|------|------|----------|------|
| 命名空间内任意 Pod | * | * | `00` | 默认 DENY |
| 任意（或选定工作负载） | `kube-system` Service `kube-dns` / 标签 `k8s-app: kube-dns` | 53 UDP/TCP | `10` | 集群 DNS；本仓 CoreDNS Service 名为 `kube-dns`，`clusterIP: 10.96.0.10`（见 `k8s/addons/coredns/coredns.yml`） |
| Grafana（标签 `{{ GRAFANA_POD_SELECTOR }}`） | 数据源命名空间 / 标签 `{{ DATASOURCE_POD_SELECTOR }}` | `{{ DATASOURCE_PORT }}` | `40` | 如 Prometheus API |
| fluent-bit（标签 `{{ FLUENT_BIT_POD_SELECTOR }}`） | 日志后端命名空间 / 标签 `{{ LOG_BACKEND_POD_SELECTOR }}` | `{{ LOG_BACKEND_PORT }}` | `50` | 如 HTTP/Forward；后端选型现网定义 |
| 其他 | 未列出 | * | — | 保持 DENY |

## 控制面 / 系统组件

| 流量 | 策略覆盖 | 备注 |
|------|----------|------|
| apiserver / etcd / scheduler / controller-manager（`k8s/master/manifests/`） | N/A | 通常 hostNetwork；用主机级 ACL |
| kube-proxy、Calico/Flannel 节点代理 | N/A | 节点网络路径 |
| CoreDNS Pod ↔ apiserver | 系统命名空间另策 | 勿用本业务 NS 示例直接套 `kube-system` |

## 与可观测性约定的交叉

- CoreDNS metrics `9153`：若对 `kube-system` 启用策略，需单独放行 Prometheus → CoreDNS（本目录示例面向**业务 NS**）。
- 参见 `examples/current/observability/README.md`、`docs/audits/observability-report.md`。
