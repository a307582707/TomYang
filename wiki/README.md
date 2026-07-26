# 运维开发 Wiki：让人愿意读、也看得出你做过系统

本目录按「吃香题材」组织，每篇都是**可直接改写后发布**的样板：带时间线、命令、取舍和防再发动作。  
写作原则：**少讲概念，多讲决策、事故与度量**。

| 编号 | 题材 | 文章 | 典型案例 |
|------|------|------|----------|
| 01 | 生产事故复盘 | [01-incident-postmortem.md](./01-incident-postmortem.md) | kubelet 磁盘压力导致大面积 NotReady |
| 02 | 架构决策（为什么不用 X） | [02-architecture-decisions.md](./02-architecture-decisions.md) | 为什么我们暂不上 Istio / 不全量 Helm |
| 03 | 容量与成本 | [03-capacity-cost.md](./03-capacity-cost.md) | 闲置资源治理，月成本下降 38% |
| 04 | 可观测性落地 | [04-observability.md](./04-observability.md) | 一次 2.3s 慢请求的端到端追踪 |
| 05 | 发布与回滚 | [05-release-rollback.md](./05-release-rollback.md) | 金丝雀误判 + 数据库迁移差点全站回滚 |
| 06 | 平台化 / 自服务 | [06-platform-selfservice.md](./06-platform-selfservice.md) | 从工单交付到 GitOps 自服务 |
| 07 | 安全与权限 | [07-security-rbac.md](./07-security-rbac.md) | CI 泄漏 token 的 45 分钟应急 |
| 08 | 深度专题 | [08-deep-dive-node-notready.md](./08-deep-dive-node-notready.md) | Node NotReady 根因图谱（可运维手册） |

## 怎么用这些样板

1. 把案例里的业务名、集群名、数值换成你们真实数据。  
2. 保留「误判 → 纠正」结构，这是可信度来源。  
3. 每篇结尾固定三块：**止血动作 / 根因 / 防再发（Owner + 截止日期）**。  
4. 对外发文前脱敏：域名、账号、内网 IP、真实账单数字可做比例缩放。
