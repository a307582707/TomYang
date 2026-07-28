# observability — 可观测性基线约定

本目录**不**拷贝 `k8s/ExtraAddons/prometheus` 旧栈，也不包含归档的 metrics-server / EFK。

## 骨架文件

| 文件 / 目录 | 说明 |
|-------------|------|
| `metrics-server-skeleton.yml` | 现行 API 的 metrics-server；kubelet TLS 鉴权抓取；验证 `kubectl top` |
| `prometheus-skeleton.yml` | Deployment + Service + PVC（`{{ STORAGE_CLASS }}`）；镜像可用 tag@digest |
| `grafana-skeleton.yml` | 同上；管理员口令仅 `secretKeyRef` |
| `monitoring-stack-skeleton/` | Prometheus Operator / kube-prometheus 最小说明、ServiceMonitor、Alertmanager 占位 |
| `logging/` | Fluent Bit 轻量日志（stdout / 占位后端）；与归档 EFK 边界见该目录 README |

镜像 digest 钉扎与更新流程见 `docs/audits/image-digest-pin-examples.md`。

持久化设计见 `docs/audits/observability-persistence-design.md`。

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
