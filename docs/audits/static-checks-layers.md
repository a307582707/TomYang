# Task 63 — 静态检查分层

本仓静态检查分两层，**避免**用现代 schema 规则误伤历史教材清单。

## 历史层（`k8s/`、`k8s/archived/`）

| 脚本 | 行为 |
|------|------|
| `scripts/check-deprecated-api.sh` | 盘点 `extensions/v1beta1` 等；默认 **告警不失败**（`STRICT_DEPRECATED=1` 可严格） |
| `scripts/check-secrets.sh` 等 | 全仓敏感信息 / YAML / 占位符等通用规则 |
| `scripts/check-archived-isolation.sh` | 归档隔离约定 |

历史层**允许**（作为教材/反例）存在废弃 API；整改见审计文档，默认不改 manifest。

## 现代层（仅 `examples/current/`）

| 脚本 | 行为 |
|------|------|
| `scripts/check-modern-examples.sh` | **只扫描** `examples/current/` |

硬性失败：

- `apiVersion: extensions/v1beta1` / `apps/v1beta1` / `apps/v1beta2`
- Deployment 非 `apps/v1`；Ingress / NetworkPolicy 非 `networking.k8s.io/v1`
- `image: …:latest`

默认告警（`MODERN_EXAMPLES_STRICT=1` 时变失败）：

- Deployment 缺少 `runAsNonRoot: true`
- Deployment 缺少 `resources.requests`
- Deployment 缺少 readiness / liveness probe

**明确不在现代层失败范围内:** `k8s/**`、`k8s/archived/**`（即使含 `extensions/v1beta1`）。

## 聚合入口

`scripts/run-static-checks.sh` 依次调用历史向检查 + `check-modern-examples.sh` + `check-wiki-links.sh` 等。

## 本地示例

```bash
bash scripts/check-modern-examples.sh
MODERN_EXAMPLES_STRICT=1 bash scripts/check-modern-examples.sh
bash scripts/run-static-checks.sh
```
