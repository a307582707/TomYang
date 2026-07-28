# Scripts — static checks

本目录包含 TomYang 仓库静态检查脚本。入口：`scripts/run-static-checks.sh`（CI 与本地相同）。

## Wiki 链接

- **检查：** `scripts/check-wiki-links.sh`
- **测试：** `scripts/test-wiki-links.sh`
- **文档：** [docs/audits/wiki-link-check.md](../docs/audits/wiki-link-check.md)

默认对公共 Wiki 做只读浅克隆；离线开发请设 `WIKI_FIXTURE_DIR=scripts/testdata/wiki-links/good`。

## 其他常用脚本

| 脚本 | 说明 |
|------|------|
| `check-modern-examples.sh` | `examples/current` 现代 API 基线 |
| `check-kubeconform.sh` | （Task 83 分支）schema 校验 |
| `test-static-checks.sh` | YAML/secret/shell 等夹具总集 |
