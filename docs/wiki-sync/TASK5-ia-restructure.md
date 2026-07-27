# Wiki Task 5 — 信息架构整理（跟踪 PR）

**Wiki 分支:** `wiki/ia-restructure`（`a307582707/TomYang.wiki`）

## 修改摘要
- 重排 `Home.md`：增加推荐阅读顺序；明确 INFRA-01 为操作权威
- 新增 `_Sidebar.md` 侧栏导航
- 新增 `历史文章归档` 作为附录入口
- **未**改写各文技术结论

## 合并方法
```bash
git clone https://github.com/a307582707/TomYang.wiki.git
cd TomYang.wiki
git fetch origin wiki/ia-restructure
git checkout master
git merge --ff-only origin/wiki/ia-restructure
git push origin master
```

## 检查结果
- [x] Home 四条主线 + 阅读顺序
- [x] Sidebar 链接指向现有页面
- [x] 未触碰凭据

## 风险说明
- Sidebar 依赖 GitHub Wiki 对 `_Sidebar.md` 的支持（GitHub 原生支持）

## 未解决事项
- 历史页顶部归档横幅（Task 7）
- INFRA 冲突消除（Task 6）

## 回滚方法
Wiki：`git revert` 合并提交或重置 `Home.md` / 删除 `_Sidebar.md` 与归档页。
