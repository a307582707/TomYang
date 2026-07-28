# GitHub Actions 失败通知策略（Task 101）

**范围:** 本仓库 CI（`static-checks` 等）。**不**要求配置 Slack / 外部 Webhook Secret。

## 目标

- 维护者在 PR / push 失败时能发现、定位、修复
- 不引入需长期保管的第三方通知凭据

## 默认通知（零 Secret）

| 渠道 | 行为 | 配置 |
|------|------|------|
| GitHub Checks | PR 与 push 上显示失败步骤 | 工作流自带 |
| PR 作者 | 合并被保护分支规则 / 必需检查拦截 | 仓库 Settings → Branches |
| Commit 状态 | `master` push 失败在 Commits 页可见 | 默认 |
| Dependabot PR | 依赖更新 PR 同样跑 `static-checks` | `.github/dependabot.yml` |

**推荐:** 维护者启用 GitHub 账号 **Notifications → Actions**（失败时邮件或 Web，无需仓内 Secret）。

## 可选增强（仍无需 Slack Secret）

| 方式 | 说明 |
|------|------|
| `issues: write` + 失败开 Issue | 仅当工作流内用 `GITHUB_TOKEN` 创建 Issue；需防 Issue 风暴（见下） |
| GitHub Discussions | 人工汇总周期性失败，非实时 |
| 组织级通知规则 | Enterprise / 组织 Settings，仓外配置 |

本仓 **不** 默认添加 `slack-github-action` 或自定义 Webhook；若现网 later 接入，Secret 名与轮换由平台组在仓外 Runbook 维护。

## 失败分流（维护者）

1. 打开失败 run → 展开首个红色 step（多为 `Run static checks`）。
2. 本地复现：`bash scripts/run-static-checks.sh`（与 CI 同命令）。
3. 常见类：
   - **kubeconform** — 占位符 / apiVersion；查 `docs/audits/kubeconform-examples.md`
   - **markdown links** — 本地路径或 Wiki 克隆失败
   - **secrets scanner** — 误报或真实凭据；禁止提交 `.env`
4. Dependabot PR：优先合并 patch/minor；major 须读 action 发行说明。

## 权限原则

工作流级 `permissions` 遵循最小权限（见 `.github/workflows/static-checks.yml`）：

- 默认 `contents: read`
- 不写 packages、不部署、不修改 Issues（除非将来专用 workflow 显式开启）

## 与 Dependabot 的关系

- `dependabot.yml` 每周扫描 `github-actions` 引用
- Action 版本 pin 为 **major tag**（如 `@v4`）或 **commit SHA**；Dependabot 提 PR 后必需检查通过再合并
- 回滚：revert Dependabot 合并 commit 或 pin 回上一 SHA/tag

## 参考

- [GitHub: Encrypted secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Dependabot for GitHub Actions](https://docs.github.com/en/code-security/dependabot/working-with-dependabot/keeping-your-actions-up-to-date-with-dependabot)
- `.github/workflows/static-checks.yml`
