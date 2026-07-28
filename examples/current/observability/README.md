# observability — 可观测性基线约定

本目录**不**拷贝 `k8s/ExtraAddons/prometheus` 旧栈，也不包含归档的 metrics-server / EFK。

## 骨架文件

| 文件 / 目录 | 说明 |
|-------------|------|
| `metrics-server-skeleton.yml` | 现行 API 的 metrics-server；kubelet TLS 鉴权抓取；验证 `kubectl top` |
| `prometheus-skeleton.yml` | Deployment + Service + PVC（`{{ STORAGE_CLASS }}` / `{{ PROMETHEUS_PVC_SIZE }}`）；镜像可用 tag@digest |
| `grafana-skeleton.yml` | 同上（`{{ GRAFANA_PVC_SIZE }}`）；管理员口令仅 `secretKeyRef` |
| `alertmanager-storage-skeleton.yml` | Alertmanager Deployment + PVC（`{{ ALERTMANAGER_PVC_SIZE }}`）；配置 Secret 外置 |
| `storage-class-reference.yml` | `{{ STORAGE_CLASS }}` 选用说明（注释清单，非 apply） |
| `monitoring-stack-skeleton/` | Prometheus Operator / kube-prometheus 最小说明、ServiceMonitor、Alertmanager 配置占位 |
| `logging/` | Fluent Bit 轻量日志（stdout / 占位后端）；与归档 EFK 边界见该目录 README |

镜像 digest 钉扎与更新流程见 `docs/audits/image-digest-pin-examples.md`。

持久化设计见 `docs/audits/observability-persistence-design.md`。

## 持久化占位符

| 占位符 | 典型 Lab 值 | 用途 |
|--------|-------------|------|
| `{{ STORAGE_CLASS }}` | `standard` / 现网 SC 名 | 所有 RWO PVC |
| `{{ PROMETHEUS_PVC_SIZE }}` | `10Gi`–`50Gi` | Prometheus TSDB |
| `{{ GRAFANA_PVC_SIZE }}` | `5Gi`–`10Gi` | Grafana 仪表盘与用户数据 |
| `{{ ALERTMANAGER_PVC_SIZE }}` | `5Gi` | Alertmanager 静默/状态 |
| `{{ PROMETHEUS_RETENTION }}` | `15d` | TSDB 保留（与容量匹配） |

渲染示例见 `docs/placeholders/examples/vars.example.env` 与 `scripts/testdata/kubeconform/dummy-placeholders.env`。

## 备份与恢复（Lab / 空集群）

**仅实验环境**；生产以现网备份策略为准。

| 组件 | 备份 | 恢复要点 |
|------|------|----------|
| Prometheus | PVC 卷快照；或 `remote_write` 到长期存储 | 新 PVC 自快照恢复；无快照则 TSDB 不可重建 |
| Grafana | 导出 dashboard JSON；PVC 快照；`grafana-credentials` Secret 外置备份 | 挂回 PVC 或导入 JSON + 重建 Secret |
| Alertmanager | 备份 `alertmanager-config` Secret + PVC 快照 | 先恢复 Secret 再挂 PVC；单副本宕机仅影响通知，不丢指标 |

通用步骤（Lab）：

```bash
# 1. 确认 SC 与 PVC Bound
kubectl -n monitoring get pvc

# 2. 卷快照（需 CSI snapshot 或云控制台；名称因环境而异）
# kubectl apply -f volume-snapshot.yml   # 现网模板，勿提交真实 SC/卷 ID

# 3. 恢复演练：删 Deployment（保留 PVC）→ 从快照建新 PVC → 再 apply 骨架
kubectl -n monitoring delete deploy/prometheus --ignore-not-found
# …按现网 snapshot restore 流程挂回 prometheus-data …
kubectl apply -f prometheus-skeleton.yml   # 渲染后
```

失败行为与 HA 注意点见 `docs/audits/observability-persistence-design.md` §失败与恢复检查清单。

## 推荐方向

| 能力 | 建议 |
|------|------|
| 指标 | 现网 kube-prometheus-stack 或托管 Prometheus；先装匹配的 CRD（见 `monitoring-stack-skeleton/`） |
| 资源指标 | 使用本目录 `metrics-server-skeleton.yml`；勿 apply `k8s/archived/metrics-server/` |
| 日志 | 使用 `logging/` Fluent Bit 或现网 Loki/云日志；勿 apply `k8s/archived/efk/` |
| 仪表盘 | Grafana + PVC；密钥部署时注入 |
| 控制面抓取 | scheduler/CM 需可达 metrics；确认非仅 `127.0.0.1` |

## 最小检查清单

- [ ] Namespace（如 `monitoring`）已创建
- [ ] ServiceMonitor / PodMonitor 与 Service 端口名一致
- [ ] 持久化 StorageClass 已选定
- [ ] 无 `insecureSkipVerify` 作为长期默认（过渡期需文档化例外）
- [ ] `kubectl top nodes/pods` 在 metrics-server 就绪后可用

详见仓库 `docs/audits/observability-completeness.md`。
