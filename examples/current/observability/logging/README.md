# logging — Fluent Bit 轻量日志采集骨架

本目录提供 **Fluent Bit DaemonSet** 示例，用于替代归档的 EFK（Elasticsearch 6.2 + privileged init）栈。

## 与归档 EFK 的边界

| 维度 | 本目录（现代示例） | `k8s/archived/efk/`（禁止部署） |
|------|-------------------|--------------------------------|
| 采集器 | Fluent Bit 3.x | Fluentd → Elasticsearch 6.2 |
| 特权 | 无 `privileged` / 无 init 提权 | ES StatefulSet 需 privileged init |
| 后端 | stdout + HTTP 占位符 | 仓内 ES/Kibana 6.2 |
| 容器运行时 | `/var/log` + `/var/log/pods`（containerd/CRI） | `/var/lib/docker/containers` |
| 用途 | 实验 / 对接现网 Loki·ELK·云日志 | 历史教材反例 |

**禁止** apply `k8s/archived/efk/` 或 `k8s/ExtraAddons/efk/`。现网请选用 Loki、托管日志或经安全评审的 ELK。

## 文件

| 文件 | 说明 |
|------|------|
| `namespace.yml` | `logging` 命名空间 |
| `fluent-bit-configmap.yml` | 采集 + stdout / HTTP 占位输出 |
| `fluent-bit-daemonset.yml` | DaemonSet、RBAC、非 root 安全上下文 |

## 占位符

| 占位符 | 含义 |
|--------|------|
| `{{ LOGGING_NAMESPACE }}` | 通常 `logging` |
| `{{ FLUENT_BIT_IMAGE }}` | 现网钉扎镜像，如 `cr.fluentbit.io/fluent/fluent-bit:3.2.4` |
| `{{ LOG_FORWARD_HTTP_ENDPOINT }}` | 占位 HTTP 后端 URL（无真实服务时可留 `{LOG_HTTP_PLACEHOLDER}` 并仅看 stdout） |

## 部署顺序（实验环境）

```bash
kubectl apply -f namespace.yml
kubectl apply -f fluent-bit-configmap.yml
kubectl apply -f fluent-bit-daemonset.yml
kubectl logs -n logging -l app=fluent-bit --tail=20
```

确认 Pod 日志中出现 `[stdout]` 行后，再将 `LOG_FORWARD_HTTP_ENDPOINT` 换成现网 Loki/Elastic/网关地址。

## 安全要点

- `runAsNonRoot` + `readOnlyRootFilesystem`；capabilities 全 drop
- 仅只读挂载节点 `/var/log` 与 `/var/log/pods`（无 docker.sock）
- 无 `system-node-critical` 强绑（可按现网策略另行添加 PriorityClass）

详见 `docs/audits/observability-completeness.md` 与 `docs/audits/pod-security-matrix.md`（EFK privileged 条目）。
