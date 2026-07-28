# Task 97 — 归档 metrics-server 禁用路径文档化

**Issue:** [#72](https://github.com/a307582707/TomYang/issues/72)  
**日期:** 2026-07-29

## 修改摘要

- 强化 `k8s/archived/metrics-server/README.md`：明确 **禁止 apply**、风险表、现代 skeleton 直链
- 交叉引用：`README.md`、`examples/current/observability/`、`examples/current/security/`、季度复查与 remaining-security-remediation

## 禁用路径（权威）

```text
k8s/archived/metrics-server/          → 禁止 apply
k8s/addons/metrics-server/            → stub，指向 archived
examples/current/observability/       → 现网/实验推荐入口
```

## 验证

- [x] 归档 README 含 skeleton 链接与验收清单
- [x] 主 README「禁止直接 apply」表仍覆盖 metrics-server stub
- [x] `docs/audits/quarterly-review-2026-Q3.md` 仍标注禁止 insecure 清单

## 风险

- 文档变更无运行时影响；现网若仍运行归档清单需人工下线（本 PR 不触达集群）

## 遗留

- 现网 metrics-server 版本与 Helm release 名需维护者自行核对（Issue #72 验收项）

## 回滚

`git revert` 本 PR；文档回退不影响已部署的现代 metrics-server。
