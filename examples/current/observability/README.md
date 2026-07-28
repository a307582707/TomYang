# observability — 可观测性基线约定

本目录**不**拷贝 `k8s/ExtraAddons/prometheus` 旧栈，也不包含归档的 metrics-server / EFK。

## 骨架文件

| 文件 / 目录 | 说明 |
|-------------|------|
| `prometheus-skeleton.yml` | Deployment + Service + PVC（`{{ STORAGE_CLASS }}`） |
| `grafana-skeleton.yml` | 同上；管理员口令仅 `secretKeyRef` |
| `logging/` | Fluent Bit DaemonSet（stdout + HTTP 占位）；**非**归档 EFK |

持久化设计见 `docs/audits/observability-persistence-design.md`。

## 推荐方向

| 能力 | 建议 |
|------|------|
| 指标 | 现网 kube-prometheus-stack 或托管 Prometheus；先装匹配的 CRD |
| 日志 | 现网 Loki / ELK / 云日志；骨架见 `logging/`；**禁止** apply `k8s/archived/efk/`（ES 6.2 + privileged init） |
| 仪表盘 | Grafana + PVC；密钥部署时注入 |
| 控制面抓取 | scheduler/CM 需可达 metrics；确认非仅 `127.0.0.1` |

## 最小检查清单

- [ ] Namespace（如 `monitoring`）已创建
- [ ] ServiceMonitor / PodMonitor 与 Service 端口名一致
- [ ] 持久化 StorageClass 已选定
- [ ] 无 `insecureSkipVerify` 作为长期默认（过渡期需文档化例外）

详见仓库 `docs/audits/observability-completeness.md`。
