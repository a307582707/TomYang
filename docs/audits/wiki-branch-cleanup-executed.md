# Task 93 — Wiki 远程分支清理验证

**验证时间:** 2026-07-29（UTC+8）  
**依据:** Task 74 执行记录（`docs/audits/branch-cleanup-executed.md`）；本任务为**事后复核**，不执行删除。

## 验证方法

```bash
# 使用 token 化 URL；日志须脱敏 token
git ls-remote --heads  https://x-access-token:***@github.com/a307582707/TomYang.wiki.git
git ls-remote --tags   https://x-access-token:***@github.com/a307582707/TomYang.wiki.git
```

## 删除前（Task 74 记录）

Task 74 计划删除的 Wiki 主题分支：

| 分支 | 状态（Task 74） |
|------|-----------------|
| `wiki/ia-restructure` | 已合入 master，待删 |
| `wiki/infra-consistency` | 已合入 master，待删 |
| `wiki/archive-banners` | 已合入 master，待删 |

保留：`master`；tag `backup/wiki-master-20260727`。

## 删除后 — 本次 `git ls-remote` 结果

### Heads（2026-07-29）

| ref | commit（abbrev） |
|-----|------------------|
| `refs/heads/master` | `0a8d2cf4` |

**结论：** 远程 **仅** 存在 `master`；Task 74 所列三主题分支 **已不存在**（无需再次删除）。

### Tags

| ref | commit（abbrev） |
|-----|------------------|
| `refs/tags/backup/wiki-master-20260727` | `d353e7e8` |

**结论：** 备份 tag **仍存在**；符合 Task 74 保留策略。

## 执行摘要

| 项 | 结果 |
|----|------|
| 本次待删分支列表 | **空**（已在 Task 74 完成） |
| 远程 heads 数量 | 1（`master`） |
| `backup/wiki-master-20260727` | 存在 |
| 误删 `master` | 否 |
| 误删 backup tag | 否 |

## 与主仓对照

主仓 Task 74 后远程亦仅 `origin/master`（见 `docs/audits/branch-cleanup-executed.md`）。Wiki 与主仓分支策略一致：单一 `master` + 可选备份 tag。

## 回滚

若误删 Wiki 分支，可从已合并 PR 的 merge commit 恢复：

```bash
git push origin <sha>:refs/heads/<branch-name>
```

若需从 tag 恢复 master 快照：

```bash
git fetch origin tag backup/wiki-master-20260727
# 在维护者确认后按需 cherry-pick 或 reset（勿 force-push master 除非已协调）
```
