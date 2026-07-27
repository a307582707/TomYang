# Secret 注入说明（Task 66）

## 禁止

- 在 Git 中提交真实口令、TLS 私钥、云 AK
- 把占位符（如 `{{ GRAFANA_ADMIN_PASSWORD }}`）未渲染就 apply 到现网
- 依赖仓库**历史提交**中的样例口令（视为已泄露）

## 推荐注入方式（选一）

1. **CI / CD**：流水线从保险箱取出 → `kubectl create secret generic … --from-literal=…` 或渲染后 apply
2. **External Secrets / Sealed Secrets**：集群内同步；清单只含引用
3. **云厂商 Secret Store CSI**：挂载为卷或环境变量

## Grafana 约定

见 `examples/current/observability/grafana-skeleton.yml`：仅 `secretKeyRef` 引用 `grafana-credentials`，本目录不存放 Secret 清单。

```bash
# Lab 示例（勿把真口令写进脚本仓库）
kubectl -n monitoring create secret generic grafana-credentials \
  --from-literal=user="{{ GRAFANA_ADMIN_USER }}" \
  --from-literal=password="{{ GRAFANA_ADMIN_PASSWORD }}"
```

## 验证

- `kubectl get secret` 存在且非 placeholder 原文
- Grafana `GF_AUTH_ANONYMOUS_ENABLED=false`
- 轮换后旧样例口令无法登录
