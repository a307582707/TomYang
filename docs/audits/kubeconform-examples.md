# Task 83 — kubeconform（`examples/current`）

## 范围

| 目录 | kubeconform |
|------|-------------|
| `examples/current/**/*.yml` | **是**（CI 硬失败） |
| `k8s/`、`k8s/archived/` | **否**（历史教材；由 `check-deprecated-api.sh` 等 warn 层处理） |

**目标 Kubernetes 版本:** `1.29.0`（与现网 1.28–1.30 基线对齐；可通过 `KUBECONFORM_VERSION` 覆盖）。

## 占位符策略

含 `{{ PLACEHOLDER }}` 的清单在校验前会用 `scripts/testdata/kubeconform/dummy-placeholders.env` 渲染为合法字面量，**不会**因未替换模板而误报 schema 错误。

- 已知占位符 → 表中 dummy 值
- 未知占位符 → `dummy-<name>` 并打印 `kubeconform_render_warn`（仍参与校验，避免静默跳过）

非 Kubernetes 清单（无 `apiVersion:` 行）自动跳过。

**无 bundled schema 的骨架**（CRD / KubeletConfiguration / Kustomization）列在 `scripts/testdata/kubeconform/skip-schema-check.txt` 或按文件名 `kustomization.y*ml` 自动排除，不参与 kubeconform，避免误报；仍受 YAML/现代基线检查约束。

## 脚本与 CI

- `scripts/check-kubeconform.sh` — 主校验
- `scripts/test-kubeconform.sh` — good/bad 夹具
- `.github/workflows/static-checks.yml` — 安装 kubeconform v0.6.7 并随 `run-static-checks.sh` 执行

本地：

```bash
bash scripts/check-kubeconform.sh
bash scripts/test-kubeconform.sh
```

## 夹具

| 路径 | 期望 |
|------|------|
| `scripts/testdata/kubeconform/good/` | 通过 |
| `scripts/testdata/kubeconform/bad/` | 失败（`extensions/v1beta1` Deployment） |

## 回滚

从 `run-static-checks.sh` 移除 `check-kubeconform.sh` 调用，并删除 workflow 中的 kubeconform 安装步骤即可；`k8s/` 行为不变。
