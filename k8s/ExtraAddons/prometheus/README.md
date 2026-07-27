# Prometheus 栈（历史参考）

目录 `alertmanater/` 为历史拼写，实际组件名为 **Alertmanager**；重命名会破坏既有路径引用，故保留并在此说明。

## 组件

| 路径 | 组件 |
|------|------|
| `operator/` | Prometheus Operator `v0.22.0`（EOL） |
| `prometheus/` | Prometheus CR、规则、Service |
| `alertmanater/` | Alertmanager CR / Secret / Service |
| `grafana/` | Grafana 5.1；本地存储为 **emptyDir**（重启丢数据） |
| `node-exporter/`、`kube-state-metrics/` | 采集器 |
| `servicemonitor/` | ServiceMonitor |
| `kube-service-discovery/` | scheduler/controller-manager 无 selector 的 discovery Service（需手工 Endpoints） |
| `namespace.yml` | `monitoring` |

## 已知采集缺口

- CoreDNS：Service 需暴露 `metrics:9153`，ServiceMonitor 端口名须为 `metrics`（本任务已对齐）。
- kubelet / apiserver ServiceMonitor 依赖集群内建或 Operator 创建的 Service。
- 多处 `tlsConfig.insecureSkipVerify: true`（历史行为，现代环境应改为正式校验）。

## 凭据

Grafana / Alertmanager Secret 必须在部署前替换；勿提交真实 webhook/SMTP 凭据。
