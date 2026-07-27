# Task 44 — `pull.sh` 现代化审计与设计

**审计对象:** 仓库根目录 [`pull.sh`](../../pull.sh)
**约束:** **不覆盖**现有 `pull.sh`；现代化方案以设计文档落地，实现脚本可选另建。

## 1. 现状摘要

| 项 | 观察 |
|----|------|
| Shebang | `#!/bin/bash` |
| 错误处理 | `[ -z "$set_e" ] && set -e` — 非标准；无 `pipefail` / `-u` |
| 功能 | `sync_pull`：将 `gcr.io` / `k8s.gcr.io` / `quay.io` 镜像改写到国内同步名，`docker pull` → `tag` → `rmi` |
| 子命令 | `$1 == search` 时查询 GitHub `zhangguanzhang/${repository}` 目录列表（需 `jq`） |
| 运行时 | 假定主机 Docker；无 containerd / `crictl` / `nerdctl` 路径 |
| 镜像源 | 硬编码 `azk8s.cn`、`zhangguanzhang/...` 等历史同步约定 |

`README.md` 描述：通过国内镜像源同步 `gcr.io` / `k8s.gcr.io` / `quay.io`。

## 2. 问题清单

1. **注册表现实变化:** `k8s.gcr.io` → `registry.k8s.io`；GCR 路径与第三方同步仓可能失效。
2. **运行时锁定 Docker:** 现网节点多为 containerd（见 `examples/current/runtime/`）。
3. **Shell 质量:** 未 `set -euo pipefail`；变量未充分加引号；与 `scripts/check-shell.sh` 期望不一致。
4. **可配置性差:** 镜像前缀、代理、重试、架构（amd64/arm64）无法用环境变量声明。
5. **search 依赖 GitHub API:** 不稳定且与拉取主路径耦合。
6. **无清单模式:** 不能从文件批量拉取教材镜像列表。
7. **安全:** 不应在脚本中嵌入仓库密码；凭证走环境或 credential helper（**不**读、不记录 `.env` 内容）。

## 3. 提议产物

可选实现路径（二选一即可，**均不修改** `pull.sh`）：

- A. 新建 `scripts/pull-images-modern.sh`（实现时另开变更）
- B. 仅保留本文件中的设计，待现网镜像策略确定后再编码

以下设计可同时存为 `scripts/pull-images-modern.sh.design.md`（与本文等价）；若创建独立文件，内容应与本节同步。

---

## 4. 设计：`scripts/pull-images-modern.sh`（拟）

### 4.1 目标

- 从**显式镜像列表**或参数拉取并（可选）retag 到现网仓库前缀。
- 支持 `docker` **或** `nerdctl` / `crictl`（通过 `PULL_RUNTIME`）。
- 所有远程前缀、重试次数可配置；**无**写死生产 registry 密码。
- `set -euo pipefail`；通过 `scripts/check-shell.sh`。

### 4.2 接口草图

```bash
# 环境变量（示例名，值现网定义）
# PULL_RUNTIME=docker|nerdctl|crictl
# DEST_REGISTRY_PREFIX=          # 空则只拉取源名
# MAX_RETRIES=3
# IMAGE_LIST_FILE=path/to/images.txt

./scripts/pull-images-modern.sh ghcr.io/example/app:1.2.3
./scripts/pull-images-modern.sh --list ./images.txt
```

### 4.3 行为

1. 校验运行时二进制存在。
2. 对每个引用：拉取 → 若设置了 `DEST_REGISTRY_PREFIX` 则 tag →（可选）push（默认 **关闭** push，避免误推）。
3. 失败重试有限次数；汇总失败列表后以非零退出。
4. 不实现 GitHub `search` 爬取；目录发现改用现网文档或 `crane`/`skopeo`（可选，非必须）。

### 4.4 与 `pull.sh` 共存

| 文件 | 角色 |
|------|------|
| `pull.sh` | 保留历史教材行为；标注可能失效的同步源 |
| `scripts/pull-images-modern.sh` | 新集群 / CI 镜像预热（实现后） |
| 本文 | 设计与审计 SSOT |

### 4.5 非目标

- 不在本 Task 改 CI 强制切换。
- 不提交任何 registry 账号或 token。
- 不自动扫描集群并拉取全部镜像。

## 5. 验收（文档）

- [ ] 确认未修改 `pull.sh` 内容
- [ ] 设计覆盖 runtime / 配置 / 错误处理
- [ ] 实现 PR（若有）需挂 ShellCheck 与静态检查
