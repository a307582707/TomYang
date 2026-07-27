# 上海海曦技术 · 运维与平台工程实践

生产故障复盘、架构取舍、容量成本、发布治理与平台建设记录。  
内容来自真实排障与落地过程，含时间线、命令、指标与防再发动作。

| 编号 | 主题 | 文章 | 案例 |
|------|------|------|------|
| 01 | 生产事故复盘 | [01-incident-postmortem.md](./01-incident-postmortem.md) | kubelet 磁盘压力导致大面积 NotReady |
| 02 | 架构决策 | [02-architecture-decisions.md](./02-architecture-decisions.md) | 暂缓全量 Istio；业务交付不全量 Helm |
| 03 | 容量与成本 | [03-capacity-cost.md](./03-capacity-cost.md) | 闲置资源治理，月成本下降 38% |
| 04 | 可观测性 | [04-observability.md](./04-observability.md) | 一次 2.3s 慢请求的端到端定位 |
| 05 | 发布与回滚 | [05-release-rollback.md](./05-release-rollback.md) | 金丝雀指标健康，数据库却被迁移拖垮 |
| 06 | 平台化 | [06-platform-selfservice.md](./06-platform-selfservice.md) | 从工单交付到 GitOps 自服务 |
| 07 | 安全与权限 | [07-security-rbac.md](./07-security-rbac.md) | CI 泄漏 Token 的 45 分钟应急 |
| 08 | 深度专题 | [08-deep-dive-node-notready.md](./08-deep-dive-node-notready.md) | Node NotReady 根因图谱与处置手册 |
