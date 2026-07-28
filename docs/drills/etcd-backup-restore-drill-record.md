# etcd 备份恢复演练记录（模板 + 桌面样本）

**适用:** 仅 Lab / 桌面推演。**禁止**连接生产 etcd 或未授权集群。
**Runbook 对照:** [`etcd-backup-restore.md`](../runbooks/etcd-backup-restore.md)

---

## 1. 演练记录模板（复制使用）

| 字段 | 填写说明 |
|------|----------|
| **演练编号** | `LAB-ETCD-YYYYMMDD-NN`（例 `LAB-ETCD-20260728-01`） |
| **类型** | [ ] 桌面推演 [ ] Lab 实操 [ ] 快照-only 校验 |
| **环境** | 虚构 lab 名称；**勿**填生产集群名 / 真实 VIP |
| **RPO 目标** | 可接受的最大数据丢失窗口（见 §4） |
| **RTO 目标** | 从决策恢复到 API 可用的最长时间（见 §4） |
| **快照来源** | `{{ SNAPSHOT_PATH }}` + sha256（虚构路径即可） |
| **执行人 / 监督人** | 姓名或角色 |
| **开始 / 结束 UTC** | ISO8601 |

### 1.1 步骤清单

| # | 步骤 | 勾选 | 失败注入点 | 预期观察 | 回滚动作 |
|---|------|------|------------|----------|----------|
| 1 | 快照 `etcdctl snapshot save` | [ ] | — | 文件落盘 | 删除错误快照 |
| 2 | `snapshot status` + sha256 | [ ] | FI-E1：损坏 hash | status 失败 | 重拍快照 |
| 3 | 异地密文下载/解密（若适用） | [ ] | FI-E2：密钥不可用 | 解密失败 | 换备份副本 |
| 4 | 停止 etcd / 备份 data-dir | [ ] | — | 进程停；`.bak` 存在 | 从 `.bak` 还原 |
| 5 | `snapshot restore`（单节点或多成员） | [ ] | FI-E3：错误 `initial-cluster-token` | 成员无法 join | 停 etcd → 恢复 `.bak` |
| 6 | `endpoint health` / `member list` | [ ] | FI-E4：单成员 down | 多数派仍 healthy | `member remove` + 重建 |
| 7 | apiserver `/healthz` + 测试 ConfigMap | [ ] | — | 读写成功 | 回滚 apiserver 证书 |
| 8 | 记录 RPO/RTO 实测 | [ ] | — | 填 §4 表格 | N/A |

**结果:** [ ] 通过 [ ] 部分通过 [ ] 失败（根因：________）

**后续动作:** ________

---

## 2. 桌面推演样本（虚构 Lab — 勿用于生产）

> **声明:** 以下数据全部为虚构；未连接任何真实 etcd 集群。

| 字段 | 样本值 |
|------|--------|
| 演练编号 | `LAB-ETCD-20260728-01` |
| 类型 | 桌面推演 |
| 环境 | `fictional-lab-cp-3m`（3 master 静态 Pod，etcd v3.3.9 量级） |
| RPO 目标 | ≤ 15 min（日快照 + 每小时增量策略的**假设**） |
| RTO 目标 | ≤ 45 min（单节点 restore + 健康检查） |
| 快照 | `/var/backups/etcd-fictional/etcd-20260728T100000Z.db` hash `a1b2…fictional` |
| 执行人 / 监督人 | 演练员 A / 监督员 B |
| 时间 | 2026-07-28 10:00–10:35 UTC |

### 2.1 推演叙事

1. **T+0** — 确认昨日快照 status 正常；sha256 与备份台账一致。
2. **T+5** — 桌面注入 **FI-E3**：假设操作员误用旧 `initial-cluster-token` 执行 restore。
3. **T+8** — 预期：`member list` 出现幽灵成员；apiserver 间歇 503。
4. **T+12** — **回滚**：停止 etcd → 恢复 `data-dir.bak` → 用原 token 启动 → health 恢复。
5. **T+25** — 重新按 runbook §4 单节点 restore，使用**新** token。
6. **T+32** — `endpoint health` 全绿；创建/删除 `configmap/etcd-drill-test` 成功。
7. **T+35** — 记录实测 RPO/RTO（见下表）。

