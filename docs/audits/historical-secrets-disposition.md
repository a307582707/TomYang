# Task 103 — 历史凭据泄露处置说明

**范围:** Git 历史中曾出现的 **样例** 口令（典型：旧版 Grafana admin Secret、HAProxy stats 默认认证）。**本文件为文档-only；不执行历史改写。**

**关联:** [`remaining-security-remediation.md`](./remaining-security-remediation.md) §4、`scripts/check-secrets.sh`、`examples/current/security/secret-injection-note.md`

---

## 1. 现状

| 项 | 说明 |
|----|------|
| **工作区 HEAD** | Grafana / HAProxy stats 等已改为 `stringData` 占位符（如 `{{ GRAFANA_ADMIN_PASSWORD }}`）；静态检查拒绝常见默认凭据回灌 |
| **Git 历史** | 早期提交可能仍含 **教材样例** 明文口令（Grafana `admin` 类组合、stats 默认认证等）。克隆/fork 任意旧 commit 均可读到 |
| **风险性质** | 样例 ≠ 生产机密，但若现网曾直接使用或从未轮换，则与历史泄露等价 |

> **禁止** 在本仓库 Issue/PR/文档中复述历史样例口令全文。排查时用 `git log -S` / `git log -G` 自行审计，输出脱敏。

---

## 2. 生产强制要求

1. **不得** 复用 Git 历史中出现过的任何样例口令（含 Grafana admin、HAProxy stats、Dashboard token 等）。
2. 现网 Secret **必须** 经 CI/CD、External Secrets、Sealed Secrets 或等价保险箱注入；**不得** 将未渲染占位符 apply 到集群。
3. 若某环境曾在任意时期使用过历史样例值，视为 **已泄露**：立即轮换并审计访问日志，**不要** 假设「只是教材所以安全」。
4. 新部署对齐 `examples/current/observability/grafana-skeleton.yml` 与 `examples/current/security/` 下的注入说明。

---

## 3. 推荐处置（默认路径）

### 3.1 凭据轮换（必做）

| 步骤 | 动作 |
|------|------|
| 1 | 盘点现网 Grafana、HAProxy stats、及相关 Dashboard/监控入口是否仍用默认或历史样例 |
| 2 | 生成强随机口令，经批准渠道写入 Secret Store / `kubectl create secret`（不入 Git） |
| 3 | 滚动重启依赖该 Secret 的工作负载；确认匿名登录关闭（`GF_AUTH_ANONYMOUS_ENABLED=false`） |
| 4 | 验证旧样例口令 **无法** 登录；记录轮换日期与负责人 |

### 3.2 检测与防回归

- 合并前：`bash scripts/check-secrets.sh`（CI 已跑）
- 季度复查：见 [`quarterly-review-2026-Q3.md`](./quarterly-review-2026-Q3.md)「危险模式 / 密钥」节
- 新贡献者：阅读 [`examples/current/security/README.md`](../../examples/current/security/README.md)

---

## 4. 可选：Git 历史清理

工具示例：**git filter-repo**、**BFG Repo-Cleaner**（将历史中的特定字符串替换或删除）。

| 优点 | 缺点 |
|------|------|
| 减少 fork/clone 时无意复制样例口令 | **重写所有 commit SHA**；所有 fork 与 open PR 需协调 |
| 对外合规叙事更清晰 | 丢失原有 blame/ bisect 上下文；操作不可逆 |
| | 无法保证已泄露口令未被人保存；**轮换仍是必做** |
| | 教材仓库 star/fork 多时不易通知全员 force-pull |

### 4.1 默认：**不** 重写历史（推荐）

维护者 **默认选择保留历史**，理由：

1. **有效性：** 轮换现网凭据直接消除可利用性；清 Git 不能撤回已泄露秘密。
2. **成本：** 历史改写需全员 `git fetch --all` + 重置分支，破坏开放 PR 与外部引用。
3. **性质：** 泄露内容为 **已知样例**，非生产随机密钥；风险已通过 HEAD 占位符化 + CI + 文档约束收敛。
4. **审计:** 保留历史有助于说明「为何禁止复用样例」；过度清洗可能掩盖整改前后对比。

若法务/合规 **明确要求** 从历史删除特定模式，在 **维护者窗口期** 单独变更单执行，并：

- 事前公告所有协作者与 fork 维护者
- 备份完整镜像后再跑 filter-repo/BFG
- 强制推送后关闭需 rebase 的旧 PR
- **仍** 完成 §3.1 现网轮换

**本 Task 不执行任何历史改写命令。**

---

## 5. 验收标准

- [ ] 现网 Grafana / stats 等入口不使用历史样例口令
- [ ] Secret 注入路径 documented 且与 `examples/current` 一致
- [ ] `bash scripts/check-secrets.sh` 通过
- [ ] 维护者已阅读本文并确认是否需（可选）历史清理变更单

## 6. 回滚

- 文档-only：删除本文件即可。
- 若已轮换凭据：回滚至 **上一 Secret 版本**（集群内），**不要** 恢复历史样例值。
- 若已执行历史改写：从改写前备份镜像恢复 remote（需维护者协调，非本 Task 范围）。

---

## 参考

- [`remaining-security-remediation.md`](./remaining-security-remediation.md) §3 HAProxy stats、§4 Grafana
- [`hygiene-acceptance-2026-07-27.md`](./hygiene-acceptance-2026-07-27.md)
- GitHub Issues [#71](https://github.com/a307582707/TomYang/issues/71)–[#73](https://github.com/a307582707/TomYang/issues/73)（并行安全跟踪，非历史清理专用）
