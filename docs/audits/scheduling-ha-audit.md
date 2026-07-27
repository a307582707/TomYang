# Task 39 — 调度与工作负载 HA 审计

**范围:** replicas、PodDisruptionBudget、affinity/anti-affinity、tolerations（摘要）。
**建议落点:** 仅在 `examples/current/` 增加现代示例，**不**把历史 `k8s/` 1.11 清单当作现网 SSOT 直接大改。

## 1. 副本与单点

| 工作负载 | replicas | 路径 | HA 评价 |
|----------|----------|------|---------|
| CoreDNS | 2 | `k8s/addons/coredns/coredns.yml` | 基本；缺 PDB / 反亲和 |
| kube-dns | 2 | `k8s/addons/Kubedns/kubedns.yml` | 旧；与 CoreDNS 勿双活 |
| Prometheus CR | 2 | `ExtraAddons/prometheus/prometheus/prometheus-main.yml` | 有副本；缺 PDB 示例 |
| Alertmanager CR | 3 | `.../alertmanager/alertmanager-main.yml` | 适合 HA |
| calico-typha | **0** | `addons/calico/v3.1/calico.yml` | 显式关闭 |
| nginx（示例） | **1** | `k8s/apps/nginx/nginx-dp.yml` | 单副本 |
| nginx-ingress-controller | **1** | `ExtraAddons/ingress-controller/` | **控制面入口单点** |
| default-http-backend | 1 | 同上 | 可接受 |
| grafana / operator / kube-state-metrics | 1 | prometheus 目录 | 单点 |
| external-dns 及附属 coredns/etcd | 1 | `ExtraAddons/external-dns/` | 单点 |
| calicoctl | 1 | calico | 工具 |
| 归档 ES | 2 | `archived/efk/` | 勿部署 |
| 控制面静态 Pod | N/A（每节点一份） | `k8s/master/manifests/` | 靠多 master + VIP；非 Deployment replicas |

DaemonSet（kube-proxy、flannel/calico-node、node-exporter、fluentd）：按节点铺开，HA 取决于节点池。

## 2. PodDisruptionBudget

- **全仓库 `k8s/`：未发现任何 `PodDisruptionBudget` 对象。**
- 滚动升级或腾空节点时，CoreDNS / Ingress / Prometheus 可能同时不可用。

## 3. 亲和与容忍

| 项 | 发现 |
|----|------|
| `affinity` | 主要见于 `ExtraAddons/external-dns/coredns/coredns-dp.yml`（**nodeAffinity 要求 master**） |
| `podAntiAffinity` | **未发现**（CoreDNS/Ingress/Prometheus 均无） |
| `tolerations` | CoreDNS、kube-proxy、CNI、node-exporter、external-dns 等有 `CriticalAddonsOnly` / master NoSchedule |
| `nodeSelector` | flannel 等 |

## 4. 建议示例（写入 `examples/current/` 的方向）

以下为文档级建议骨架，供后续 PR 落文件；数值与标签以现网选定为准。

**`examples/current/apps/` — 多副本 + 反亲和 + PDB**

```yaml
# 示意：勿直接当生产容量
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: demo-web
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: demo-web
---
# Deployment spec.replicas: 2+
# affinity.podAntiAffinity: preferred/required on app label, topologyKey: kubernetes.io/hostname
```

**`examples/current/ingress/` — Ingress Controller HA**

- `replicas: 2`（或 DaemonSet + 主机网络，现网选定）
- PDB `minAvailable: 1`
- `podAntiAffinity` 打散到不同节点

**`examples/current/observability/`**

- 对 Prometheus / Alertmanager 引用发行版 chart 的 PDB 与反亲和约定
- 不复制仓库内 EOL Operator 全量 YAML

**DNS**

- CoreDNS：`replicas ≥ 2` + PDB + softAntiAffinity；容忍控制面污点可保留

## 5. 控制面 HA（对照）

- 多 master 静态 Pod + Keepalived VIP `:8443` + HAProxy → `:5443`
- CM/scheduler 已 `--leader-elect=true`
- 工作负载层 HA（本审计）与控制面 HA（Task 33）互补，不能互相替代

## 修改摘要

### 风险
- Ingress / external-dns / 多数监控组件 `replicas: 1` 且无 PDB → 节点排水即中断。
- external-dns 附属 CoreDNS 亲和到 master，扩大控制面负载与耦合。

### 遗留
- 无 PDB 清单。
- 无 podAntiAffinity。
- 现代示例尚未全部落地为独立 YAML（可以本审计为清单逐步补到 `examples/current/`）。

### 回滚
- 文档-only。若已在 examples 增加 PDB/亲和，删除或 revert 对应文件即可；勿在未评审时降低现网 Ingress 副本。
