# Task 29 — 目录/文件命名规范化映射

**原则:** 先映射后分批实施；历史清单语义不变；Wiki/脚本/审计引用同步更新。  
**状态:** 本 PR 仅发布映射与影响面，**不执行**重命名。

## 1. 重命名映射

| 当前路径 | 建议路径 | 类型 | 批次 | 风险 | 说明 |
|----------|----------|------|------|------|------|
| `k8s/ExtraAddons/prometheus/alertmanager/` | `k8s/ExtraAddons/prometheus/alertmanager/` | 目录拼写 | B1 | 中 | 组件名为 Alertmanager；目录内文件名前缀可保留历史文件名或随迁 |
| `k8s/addons/metric-server/`（跳转 stub） | `k8s/addons/metrics-server/` | 目录命名 | B2 | 低 | stub 指向 `k8s/archived/metric-server/`；归档目录是否同步改名见下 |
| `k8s/archived/metric-server/` | `k8s/archived/metrics-server/` | 归档目录 | B2 | 中 | 与上游组件名 `metrics-server` 一致；更新 ARCHIVED/隔离脚本 |
| `k8s/addons/Kubedns/` | `k8s/addons/kube-dns/` | 大小写 | B2 | 中 | 建议同步迁入 `k8s/archived/kube-dns/`（EOL），本映射先定名 |
| `k8s/pki/manager-csr.json` | `k8s/pki/controller-manager-csr.json` | 文件名 | B3 | 中 | 需核对 cfssl 签发脚本/Wiki 是否硬编码旧名 |
| `k8s/master/resources/bootstrap-token-Secret.yml` | `k8s/master/resources/bootstrap-token-secret.yml` | 大小写 | B3 | 低 | Kubernetes kind 为 Secret；文件名宜全小写 |
| `k8s/ExtraAddons/prometheus/servicemonitor/kubestate-metrics-sm.yml` | `.../kube-state-metrics-sm.yml` | 文件名 | B3 | 低 | 与目录 `kube-state-metrics/` 对齐 |
| `k8s/ExtraAddons/prometheus/servicemonitor/prometheus-sm.yaml` | `.../prometheus-sm.yml` | 扩展名 | B4 | 低 | 统一 `.yml`（本仓 102:2） |
| `k8s/archived/efk/fluentd-es-ds.yaml` | `.../fluentd-es-ds.yml` | 扩展名 | B4 | 低 | 归档区一并统一 |

## 2. 引用影响面（需同步）

| 引用源 | 受影响项 |
|--------|----------|
| `k8s/ExtraAddons/prometheus/README.md` | `alertmanager/` 说明与表格 |
| `docs/audits/*`（correctness / observability / completeness / maintenance） | 拼写与路径 |
| `docs/MAINTENANCE.md` | Alertmanager 行「目录名拼写」待办 |
| `scripts/check-archived-isolation.sh` | `metric-server` 字符串 |
| Wiki `05-可观测性…` | archived metrics-server / prometheus 路径 |
| Wiki 历史长文 | 含 `addons/metric-server`、`ExtraAddons/dashboard` 的 **归档正文**可不改路径（仅教材）；操作页必须更新 |
| 兼容性矩阵 | Kubedns / metric-server 路径列 |

## 3. 分批实施计划

1. **B1** `alertmanager` → `alertmanager`（`git mv` + 文档/README）  
2. **B2** metrics-server 目录名 + Kubedns 规范化（及可选归档）  
3. **B3** 单文件：`manager-csr`、`bootstrap-token-Secret`、`kubestate-metrics-sm`  
4. **B4** `.yaml` → `.yml` 仅限已列两文件  

每批独立 PR；合并后跑 `scripts/run-static-checks.sh` 并抽查 Wiki 操作页链接。

## 4. 不在本任务范围

- 不修改清单内部 API/镜像版本  
- 不编造上游组件版本  
- 不批量改历史教程正文中的过时路径（除非操作入口页）

## 5. 回滚

关闭本 PR；实施批次用 `git revert` 或反向 `git mv`。
