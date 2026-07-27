# Task 45 — Shell 脚本质量审计

**范围:** `scripts/*.sh`、根目录 `pull.sh`、`vsphere.sh`、相关 git 辅助脚本。
**工具:** `bash -n`、ShellCheck（见 [`scripts/check-shell.sh`](../../scripts/check-shell.sh)）。

## 1. 检查器行为（事实）

`scripts/check-shell.sh`：

- `set -euo pipefail`
- 收集仓库内 `*.sh`，排除：`.git/`、`scripts/testdata/`、`.git-askpass.sh`、**`vsphere.sh`**
- 仅对「首部像 shebang 文本」的文件跑 `bash -n`；若安装了 `shellcheck` 则以 `-S error` 检查

因此：**自解压 / 二进制拼接的 `vsphere.sh` 被有意跳过**，避免误报与误读。

## 2. 分项结果

### 2.1 `scripts/` 静态检查脚本

| 脚本 | `set -euo pipefail` | 备注 |
|------|---------------------|------|
| `check-shell.sh` | 是 | 元检查器 |
| `check-yaml-json.sh` | 宜保持与仓库一致 | 以文件为准 |
| `check-secrets.sh` | 宜保持 | 含密钥模式检测 |
| `check-placeholders.sh` | 宜保持 | |
| `check-deprecated-api.sh` | 宜保持 | |
| `check-markdown-links.sh` | 宜保持 | |
| `check-trailing-whitespace.sh` | 宜保持 | |
| `check-archived-isolation.sh` | 宜保持 | |
| `check-repo-path-refs.sh` | 宜保持 | |
| `run-static-checks.sh` | 宜保持 | 聚合入口 |
| `test-static-checks.sh` / `test-check-secrets.sh` | 宜保持 | 自测 |

新脚本必须：`#!/usr/bin/env bash`（或明确 `sh`）+ `set -euo pipefail` + 可被 `check-shell.sh` 覆盖。

### 2.2 `pull.sh`

| 项 | 状态 |
|----|------|
| `set -euo pipefail` | **否**（仅条件 `set -e`） |
| 引号 / SC 建议 | 多处未加引号的 `$pullName`、`$1` |
| 现代化 | 见 [`pull-script-modernization.md`](./pull-script-modernization.md)；**本 Task 不改文件** |

建议（未来变更）：补严格模式与引号，或冻结为 legacy 并指向 modern 设计。

### 2.3 `vsphere.sh`（自解压 / 嵌入载荷）

| 项 | 说明 |
|----|------|
| 文件类型 | `file` 报含 binary data；前部为 POSIX 自解压 stub（`skip=44`，`gzip -cd` 后执行） |
| 用途 | README：vSphere 侧磁盘处理辅助 |
| ShellCheck | **排除**（`check-shell.sh`） |
| 审计注意 | 可能为 **makeself 类或口令保护的自解压包** |

**安全与文档约束（重要）：**

- 审计只描述「存在自解压 stub / 可能口令保护」这一事实。
- **禁止**在文档、工单、聊天中打印、转录或提交解压后的明文密码、许可证密钥或内嵌凭证。
- 需要运行时：在受控环境按现网规程执行；口令走现网密钥系统（**现网定义**），不写入本仓库。
- 勿用 `strings`/`hexdump` 输出把疑似密钥贴进 Git。

### 2.4 其他根脚本

| 文件 | 备注 |
|------|------|
| `git-auth.sh` / `git-push.sh` | 辅助推送；勿在日志中 echo 凭证；`.git-askpass.sh` 已被 check-shell 排除 |
| `.env` | **本审计不读取内容**；应在 `.gitignore` 中；密钥轮换见 Wiki SRE-07 |

## 3. 改进建议（不自动执行）

1. 保持 CI 调用 `scripts/run-static-checks.sh`（含 shell 检查）。
2. `pull.sh` 单开 PR 做严格模式或标记 deprecated。
3. `vsphere.sh` 继续排除 ShellCheck；在 `README` / 本审计中保留「自解压、勿倾倒密钥」警告即可。
4. 新增脚本一律对标 `scripts/testdata/shell/good.sh` 风格。

## 4. 验收

- [ ] `scripts/check-shell.sh` 在干净树上可运行
- [ ] 无文档泄露 `vsphere.sh` 或 `.env` 中的秘密
- [ ] 已知例外（`vsphere.sh`、askpass）有书面理由
