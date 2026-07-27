# Task 38 — 健康探针审计

**范围:** `k8s/` 中 Deployment/DaemonSet/StatefulSet/Pod 的 `livenessProbe` / `readinessProbe` / `startupProbe`。

## 1. 控制面静态 Pod

| 组件 | 文件 | 探针 | 端口/方式 | 结论 |
|------|------|------|-----------|------|
| kube-apiserver | `k8s/master/manifests/kube-apiserver.yml` | liveness HTTP `/healthz` HTTPS | **5443** | **已与 `--secure-port=5443` 对齐**（曾误为 6443，已修） |
| etcd | `etcd.yml` | liveness TCP | 2379 | 合理；无 readiness |
| kube-controller-manager | `kube-controller-manager.yml` | liveness HTTP `/healthz` | **10252**（`--address=127.0.0.1`） | 与历史 insecure 健康端口一致；现代版应迁 HTTPS 安全端口 |
| kube-scheduler | `kube-scheduler.yml` | liveness HTTP `/healthz` | **10251** | 同上 |
| haproxy | `haproxy.yml` | **无** | — | 依赖 keepalived/外部检查；可补 TCP/HTTP 探针 |
| keepalived | `keepalived.yml` | **无** | — | 常见；靠进程存活 |

VIP 路径健康：实验室用 `https://{{ VIP }}:8443/healthz`（经 HAProxy），不是 5443。

## 2. 插件与 ExtraAddons

| 工作负载 | 探针 | 问题 |
|----------|------|------|
| CoreDNS `addons/coredns` | liveness `:8080/health` | **无 readiness**；现代建议加 readiness（如 `/ready`） |
| kube-dns `addons/Kubedns` | liveness/readiness 多容器 | 旧栈；与 CoreDNS 二选一 |
| calico-node | liveness+readiness `:9099` | OK |
| calico-typha | liveness+readiness `:9098` | replicas=0 |
| flannel | **无** | 缺探针 |
| kube-proxy | **无** | 缺探针 |
| nginx-ingress-controller | liveness+readiness `:10254/healthz` | OK |
| default-http-backend | liveness `:8080` | 无 readiness |
| external-dns coredns | liveness `:8080` | 无 readiness；replicas=1 |
| external-dns etcd | liveness TCP 2379 | OK 基本 |
| external-dns 主容器 | **无** | 建议加 |
| grafana | **无** | 建议加 |
| prometheus-operator | **无** | 建议加 |
| kube-state-metrics 四容器 | **无** | 建议加 |
| node-exporter | **无** | 建议加 |
| Prometheus/Alertmanager CR | 清单无探针字段 | 由 Operator 注入（需对照运行时） |

## 3. 应用与归档

| 工作负载 | 探针 |
|----------|------|
| `apps/nginx` | **无** |
| archived dashboard | liveness `:8443` |
| archived metrics-server | **无** |
| archived EFK ES/fluentd/kibana | **无** |

## 4. 端口对齐要点

- **Apiserver：探针 5443 = secure-port 5443 = HAProxy backend。** 对外客户端走 **8443**。
- 勿再改回 6443，除非整条链路（含 HAProxy）同步迁移。
- CM/scheduler 的 10251/10252 在较新 Kubernetes 已废弃 insecure 端口——升级时一并改探针。

## 修改摘要

### 风险
- 缺就绪探针会导致流量打到未就绪 Pod（Ingress/DNS）。
- 错误端口的存活探针会造成不必要的重启（apiserver 已修复）。

### 遗留
- 大量 ExtraAddons / CNI / 示例仍无完整探针。
- haproxy/keepalived 无容器探针。
- CM/scheduler 仍用历史明文健康端口。

### 回滚
- 文档-only。探针改动回滚对应 manifest；apiserver 保持 5443 与现网拓扑一致。
