# Task 94 — Wiki 现代示例基线条目同步记录

**同步时间:** 2026-07-29（UTC+8）  
**Wiki 目标:** `TomYang.wiki` → `master`  
**主仓:** 本文件为同步台账；**未**将 Wiki 长文复制回 `wiki/` 目录。

## 修改页面

| 页面 | 变更摘要 |
|------|----------|
| [Home](https://github.com/a307582707/TomYang/wiki/Home) | 新增「现代示例基线 vs 历史教材」；骨架与 Runbook 链接表 |
| [_Sidebar](https://github.com/a307582707/TomYang/wiki/_Sidebar) | 侧栏增加「现代基线」入口 |
| [INFRA-01](https://github.com/a307582707/TomYang/wiki/INFRA-01-本仓HA控制面与节点接入) | §9 现代清单与 Runbook；stats bind 占位符说明 |
| [05-可观测性](https://github.com/a307582707/TomYang/wiki/05-可观测性与运维：Metrics-日志-监控) | 明确 skeleton 直链（metrics-server / logging / monitoring / ingress） |

## 边界说明（Wiki 正文已写入）

```text
k8s/ + k8s/archived/   → 历史教材 / 禁止 apply 反例
examples/current/      → 现代基线（apps/v1、Ingress v1、可观测性 skeleton）
docs/runbooks/         → 运维 Runbook（主仓 blob 链接，非 Wiki 副本）
```

## 骨架直链（主仓）

| 组件 | 路径 |
|------|------|
| metrics-server | [`examples/current/observability/metrics-server-skeleton.yml`](https://github.com/a307582707/TomYang/blob/master/examples/current/observability/metrics-server-skeleton.yml) |
| Ingress | [`examples/current/ingress/`](https://github.com/a307582707/TomYang/tree/master/examples/current/ingress) |
| 日志（Fluent Bit） | [`examples/current/observability/logging/`](https://github.com/a307582707/TomYang/tree/master/examples/current/observability/logging) |
| 监控栈 skeleton | [`examples/current/observability/monitoring-stack-skeleton/`](https://github.com/a307582707/TomYang/tree/master/examples/current/observability/monitoring-stack-skeleton) |

## Runbook 直链（主仓 blob）

| 主题 | 路径 |
|------|------|
| etcd 备份恢复 | [`docs/runbooks/etcd-backup-restore.md`](https://github.com/a307582707/TomYang/blob/master/docs/runbooks/etcd-backup-restore.md) |
| 证书轮换 | [`docs/runbooks/certificate-rotation.md`](https://github.com/a307582707/TomYang/blob/master/docs/runbooks/certificate-rotation.md) |
| 控制面双模式（静态 Pod / systemd） | [`docs/runbooks/control-plane-deployment-mode.md`](https://github.com/a307582707/TomYang/blob/master/docs/runbooks/control-plane-deployment-mode.md) |

## Wiki push 结果

- 分支：`master`
- 方式：`git push origin master`（Wiki 独立仓库）
- 验证：GitHub Wiki 页面可打开上述四页；侧栏含「现代基线」

## 回滚

在 Wiki 仓库 checkout 上一 commit 并 push（维护者操作）；或自 tag `backup/wiki-master-20260727` 恢复单页 diff。
