# Task 55 — 季度复查自动化设计

## 行为

- 脚本：`scripts/quarterly/run-quarterly-review.sh`
- **只生成** `docs/audits/quarterly-review-YYYYMMDD.md` 报告草稿
- 可选：维护者将报告粘贴为 Issue（脚本不自动开 Issue，除非设置 `CREATE_GITHUB_ISSUE=1` 且已配置 `gh`——默认关闭）

## 覆盖

EOL 提醒、CVE（人工）、镜像可用性（人工）、链接、静态检查、维护日期、高风险遗留

## 禁止

- 自动升级组件  
- 自动修改 Wiki  
- 自动合入 PR  

## 回滚

删除脚本与说明文档。
