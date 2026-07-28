# observability — 可观测性基线约定

本目录**不**拷贝 `k8s/ExtraAddons/prometheus` 旧栈，也不包含归档的 metrics-server / EFK。

## 骨架文件

| 文件 | 说明 |
|------|------|
| `metrics-server-skeleton.yml` | metrics-server（apps/v1 + RBAC + APIService）；kubelet TLS 抓取，非 archived 拷贝 |
| `prometheus-skeleton.yml` | Deployment + Service + PVC（`{{ STORAGE_CLASS }}`） |
| `grafana-skeleton.yml` | 同上；管理员口令仅 `secretKeyRef` |
| `monitoring-stack-skeleton/` | Prometheus Operator / kube-prometheus 最小安装文档 + ServiceMonitor / Alertmanager 占位 |

持久化设计见 `docs/audits/observability-persistence-design.md`。

## metrics-server（Task 77）

1. 渲染 `{{ METRICS_SERVER_IMAGE }}`（例 `registry.k8s.io/metrics-server/metrics-server:v0.7.2` 或 digest 占位）。
2. `kubectl apply -f metrics-server-skeleton.yml`（或经 `scripts/render/` 输出到 `.rendered/`）。
3. 若 `kubectl top` 报 APIService 不可用，按 [metrics-server 上游文档](https://github.com/kubernetes-sigs/metrics-server) 提取 serving CA 并 `kubectl patch apiservice v1beta1.metrics.k8s.io --type=json -p='[{"op":"add","path":"/spec/caBundle","value":"<base64>"}]'`（**勿**改 kubelet 抓取为 insecure 默认）。
4. 验证：

```bash
kubectl top nodes
kubectl top pods -A
```

**禁止默认：** `--kubelet-insecure-tls`、`--deprecated-kubelet-completely-insecure`、APIService `insecureSkipTLSVerify: true`（过渡期须单独变更单）。

## 推荐方向

| 能力 | 建议 |
|------|------|
| 指标 | 现网 kube-prometheus-stack 或托管 Prometheus；先装匹配的 CRD |
| 资源用量 | 先装 `metrics-server-skeleton.yml`，再 `kubectl top` / HPA |
| 日志 | 现网 Loki / ELK / 云日志；勿 apply `k8s/archived/efk/` |
| 仪表盘 | Grafana + PVC；密钥部署时注入 |
| 控制面抓取 | scheduler/CM 需可达 metrics；确认非仅 `127.0.0.1` |

## 最小检查清单

- [ ] Namespace（如 `monitoring`）已创建
- [ ] ServiceMonitor / PodMonitor 与 Service 端口名一致
- [ ] 持久化 StorageClass 已选定
- [ ] 无 `insecureSkipVerify` 作为长期默认（过渡期需文档化例外）

详见仓库 `docs/audits/observability-completeness.md`。
