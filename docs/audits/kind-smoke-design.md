# Task 104 — Kind / k3d 可选冒烟设计

**状态:** 设计-first；CI 提供 **手动** `workflow_dispatch` 桩，**默认不在每条 PR 上运行**（集群创建 + 镜像拉取较重）。

**约束:** **禁止** 使用生产 `KUBECONFIG` 或生产集群 endpoint；仅 ephemeral 本地/CI 集群。

---

## 1. 目标

| 验证项 | 范围 | 说明 |
|--------|------|------|
| **nginx 工作负载** | `examples/current/apps/nginx/` | Deployment + Service；固定 tag + digest |
| **Ingress（概念）** | `ingress/` + nginx Ingress | 需预装 ingress-nginx；占位符渲染后 HTTP 路由 |
| **Metrics（概念）** | `observability/metrics-server-skeleton.yml` 等 | 需占位镜像 + CRD；验证 `kubectl top` 或 Prometheus scrape 路径 |

不覆盖 `k8s/` 历史清单；不 apply `k8s/archived/`。

---

## 2. 推荐子集（Phase）

### Phase A — 最小冒烟（本 Task 桩实现）

```text
examples/current/apps/nginx/deployment.yml
examples/current/apps/nginx/service.yml
```

- 创建 kind 单节点集群（Kubernetes 1.28+ 与 CI runner 兼容）
- `kubectl apply -k` 或等价 apply deployment+service
- `kubectl rollout status deployment/nginx`
- 集群内 `curl` Service ClusterIP → 期望 HTTP 200

### Phase B — Ingress（维护者手动扩展）

1. kind 集群加载 ingress-nginx（官方 manifest 或 helm，**版本由维护者 pin**）
2. 渲染 `{{ INGRESS_CLASS_NAME }}` / `{{ NGINX_HOST }}`（envsubst 或 `scripts/render-config.sh` 若已合入）
3. apply `apps/nginx/ingress.yml` 或 `ingress/demo-web-ingress.yml`
4. `curl -H "Host: …" http://localhost/` 经 NodePort / port-forward 验证

### Phase C — Metrics（概念验证）

1. 安装 metrics-server（现网批准镜像 + 占位符渲染）或仅文档化 `kubectl top` 期望
2. 可选：apply `observability/prometheus-skeleton.yml` 片段 + 检查 Pod Ready（需 CRD/Operator 时标记 **skip in stub**）
3. 验收：`kubectl top nodes` 或 Prometheus `/metrics` 路径可达（维护者记录于 Run 日志）

---

## 3. 工具选型

| 工具 | 适用 | 备注 |
|------|------|------|
| **kind** | GitHub Actions ubuntu-latest | 本仓库桩默认；无额外 VM |
| **k3d** | 本地维护者 | 更快启动；脚本可 `CLUSTER_TOOL=k3d` 扩展 |

---

## 4. 密钥与 kubeconfig

- CI **不得** 挂载 `secrets.KUBECONFIG` 指向生产
- 仅 `kind create cluster` / `k3d cluster create` 生成临时 kubeconfig
- 镜像拉取使用公共 registry；nginx 示例已 digest-pin

---

## 5. 本地运行

```bash
# 需本地 docker + kind
bash scripts/kind-smoke.sh
```

环境变量：

| 变量 | 默认 | 说明 |
|------|------|------|
| `KIND_SMOKE_CLUSTER_NAME` | `tomyang-smoke` | kind 集群名 |
| `KIND_SMOKE_SKIP_DELETE` | `0` | `1` 保留集群便于调试 |

---

## 6. CI 集成

- Workflow: [`.github/workflows/kind-smoke.yml`](../../.github/workflows/kind-smoke.yml)
- 触发：`workflow_dispatch` only（**非** `pull_request` / `push` 默认路径）
- 桩行为：Phase A + 打印 Phase B/C 检查清单；失败则 Job 红

未来若资源允许，可加 `schedule: cron` 每周一次，仍与 PR 门禁分离。

---

## 7. 验收标准

- [ ] 维护者可手动 dispatch workflow 且 Phase A 绿
- [ ] 文档明确 ingress/metrics 为概念步骤与占位符依赖
- [ ] 无生产 kubeconfig 引用
- [ ] PR 默认 CI（`static-checks`）不受影响

## 8. 回滚

- 删除 workflow、`scripts/kind-smoke.sh` 与本设计 doc
- 不影响现网或 `k8s/` 清单

---

## 参考

- [`examples/current/README.md`](../../examples/current/README.md)
- [`examples/current/ingress/controller/E2E-NOTES.md`](../../examples/current/ingress/controller/E2E-NOTES.md)
- [`docs/audits/kubeconform-examples.md`](./kubeconform-examples.md)
