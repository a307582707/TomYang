# monitoring-stack-skeleton — Prometheus Operator 最小路径（Task 78）

**不**拷贝 `k8s/ExtraAddons/prometheus`；空测试集群可按本文安装 kube-prometheus / Prometheus Operator 最小栈。

## 前置

- 集群 ≥ 1.25；已装 CNI 与（可选）metrics-server（上游发行版或独立安装）。
- `kubectl` / `helm`（若用 Helm）可用；**勿**在 Git 中 vendoring 完整 CRD 包（体积过大）。

## 1. 安装 Prometheus Operator CRD（版本钉死）

从 [prometheus-operator 发布页](https://github.com/prometheus-operator/prometheus-operator/releases) 取与 Operator 一致的 bundle：

```bash
export PROMETHEUS_OPERATOR_VERSION="{{ PROMETHEUS_OPERATOR_VERSION }}"
kubectl apply --server-side -f \
  "https://github.com/prometheus-operator/prometheus-operator/releases/download/${PROMETHEUS_OPERATOR_VERSION}/stripped-down-crds.yaml"
kubectl apply --server-side -f \
  "https://github.com/prometheus-operator/prometheus-operator/releases/download/${PROMETHEUS_OPERATOR_VERSION}/crd.yaml"
```

或使用 kube-prometheus 发布中已钉版本的 manifest（推荐与下面 bundle 同 tag）：

```bash
export KUBE_PROMETHEUS_VERSION="{{ KUBE_PROMETHEUS_VERSION }}"
# 仅 CRD + Operator 最小集；完整 bundle 见上游 manifests/setup/
kubectl apply --server-side -f \
  "https://raw.githubusercontent.com/prometheus-operator/kube-prometheus/${KUBE_PROMETHEUS_VERSION}/manifests/setup/0prometheus-operator-0prometheusCustomResourceDefinition.yaml"
# …按 upstream README 顺序 apply setup/ 下其余 CRD（勿整仓复制进本 repo）
```

验证：

```bash
kubectl get crd prometheuses.monitoring.coreos.com
kubectl get crd servicemonitors.monitoring.coreos.com
```

## 2. 命名空间

```bash
kubectl create namespace "{{ MONITORING_NAMESPACE }}"
```

## 3. ServiceMonitor 示例

见同目录 `servicemonitor-example.yml`：抓取带 `app: demo-web` 的 Pod metrics 端口（需目标 Service 暴露名为 `metrics` 的端口）。

```bash
kubectl apply -f servicemonitor-example.yml
```

Operator 已运行且 Prometheus CR 的 `serviceMonitorSelector` 匹配时，Targets 页应出现该 scrape job。

## 4. Grafana + 持久化

- **Operator / Helm 路径：** kube-prometheus 默认带 Grafana；PVC 与 `storageClassName: "{{ STORAGE_CLASS }}"` 在上游 values 中配置。
- **本仓骨架路径：** 无 Operator 时可先 apply `../grafana-skeleton.yml`（Secret 外置，见 `../../security/secret-injection-note.md`）。

Operator 取向注意：

- Grafana admin 走 Secret / `{{ GRAFANA_ADMIN_USER }}` / `{{ GRAFANA_ADMIN_PASSWORD }}`，勿写明文。
- 单副本 + RWO PVC；HA 见下文。

## 5. Alertmanager 配置与存储

- **配置 Secret：** `alertmanager-config-placeholder.yml` — SMTP / Slack 字段均为 `{{ ALERTMANAGER_* }}` 占位，apply 前须渲染或改为 ExternalSecret。
- **PVC 骨架（无 Operator）：** `../alertmanager-storage-skeleton.yml` — `storageClassName: "{{ STORAGE_CLASS }}"`，容量 `{{ ALERTMANAGER_PVC_SIZE }}`。

## 6. 单节点 vs HA

| 组件 | 单节点 Lab | HA 方向 |
|------|------------|---------|
| Prometheus Operator | 1 副本 Deployment | 2+ 副本 + PDB；CRD 一次安装 |
| Prometheus | Prometheus CR `replicas: 1` + 单 PVC | `replicas: 2+` 每副本独立 PVC，或 Thanos/Mimir |
| Alertmanager | `replicas: 1` | `replicas: 3` + 正确 `alertmanagerConfiguration` / peer |
| Grafana | 1 副本 + RWO（`grafana-skeleton.yml`） | 外部 Postgres + ≥2 副本；勿多 Pod 抢一块 RWO |

持久化细节：`docs/audits/observability-persistence-design.md`。

## 7. 最小检查清单

- [ ] CRD 版本与 Operator 镜像 tag 一致
- [ ] `ServiceMonitor` 的 `namespaceSelector` / `selector` 与目标 Service 标签一致
- [ ] NetworkPolicy 放行抓取（见 `examples/current/networkpolicy/30-allow-prometheus-scrape.yml`）
- [ ] 无 `insecureSkipTLSVerify: true` 作为 scrape 长期默认

## 参考（上游，勿 vendoring 进仓）

- [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus)
- [prometheus-operator](https://github.com/prometheus-operator/prometheus-operator)
