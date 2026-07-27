# Task 37 — 资源 requests/limits 与 QoS 审计

**范围:** `k8s/` 工作负载容器的 `resources.requests` / `limits`。
**不做:** 臆造现网容量数字或强制设定具体 CPU/内存值。

## 1. 有 requests 且有 limits

| 工作负载 | 路径 | QoS 倾向 |
|----------|------|----------|
| CoreDNS | `k8s/addons/coredns/coredns.yml` | Burstable（cpu 仅 request；memory 有 req+lim） |
| Flannel `kube-flannel` | `k8s/addons/flannel/kube-flannel.yml` | Burstable/Guaranteed 视是否 req=lim |
| Grafana | `k8s/ExtraAddons/prometheus/grafana/grafana-dp.yml` | 有 req+lim |
| prometheus-operator | `.../operator/operator.yml` | 有 req+lim |
| kube-state-metrics 各容器 | `.../kube-state-metrics-dp.yml` | 有 req+lim |
| node-exporter + kube-rbac-proxy | `.../node-exporter-ds.yml` | 有 req+lim |
| default-http-backend | `.../ingress-controller/ingress-controller.yml` | 有 req+lim |
| external-dns CoreDNS / etcd | `.../external-dns/coredns/*-dp.yml` | 有 req+lim |
| kube-dns 主容器等 | `k8s/addons/Kubedns/kubedns.yml` | 部分有 lim |
| 归档 EFK（ES/fluentd/kibana） | `k8s/archived/efk/` | 有 req+lim（勿部署） |

## 2. 仅有 requests（无 limits）

| 工作负载 | 路径 | 备注 |
|----------|------|------|
| kube-apiserver | `k8s/master/manifests/kube-apiserver.yml` | cpu 250m |
| kube-controller-manager | `.../kube-controller-manager.yml` | cpu 200m |
| kube-scheduler | `.../kube-scheduler.yml` | cpu 100m |
| haproxy / keepalived | `haproxy.yml` / `keepalived.yml` | cpu 100m |
| calico-node | `addons/calico/v3.1/calico.yml` | 有 requests |
| Prometheus CR | `prometheus/prometheus-main.yml` | `requests.memory: 400Mi`（由 Operator 落到 Pod） |

**QoS:** 多为 **Burstable**。控制面静态 Pod 常故意不设 limits，避免 CPU throttle 影响 API 延迟——属常见做法，是否加 limits 由现网选定。

## 3. requests/limits 皆缺（或基本缺失）

| 工作负载 | 路径 | 影响 |
|----------|------|------|
| etcd | `k8s/master/manifests/etcd.yml` | BestEffort 风险：节点压力时易被驱逐（etcd 有 critical priority 可缓） |
| kube-proxy | `addons/kube-proxy/kube-proxy.yml` | 无 resources |
| calico-typha / install-cni / calicoctl | `addons/calico/v3.1/` | typha replicas=0；缺资源字段 |
| nginx-ingress-controller | `ingress-controller.yml` | 有探针但**无** resources（同文件 backend 有） |
| external-dns | `external-dns/external-dns.yml` | 无 |
| apps/nginx | `k8s/apps/nginx/nginx-dp.yml` | 示例无资源 |
| 归档 dashboard / metrics-server | `archived/` | 无 |
| Alertmanager CR | `alertmanager-main.yml` | 清单未写 resources（依赖 Operator 默认） |

## 4. 命名空间配额

- 仓库内 **无** `ResourceQuota` / `LimitRange` 对象。
- 建议在 `examples/current/` 按命名空间（如 ingress、monitoring、应用 ns）由现网选定配额，而非写死容量。

## 5. 现代建议（无具体数值）

1. 所有业务与插件容器至少设 **requests**（调度与容量规划）。
2. 对可水平扩展的无状态服务设 **limits**，并关注 CPU throttle。
3. etcd / apiserver：优先 requests + `PriorityClass`；limits 谨慎、经压测。
4. 用 metrics（现网 Prometheus/metrics-server）定基线后再填数字。
5. 新基线放在 `examples/current/`，勿直接改历史 1.11 清单当作现网 SSOT。

## 修改摘要

### 风险
- BestEffort（如 etcd 无 request）在节点资源耗尽时更易被驱逐。
- 无 LimitRange 时命名空间可被单 Pod 打满。

### 遗留
- ingress-controller、kube-proxy、etcd、示例 nginx 等仍缺完整资源字段。
- 无集群级 Quota 示例（可后续加到 examples/current）。

### 回滚
- 文档-only。若已改清单 resources，回滚对应 YAML 即可。
