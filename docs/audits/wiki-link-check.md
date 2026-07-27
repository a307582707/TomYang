# Task 62 — Wiki 链接检查

## 脚本

`scripts/check-wiki-links.sh`

- 默认只读 `git clone --depth 1` 公共仓库 `https://github.com/a307582707/TomYang.wiki.git` 到临时目录（**无需 token**）。
- 检查：wiki 内链页是否存在、页内/跨页锚点（含中文标题启发式）、以及指向 `github.com/a307582707/TomYang/tree|blob/...` 的路径是否在本仓存在。
- 忽略 fenced code 内的链接，降低假阳性。
- **网络/克隆失败:** 打印 `WIKI_CHECK_SKIP` 并以 **exit 0** 结束；若设 `WIKI_CHECK_STRICT=1` 则失败。

## 夹具

| 目录 | 用途 |
|------|------|
| `scripts/testdata/wiki-links/good/` | 合法内链、中文锚点、代码块假链（不应失败） |
| `scripts/testdata/wiki-links/bad/` | 故意断链 |

```bash
# 夹具应通过
WIKI_FIXTURE_DIR=scripts/testdata/wiki-links/good bash scripts/check-wiki-links.sh

# 夹具应失败
WIKI_FIXTURE_DIR=scripts/testdata/wiki-links/bad bash scripts/check-wiki-links.sh; echo exit=$?
```

## CI

由 `scripts/run-static-checks.sh` 调用。克隆失败不阻断默认流水线。
