# ADR-002：监控栈选型（kube-prometheus-stack vs DIY Operator）

- **状态:** 提议（Accepted for documentation；**本 ADR 不含 Helm install 命令、不 vendoring 上游 chart**）
- **任务:** Task 99
- **日期:** 2026-07-29
- **决策者:** 仓库维护者 / 现网平台组（最终以现网变更为准）

## 背景

本仓 `examples/current/observability/` 提供三类现代基线：

| 路径 | 用途 |
|------|------|
| `prometheus-skeleton.yml` / `grafana-skeleton.yml` / `alertmanager-storage-skeleton.yml` | 无 Operator 时的最小 Deployment + PVC 骨架 |
| `metrics-server-skeleton.yml` | 资源指标（`kubectl top`） |
| `monitoring-stack-skeleton/` | Prometheus Operator CRD 安装说明、ServiceMonitor 示例、Alertmanager Secret 占位 |

历史 `k8s/ExtraAddons/prometheus/` 为教材时代全量清单，**禁止**作为新集群安装源。

现网需在 **kube-prometheus-stack（Helm）** 与 **DIY Operator + 自选 manifest** 之间选型。

## 决策驱动因素

1. 是否需要 Prometheus Operator CR（ServiceMonitor / PrometheusRule / AlertmanagerConfig）。
2. 团队对 Helm values、CRD 升级与回滚的运维能力。
3. 与 `examples/current/networkpolicy/` 抓取放行策略的对齐成本。
4. 持久化（`{{ STORAGE_CLASS }}`、PVC 容量）与备份策略是否已有平台标准。
5. 是否接受上游 bundle 体积与版本 pin 纪律（**禁止**将完整 chart 拷贝进本 repo）。

## 方案比较

| 维度 | kube-prometheus-stack（Helm） | DIY Prometheus Operator |
|------|------------------------------|-------------------------|
| 安装面 | 单 chart：Operator + Prometheus + Alertmanager + Grafana + 默认规则 | 分步 apply CRD、Operator Deployment、自写/上游 Prometheus CR |
| 版本 pin | Chart version + appVersion；与 `{{ KUBE_PROMETHEUS_VERSION }}` 对齐 | Operator 镜像 tag = `{{ PROMETHEUS_OPERATOR_VERSION }}`；CR 与 RBAC 自维护 |
| CRD 管理 | Chart 内置或引用 prometheus-operator release bundle | 须手动 `kubectl apply --server-side` 上游 `crd.yaml`（见 skeleton README） |
| 与本仓骨架关系 | values 中配置 SC/PVC；Grafana 口令走 Secret | 可先 apply 本仓 `*-skeleton.yml` 做 Lab，再迁 Operator |
| 升级 | `helm upgrade` + CRD 兼容矩阵；回滚 `helm rollback` | 先升 CRD → 再升 Operator → 再调 CR；回滚逐步逆序 |
| 适合 | 需要完整栈、接受 Helm 运维 | 需要细粒度控制、已有 GitOps/裸 manifest 流程 |

## 版本 pin 策略

| 层级 | 约定 |
|------|------|
| Operator / kube-prometheus | 钉死 git tag 或 Helm chart version；写入变更单，**勿** `latest` |
| CRD | 与 Operator **同 release**；升级前 diff 上游 CHANGELOG 中 breaking CRD |
| 应用镜像 | Prometheus / Grafana / Alertmanager 使用固定 tag 或 digest（见 `docs/audits/image-digest-pin-examples.md`） |
| 本仓占位 | `{{ PROMETHEUS_OPERATOR_VERSION }}`、`{{ KUBE_PROMETHEUS_VERSION }}` 仅文档与渲染示例 |

**禁止**在 Git 中提交未 pin 的 `image: prom/prometheus:latest` 或整包 `manifests/` 拷贝。

## CRD 管理

1. **安装顺序：** Namespace → CRD（server-side apply）→ Operator RBAC/Deployment → Prometheus/Alertmanager CR → ServiceMonitor。
2. **单一来源：** 从 [prometheus-operator releases](https://github.com/prometheus-operator/prometheus-operator/releases) 或 kube-prometheus **同 tag** 取 CRD；勿混用不同 minor 的 CRD 与 Operator。
3. **本仓边界：** `monitoring-stack-skeleton/servicemonitor-example.yml` 为示例；kubeconform 跳过 CRD schema（无 vendored OpenAPI）。
4. **卸载：** 生产慎用 CRD 级联删除；Lab 可 `kubectl delete crd …` 前确认无其他租户 CR。

## 与 `examples/current/observability` 骨架的关系

```text
Lab / 连通性验证          → metrics-server-skeleton + apps/nginx + networkpolicy
无 Operator 持久化实验    → *-skeleton.yml（PVC + Deployment）
Operator / 生产取向       → monitoring-stack-skeleton/README.md → 上游 Helm 或 manifest
日志（非指标）            → logging/ Fluent Bit（与 Prometheus 栈正交）
```

骨架 **不替代** kube-prometheus-stack；它们用于文档化占位符、kubeconform 与空集群试装。选定 Helm 后，PVC/保留/告警路由应在 values 或 AlertmanagerConfig CR 中配置，Secret 仍遵循 `secret-injection-note.md`。

## 升级与回滚

| 场景 | 升级 | 回滚 |
|------|------|------|
| Helm 栈 | `helm upgrade` 前备份 values；检查 CRD hook | `helm rollback <release> <revision>` |
| DIY Operator | 1) CRD 2) Operator Deployment 3) Prometheus CR 镜像/副本 | 逆序降版；PVC 不随 Deployment 回滚 |
| 仅本仓 skeleton | 重新渲染占位符后 `kubectl apply` | `kubectl rollout undo`；PVC 保留需手动处理 |
| 数据 | Prometheus/Grafana/Alertmanager PVC 或 remote_write | 卷快照 / remote 恢复（见 `observability/README.md` 备份节） |

升级窗口内应验证：Targets 健康、Alertmanager 测试告警、Grafana 数据源、NetworkPolicy 抓取路径（`30-allow-prometheus-scrape.yml`）。

## 决策（文档立场）

| 场景 | 建议 |
|------|------|
| 新集群、需要完整监控与告警 | **优先 kube-prometheus-stack**（Helm），版本 pin 与现网变更流程绑定 |
| 已有 GitOps、仅需 Operator + 自管 CR | **DIY Operator**；严格 CRD/Operator 同版本 |
| 仅教材/空集群连通性 | 本仓 skeleton + metrics-server；**不**装全栈 |
| 沿用 `k8s/ExtraAddons/prometheus` | **拒绝** |

**本 ADR 不提供 install 命令输出、不修改现网集群。**

## 后果

- 正：版本与 CRD 纪律清晰；与 Task 98 PVC 占位、Task 40 NetworkPolicy 示例可组合验证。
- 负：Helm 与 DIY 二选一后，另一路径文档需标记为备选，避免双栈并存。
- 中性：日志栈（Fluent Bit）独立选型，见 `logging/README.md`。

## 参考

- `examples/current/observability/README.md`
- `examples/current/observability/monitoring-stack-skeleton/README.md`
- `docs/audits/observability-persistence-design.md`
- `docs/audits/observability-completeness.md`
- [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus)
- [prometheus-operator](https://github.com/prometheus-operator/prometheus-operator)