### 2.2 样本结果

| 指标 | 目标 | 实测（桌面） | 备注 |
|------|------|--------------|------|
| RPO | ≤ 15 min | ~12 min | 假设故障发生在最后一次快照后 12 min |
| RTO | ≤ 45 min | 32 min | 含一次错误 token 回滚 |
| 结果 | — | **部分通过** | 注入 FI-E3 成功触发回滚路径 |

**后续动作:** 更新变更单模板，强调 `initial-cluster-token` 必须新生成；下季度 Lab 实操补测多成员 restore。

---

## 3. 演练前检查清单

- [ ] 变更单已批准；监督人在场
- [ ] 环境确认为 **Lab**，非生产网络
- [ ] 不使用生产证书、Token、`.env` 真实值
- [ ] 快照路径与 hash 已登记（虚构 lab 可填占位）
- [ ] 旧 `data-dir` 备份策略明确（`.bak-$(date +%s)`）
- [ ] apiserver / kubelet 恢复顺序与 runbook 一致
- [ ] 带外/console 可用（避免 VIP+SSH 同时丢失）
- [ ] 演练后清理：删除测试 ConfigMap；保留或销毁 lab 副本 per 策略

---

## 4. RPO / RTO 填写指引

| 概念 | 定义 | 本仓 Lab 建议填法 |
|------|------|------------------|
| **RPO** (Recovery Point Objective) | 可接受丢失的 etcd 写入时间窗口 | 距**最近一次有效快照**的时间差；桌面推演写「假设故障时刻 − 末次快照时刻」 |
| **RTO** (Recovery Time Objective) | 从宣布故障到 API 恢复可用的时长 | 从「停止 etcd / 开始 restore」到「ConfigMap 读写成功」的计时 |
| **测量点** | — | 记录 wall-clock UTC；勿伪造生产 SLA |
| **未达标** | — | 在「后续动作」写缩小 RPO（加密异地快照频率）或 RTO（自动化 restore 脚本） |

**现网:** RPO/RTO 由业务与 SRE 定义；本文件仅为 Lab 模板，**不**替代 [`docs/disaster-recovery/README.md`](../disaster-recovery/README.md)。

---

## 5. 失败注入目录（etcd 专用）

| ID | 注入 | 模拟方式（桌面/Lab） | 预期信号 | 回滚 |
|----|------|----------------------|----------|------|
| FI-E1 | 快照损坏 | 改 sha256 或截断文件 | `snapshot status` 失败 | 换有效快照 |
| FI-E2 | 备份密钥丢失 | 假设 KMS/age 密钥不可用 | 解密失败 | 备用密钥 / 旧副本 |
| FI-E3 | 错误 cluster token | restore 时用旧 token | 脑裂 / 幽灵成员 | 停 etcd → `.bak` → 原配置 |
| FI-E4 | 单成员不可用 | 停一台 etcd 静态 Pod | 3 节点丢 1 仍多数派 | 拉起成员 |
| FI-E5 | 证书 SAN 不匹配 | 换错误 apiserver PEM（单节点） | 该 backend DOWN | 还原 PEM |

> **禁止:** 在仍有存活多数派的集群上对部分节点单独 restore 成另一 token（见 runbook §5）。

---

## 6. 回滚总则

1. 停止新 etcd 进程 / 静态 Pod。
2. 恢复 `data-dir.bak` 与原 `initial-cluster` 配置。
3. 确认 `endpoint health` 与 apiserver `/healthz`。
4. 若仍失败，评估从**另一份**快照 restore（新维护窗口）。

文档-only：revert 本文件即可。
