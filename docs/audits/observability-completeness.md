# Task 16 — 可观测性部署完整性审计

**分支:** `audit/observability-completeness`

## 确定性修复（本 PR）

| 项 | 处置 |
|----|------|
| Alertmanager Secret 内嵌默认 slack/smtp 样例 | 改为 `stringData` + `{{ ALERTMANAGER_* }}` 占位符，部署前注入 |
| scheduler/CM Endpoints 仅 README 示例 | 增加 `kube-service-discovery/endpoints.example.yml`（文档网段 IP，防误用） |

## 核对结果

| 检查项 | 结论 |
|--------|------|
| Prometheus Operator CRD | **缺失**：`k8s/ExtraAddons/prometheus/` 无 `CustomResourceDefinition`；直接 apply Operator/CR 会失败 |
| scheduler / controller-manager Endpoints | Service 无 selector；需 Endpoints。示例已补；若组件只听 `127.0.0.1` 仍抓不到 |
| CoreDNS metrics Service | `kube-dns` Service 含 `metrics:9153`；SM `port: metrics` + `k8s-app: kube-dns` **匹配** |
| ServiceMonitor selector | 主要依赖 `k8s-app` 存在；Prometheus CR `serviceMonitorSelector` 为 `k8s-app Exists` |
| Grafana 持久化 | **emptyDir** → 重启丢数据 |
| Prometheus 持久化 | Prometheus CR **无 `storage`** → 默认 emptyDir/ephemeral |
| Alertmanager 持久化 | Alertmanager CR 未见 PVC 配置 |
| Elasticsearch 持久化 | STS 使用 **emptyDir**（非 PVC） |
| Alertmanager Secret 默认配置 | 已改为占位符（见上） |
| Namespace | `monitoring`、`kube-logging` 清单存在 |

## 部署限制（不做强改）

1. **必须先安装与 Operator `v0.22.0` 匹配的 CRD**（Prometheus、Alertmanager、ServiceMonitor、PrometheusRule 等），本仓未托管 CRD YAML。  
2. **勿把 `endpoints.example.yml` 原样用于生产**；替换 IP，并确认 10251/10252 对 Prometheus 可达。  
3. **现代 kube-scheduler/controller-manager** 常关闭非安全端口或只绑 loopback → 需 `--bind-address`/secure metrics 方案，超出本仓 1.11 语义。  
4. Grafana / Prometheus / ES **无可靠持久化**；生产需 PVC + StorageClass（按站点新建，不在本 PR 猜测类名）。  
5. 目录名 `alertmanater` 拼写错误；重命名需批量改引用，留待维护窗口。  
6. 组件版本 EOL：见 `docs/audits/k8s-compatibility-matrix.md`；新集群建议 kube-prometheus-stack，而非原地升级本目录。

## 建议 apply 顺序（历史栈）

1. `namespace.yml`（monitoring / kube-logging）  
2. 外部提供的 Operator CRD  
3. `operator/` → 其余 prometheus 组件 → `servicemonitor/`  
4. 按需 `kube-service-discovery/*` + 真实 Endpoints  
5. EFK：`efk/namespace.yml` → ES → Fluentd → Kibana  

## 回滚

`git revert` 本 PR；Alertmanager Secret 回滚后需重新注入配置。
