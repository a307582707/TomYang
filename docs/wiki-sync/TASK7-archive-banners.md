# Wiki Task 7 跟踪 — 历史教程归档

**Wiki 分支:** `wiki/archive-banners`

## 修改摘要
- 为 AI-01～04、kubectl/OSI/TCP、企业级搭建长文、AsciiDoc 历史页增加醒目【历史归档】横幅
- 指向 INFRA-01 / AIDC-01 / 历史文章归档
- **未删除**任何历史内容

## 合并
```bash
git fetch origin wiki/archive-banners
git checkout master && git merge --ff-only origin/wiki/archive-banners && git push
```

## 检查结果 / 风险 / 回滚
仅文档横幅；不合并即回滚。注意 Task5/6/7 Wiki 分支可能需按序合并以免冲突。
