# Task 55 — 季度复查自动化设计

## 行为

- 脚本：`scripts/quarterly/run-quarterly-review.sh`
- **只生成** `docs/audits/quarterly-review-YYYY-QN.md` 报告草稿（如 `2026-Q3`）
- 可选：维护者将报告粘贴为 Issue（脚本不自动开 Issue，除非设置 `CREATE_GITHUB_ISSUE=1` 且已配置 `gh`——默认关闭）

## 覆盖

EOL 提醒、CVE（人工）、镜像可用性（人工）、链接、静态检查、维护日期、高风险遗留

**台账脚本：** `scripts/check-maintenance-ledger.sh`（`--json` 供季度报告嵌入；`run-quarterly-review.sh` 已调用）

| 检查项 | 说明 |
|--------|------|
| 全局/组件「下次复查」 | 过期 → exit 1 |
| 归档路径引用 | 须含「归档/禁止」类说明 |
| 高风险组件 | 缺 `#NN` Issue 引用时 warn（`MAINTENANCE_LEDGER_STRICT_ISSUES=1` 升级为 fail） |

## 禁止

- 自动升级组件  
- 自动修改 Wiki  
- 自动合入 PR  

## 回滚

删除脚本与说明文档。
