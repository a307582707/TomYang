# 灾难恢复（Disaster Recovery）文档索引

**任务:** Task 46
**性质:** 索引与占位；RPO/RTO 数值以 **现网定义** 为准，本文不编造生产指标。

## 1. RPO / RTO 占位

| 对象 | RPO | RTO | 备注 |
|------|-----|-----|------|
| etcd | 现网定义 | 现网定义 | 快照频率与演练窗口由平台组核定 |
| 集群清单 / Git | 现网定义 | 现网定义 | 本仓库为教材+清单；非唯一备份 |
| 应用 PVC / 数据库 | 现网定义 | 现网定义 | 不在本仓范围 |
| 镜像与制品 | 现网定义 | 现网定义 | 参见镜像拉取审计 |
| 密钥与证书 | 现网定义 | 现网定义 | 泄露响应见下节 |

填写实际数字时，更新现网 Runbook，并仅在获批后回写本表。

## 2. 文档链接

### 本仓库（已有 / 审计）

| 文档 | 用途 |
|------|------|
| [`docs/MAINTENANCE.md`](../MAINTENANCE.md) | 组件台账、回滚总则 |
| [`docs/SSOT.md`](../SSOT.md) | 事实源速查 |
| [`docs/RELEASE.md`](../RELEASE.md) | 仓库版本与发布检查单 |
| [`docs/audits/`](../audits/) | 各类审计（网络、DNS、安全等） |
| [`docs/adr/ADR-001-cni-selection.md`](../adr/ADR-001-cni-selection.md) | CNI 决策（无安装） |
| [`k8s/master/encryption/`](../../k8s/master/encryption/) | Secret 静态加密配置模板 |
| [`k8s/master/audit/`](../../k8s/master/audit/) | API 审计策略模板 |
| [`k8s/archived/ARCHIVED.md`](../../k8s/archived/ARCHIVED.md) | 禁止部署清单 |

### 计划中（占位，待现网补齐）

| 主题 | 状态 | 说明 |
|------|------|------|
| etcd 快照与恢复 Runbook | 计划 | 步骤正文放 Wiki / 现网库；此处只留入口 |
| 控制面节点重建 | 计划 | 对照 Wiki INFRA-01 |
| 插件（DNS / CNI / Ingress）回滚 | 计划 | 结合 MAINTENANCE 台账 |
| 备份加密与异地副本 | 计划 | 现网定义 |

### Wiki（权威运维正文）

| 主题 | 链接 |
|------|------|
| HA 控制面与节点 | [INFRA-01](https://github.com/a307582707/TomYang/wiki/INFRA-01-本仓HA控制面与节点接入) |
| 发布与回滚 | [SRE-05](https://github.com/a307582707/TomYang/wiki/SRE-05-发布与回滚-金丝雀误判与数据库迁移) |
| Token 泄露应急 | [SRE-07](https://github.com/a307582707/TomYang/wiki/SRE-07-安全与权限-CI泄漏Token应急) |
| Node NotReady | [SRE-08](https://github.com/a307582707/TomYang/wiki/SRE-08-深度专题-Node-NotReady根因图谱) |
| Wiki 目录 | [`wiki/README.md`](../../wiki/README.md) |

## 3. Token / 凭证泄露响应

若发生 CI Token、云密钥、kubeconfig、镜像仓库密码等泄露：

1. **立即**按 Wiki **[SRE-07 — 安全与权限：CI 泄漏 Token 应急](https://github.com/a307582707/TomYang/wiki/SRE-07-安全与权限-CI泄漏Token应急)** 执行（吊销、轮换、审计、通报）。
2. 本仓库侧：确认 `.gitignore` 覆盖 `.env`；运行 `scripts/check-secrets.sh`；**不要**在 Issue/PR 中粘贴秘密。
3. 历史 git 中若曾提交样例口令（见安全审计），现网必须视为已泄露并轮换，不得复用教材样例值。

## 4. 演练原则

- 灾难恢复演练在**指定演练环境**进行，不在本索引文档触发自动恢复脚本。
- 每次演练记录实际 RPO/RTO 观测值，用于校正「现网定义」表。
