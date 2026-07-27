# Task 4 — 可观测性清单整理报告

**分支:** `audit/observability`

## 已修复（低风险）

| 项 | 处置 |
|----|------|
| CoreDNS ServiceMonitor 端口名 `http-metrics` 与容器/Service 不一致 | SM 改为 `metrics`；CoreDNS Service 增加 `9153/metrics` |
| EFK 缺少 Namespace | 新增 `ExtraAddons/efk/namespace.yml` |
| 文档缺口 | 新增 Prometheus / discovery README |

## 组件核对摘要

| 组件 | 端口/selector | Namespace | 持久化 | 凭据 | 结论 |
|------|---------------|-----------|--------|------|------|
| Prometheus Operator | Service `http:8080` 与 SM 一致 | monitoring | 无 | SA/RBAC | 结构可用；版本 EOL |
| Prometheus | `web:9090`；SM `prometheus:k8s` | monitoring | 视 CR storage 字段 | — | 需确认 CR 存储配置 |
| Alertmanager | `web:9093`；SM `alertmanager:main` | monitoring | — | Secret 含模板化 slack/smtp 占位 | 目录名拼写 `alertmanager` |
| Grafana | `http:3000` | monitoring | **emptyDir** | Secret | 重启丢面板数据；凭据见安全任务 |
| kube-state-metrics | Service 标签 `k8s-app` + selector `app` 与 Pod 对齐 | monitoring | — | https + insecureSkipVerify | 可采集 |
| node-exporter | 同上模式 | monitoring | hostPath 只读 | https + insecureSkipVerify | 可采集 |
| CoreDNS metrics | 已对齐 | kube-system | — | bearer token | 已修 |
| kubelet SM | 依赖 kube-system 中 kubelet Service | kube-system | — | insecureSkipVerify | 缺 Service 时无数据 |
| apiserver SM | 依赖 default/kubernetes | default | — | 正式 CA | 通常可用 |
| scheduler/CM SM | discovery Service 无 selector | kube-system | — | 明文 10251/10252 | 需 Endpoints；且常听 127.0.0.1 |
| EFK | ES↔Fluentd↔Kibana 名称端口一致 | kube-logging | ES STS 卷 | — | 缺 Namespace 已补；组件 EOL |

## 剩余问题

1. Grafana 生产应改 PVC；Alertmanager/Prometheus 存储策略需按 CR 明确。
2. 多处 `insecureSkipVerify` / metrics-server insecure（跨任务）。
3. `alertmanager` 目录重命名需全库替换引用。
4. discovery Endpoints 仅提供文档示例，未提交含真实 IP 的清单。
5. Operator/CRD 版本过旧，不建议在新集群直接 apply（见 Task 2）。

## 检查结果

- [x] 核对 ServiceMonitor ↔ Service 标签与端口
- [x] 核对 EFK 服务名与 Fluentd/Kibana 配置
- [x] 低风险项已修；其余写入本报告

## 风险说明

- CoreDNS Service 增加 metrics 端口对现网无害；若有 NetworkPolicy 需放行 9153。
- 未升级 Operator，避免运行时大变。

## 回滚方法

关闭本 PR 或 revert；CoreDNS/SM 变更可单独 revert。
