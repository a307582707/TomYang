# Prometheus 栈（历史参考）

目录 `alertmanager/` 为历史拼写，实际组件名为 **Alertmanager**；重命名会破坏既有路径引用，故保留并在此说明。

**部署前置：** 本目录**不包含** Prometheus Operator CRD。必须先安装与 Operator `v0.22.0` 匹配的 CRD，再 apply 本目录；详见 `docs/audits/observability-completeness.md`。

## 组件

| 路径 | 组件 |
|------|------|
| `operator/` | Prometheus Operator `v0.22.0`（EOL；无 CRD YAML） |
| `prometheus/` | Prometheus CR、规则、Service（CR **无 storage**，默认非持久） |
| `alertmanager/` | Alertmanager CR / Secret / Service（Secret 为占位符） |
| `grafana/` | Grafana 5.1；本地存储为 **emptyDir**（重启丢数据） |
| `node-exporter/`、`kube-state-metrics/` | 采集器 |
| `servicemonitor/` | ServiceMonitor |
| `kube-service-discovery/` | discovery Service + `endpoints.example.yml` |
| `namespace.yml` | `monitoring` |

## 已知采集缺口

- CoreDNS：Service 需暴露 `metrics:9153`，ServiceMonitor 端口名须为 `metrics`（已对齐）。
- kubelet / apiserver ServiceMonitor 依赖集群内建或 Operator 创建的 Service。
- scheduler/CM：需真实 Endpoints，且 metrics 端口须对 Prometheus 可达。
- 多处 `tlsConfig.insecureSkipVerify: true`（历史行为，现代环境应改为正式校验）。

## 凭据

Grafana / Alertmanager Secret 必须在部署前替换占位符；勿提交真实 webhook/SMTP 凭据。
