# 贡献指南

感谢参与 TomYang（上海海曦技术）仓库维护。

## 边界

| 区域 | 说明 |
|------|------|
| `k8s/` | 历史 Kubernetes 1.11 自建清单（教材）；谨慎修改，优先审计文档 |
| `k8s/archived/` | **禁止部署** 的高风险历史件 |
| `examples/current/` | 现代示例基线；新功能优先放这里 |
| Wiki | 操作正文权威；仓库 `wiki/` 仅指针 |
| `.env` / Token / 私钥 | **禁止**读取、提交、粘贴到 Issue/PR |

## 分支命名

- `fix/...` `fix/...` `docs/...` `audit/...` `rename/...` `ci/...`
- 每个主题独立分支、独立 PR

## Commit

- 使用祈使句、说明动机（why）
- 不使用 `--no-verify` 绕过钩子（除非维护者明确要求）

## PR 要求

使用仓库 PR 模板，至少包含：修改摘要、验证结果、风险、遗留事项、回滚方法。
区分「修改历史清单」与「现代示例」。

## 清单修改验证

合并前尽量运行：

```bash
bash scripts/run-static-checks.sh
```

## Wiki 修改流程

1. 克隆 `TomYang.wiki.git`
2. 在独立分支修改并自测链接
3. 仓库侧可用 `docs/wiki-sync/` 跟踪说明
4. 合并前备份 Wiki `master`（打 tag）

## 审查责任

见以下文件（内容应保持一致）：

- [`CODEOWNERS`](./CODEOWNERS)（仓库根，GitHub 识别）
- [`.github/CODEOWNERS`](./.github/CODEOWNERS)（与根文件同步副本，避免合并顺序导致瞬时断链）
- [`docs/CODEOWNERS-matrix.md`](./docs/CODEOWNERS-matrix.md)

默认审查人为仓库维护者 `a307582707`。

### 合并顺序注意

若 PR 仅新增 `CONTRIBUTING.md` 并链接 `CODEOWNERS`，而 `CODEOWNERS` 在后续 PR 才合入，CI 的 Markdown 链接检查会在中间态失败。约定：

1. 链接目标文件与引用放在**同一 PR**，或
2. 先合入目标文件再合入引用，或
3. 临时用纯文本路径（无 Markdown 链接）直至目标存在

`scripts/test-static-checks.sh` / 链接检查会验证上述路径在完整 `master` 上可解析。

## 安全报告

见 [`SECURITY.md`](./SECURITY.md)。
