# examples/current — 空集群端到端连通性指南

**范围:** 仅空测试 / Lab 集群。**禁止**在生产环境按本文一键 apply。

**目标:** 按固定顺序验证 `examples/current/` 现代基线是否可协同工作：节点运行时 → 资源指标 → Ingress → 示例应用 → NetworkPolicy → 日志采集。

## 前提

- 控制面与 worker 已就绪；`kubectl get nodes` 全部 Ready
- CNI 已安装；若需 NetworkPolicy，CNI 须支持策略（见 [ADR-001](../../docs/adr/ADR-001-cni-selection.md)）
- 占位符渲染：复制 `docs/placeholders/examples/vars.example.env`，替换为 Lab 值；勿提交真实密码

---

## 1. 运行时准备（runtime）

核对节点 CRI / kubelet 与教材假设一致（containerd + systemd cgroup）。

| 检查 | 命令 / 动作 |
|------|-------------|
| 片段对照 | 读 `runtime/README.md`；合并 `containerd-config.toml.snippet`、`kubelet-config.snippet.yml` 到现网配置 |
| cgroup | kubelet `cgroupDriver: systemd`；containerd `SystemdCgroup = true` |
| 匿名关闭 | `readOnlyPort: 0`；无 dockershim |

```bash
kubectl get nodes -o wide
# 节点 NotReady → 查 kubelet / containerd 日志（见下方「失败分流」§ runtime）
```

---

## 2. metrics-server

```bash
# 渲染 METRICS_SERVER_IMAGE 等占位符后：
kubectl apply -f examples/current/observability/metrics-server-skeleton.yml
kubectl -n kube-system rollout status deploy/metrics-server --timeout=120s
kubectl top nodes
kubectl top pods -A
```

| 期望 | 说明 |
|------|------|
| `kubectl top` 有数据 | APIService `v1beta1.metrics.k8s.io` 可用 |
| Deployment Ready | 无 `--kubelet-insecure-tls` 类长期默认 |

---

## 3. Ingress 控制器

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.ingressClassResource.name=nginx \
  --set controller.ingressClassResource.enabled=true \
  --set controller.ingressClass=nginx \
  --set controller.service.type=LoadBalancer

kubectl -n ingress-nginx get pods
kubectl get ingressclass nginx
```

详情：`ingress/controller/README.md`。**勿** apply `k8s/ExtraAddons/ingress-controller/`。

---

## 4. nginx 示例应用

```bash
# 设置 {{ INGRESS_CLASS_NAME }}=nginx、{{ NGINX_HOST }}=nginx.lab.example（解析到 LB / NodePort / /etc/hosts）
kubectl apply -k examples/current/apps/nginx/
kubectl rollout status deploy/nginx
kubectl get ingress nginx
```

验证（`INGRESS_IP` = LB EXTERNAL-IP 或 Node IP + NodePort）：

```bash
curl -sI -H 'Host: nginx.lab.example' "http://${INGRESS_IP}/"
# 期望 HTTP/1.1 200
```

TLS 可选步骤见 `ingress/controller/E2E-NOTES.md`。

---

## 5. NetworkPolicy

在**实验命名空间**启用默认拒绝 + 最小放行（勿直接套生产 default）：

```bash
export TARGET_NAMESPACE=default   # 或专用 lab-ns
# 渲染 networkpolicy/*.yml 中占位符后按序 apply：
kubectl apply -f examples/current/networkpolicy/00-default-deny.yml
kubectl apply -f examples/current/networkpolicy/10-allow-dns.yml
kubectl apply -f examples/current/networkpolicy/20-allow-ingress-to-app.yml
# 若已装 Prometheus/Grafana，再 apply 30/40；Fluent Bit 用 50
```

验证：在启用 `00-default-deny` 后，无 DNS 放行时 Pod 应无法解析；叠加 `10` 后恢复；Ingress 路径需 `20` 与控制器标签对齐（见 `TRAFFIC-MATRIX.md`）。

---

## 6. Fluent Bit（日志）

```bash
kubectl apply -f examples/current/observability/logging/namespace.yml
kubectl apply -f examples/current/observability/logging/fluent-bit-configmap.yml
kubectl apply -f examples/current/observability/logging/fluent-bit-daemonset.yml
kubectl -n logging logs -l app=fluent-bit --tail=30
```

期望日志含 `[stdout]` 采集行。HTTP 转发端点未配置时可仅验证 stdout。

---

## 7. 汇总验证命令

```bash
# 资源与入口
kubectl get nodes
kubectl top nodes
kubectl -n ingress-nginx get pods
kubectl get ingressclass
kubectl get deploy,svc,ingress -l app=nginx
curl -sI -H 'Host: nginx.lab.example' "http://${INGRESS_IP}/"

# 策略（若已 apply）
kubectl get networkpolicy -n "${TARGET_NAMESPACE:-default}"

# 日志
kubectl -n logging get pods -l app=fluent-bit
kubectl -n logging logs -l app=fluent-bit --tail=5
```

可选监控栈（非本 E2E 必需）：`observability/README.md`、`monitoring-stack-skeleton/`。

---

## 失败分流（triage）

| 症状 | 可能原因 | 排查 |
|------|----------|------|
| Node NotReady | CRI / kubelet / CNI | 节点 `journalctl -u kubelet`；对照 `runtime/README.md` |
| `kubectl top` 失败 | metrics-server APIService、kubelet 证书 | `kubectl get apiservice v1beta1.metrics.k8s.io`；metrics-server Pod 日志 |
| Ingress 无 ADDRESS | LB 未分配、class 名不匹配 | `kubectl describe ingress nginx`；`kubectl get svc -n ingress-nginx` |
| curl 502/404 | 后端未 Ready、Host 头错误 | `kubectl get endpoints`；确认 `Host` 与 `{{ NGINX_HOST }}` 一致 |
| NP 后全断网 | 缺 DNS 或 Ingress 放行 | 先 apply `10-allow-dns`；核对 `20` 中 Ingress 命名空间标签 |
| Fluent Bit CrashLoop | 镜像/权限/路径 | `kubectl describe pod -n logging`；确认挂载 `/var/log/pods`（containerd） |
| 抓取/仪表盘失败 | 未装 Operator 或 NP 未放行 9090 | 见 `networkpolicy/30-allow-prometheus-scrape.yml` |

---

## 清理（Lab）

```bash
kubectl delete -k examples/current/apps/nginx/
kubectl delete -f examples/current/observability/logging/ --ignore-not-found
kubectl delete -f examples/current/networkpolicy/ --ignore-not-found   # 按实际 apply 顺序逆序更安全
helm uninstall ingress-nginx -n ingress-nginx
kubectl delete -f examples/current/observability/metrics-server-skeleton.yml --ignore-not-found
```

---

## 相关文档

- [examples/current/README.md](./README.md) — 目录总览
- [ingress/controller/E2E-NOTES.md](./ingress/controller/E2E-NOTES.md) — Ingress + nginx 细节
- [networkpolicy/README.md](./networkpolicy/README.md) — 策略前提与顺序
- [observability/README.md](./observability/README.md) — 监控 / 持久化（可选）
