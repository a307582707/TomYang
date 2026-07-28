# Task 84 — Wiki 链接检查（默认静态流水线）

## 脚本

`scripts/check-wiki-links.sh`

## 公共 Wiki 只读克隆策略

| 项 | 策略 |
|----|------|
| 数据源 | `https://github.com/a307582707/TomYang.wiki.git` |
| 认证 | **不需要** token；只读 `git clone --depth 1` |
| 网络失败 | 打印 `WIKI_CHECK_SKIP`，**exit 0**（默认不阻断 CI） |
| 严格模式 | `WIKI_CHECK_STRICT=1` 时克隆失败 → exit 1 |
| 夹具模式 | `WIKI_FIXTURE_DIR=scripts/testdata/wiki-links/good` 离线校验 |

Wiki 内容与主仓分离；CI 仅验证链接目标在克隆快照中存在，**不** push 或修改 Wiki。

## 检查范围

- Wiki 内相对页链接、`.md` 文件名链接
- `github.com/a307582707/TomYang/wiki/Page` 形式
- 页内/跨页 `#anchor`（含中文标题 slug 启发式）
- 指向本仓 `tree|blob` 的路径是否存在
- **忽略**：fenced code 内链接、纯外链（非本仓 tree/blob/wiki）

## 已知假阳性与忽略规则

| 类型 | 行为 |
|------|------|
| fenced code 内 `[假链](...)` | 不扫描 |
| 中文锚点 slug 与 GitHub 渲染差异 | `WARN`；部分模式打印 `IGNORE`（见脚本 `IGNORE_WARN_SUBSTRINGS`） |
| 外链 example.com 等 | 不校验 wiki 页存在性 |
| Wiki 克隆失败 | 默认 skip（非错误） |
| URL 含括号页名 | 使用 `%28`/`%29` 编码，避免 Markdown `)` 截断 |

**硬失败**仅针对：缺失 wiki 页、缺失本仓 repo 路径。

## 夹具（`scripts/testdata/wiki-links/`）

| 目录/文件 | 用途 |
|-----------|------|
| `good/Home.md` | 正常内链、中文页、括号页名 URL 编码 |
| `good/Page (Legacy).md` | 括号页名 |
| `good/Archive-Index.md` | 归档索引式链接 |
| `good/中文页面.md` | 中文锚点 `#备份原则` |
| `good/Drill-Page.md` | 跨页中文锚点 |
| `bad/Broken.md` | 故意断链 |

```bash
bash scripts/test-wiki-links.sh
WIKI_FIXTURE_DIR=scripts/testdata/wiki-links/good bash scripts/check-wiki-links.sh
```

## CI 失败可读性

失败时输出：

```
WIKI_LINK_ERRORS: wiki internal link check failed
wiki_error_count=N
ERRORS:
  [1] Page.md: missing internal page '...'
hint: fix wiki page name/anchor or add fixture ...
```

## 流水线位置

`scripts/run-static-checks.sh` 在打印 `ALL STATIC CHECKS PASSED` **之前** 调用 wiki 检查与 `scripts/test-wiki-links.sh`。

## 回滚

从 `run-static-checks.sh` 移除 wiki 相关两行；删除 `scripts/test-wiki-links.sh` 与扩展夹具即可。
