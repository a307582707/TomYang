# Issue #1 处置记录 — Jenkins unexpected EOF

**Issue:** [a307582707/TomYang#1](https://github.com/a307582707/TomYang/issues/1)
**标题:** kubernetes集群无法运行jenkins，报错：error: unexpected EOF
**创建:** 2019-01-09
**处置日期:** 2026-07-29
**结论:** **关闭 — 过时且超出本仓范围**

## 背景摘要

- 报告 `demo-jenkins` Pod 日志在 Jenkins 正常启动约 35 秒后出现 `error: unexpected EOF`（kubectl logs 侧）。
- 日志时间戳为 **2019-01-09**；Jenkins 版本与插件栈均为早期 2.x 时代。
- Issue 无后续评论、无复现环境、无与本仓清单的明确关联。

## 与本仓定位对照

| 维度 | 评估 |
|------|------|
| 仓库定位 | Kubernetes **教材 / 清单** 仓库；非 Jenkins 发行版或 CI 产品仓 |
| Jenkins 维护 | 仓内 **无** Jenkins 部署清单、Runbook 或 `examples/current` 基线 |
| 可复现性 | 缺少集群版本、镜像、资源限制、CNI、Ingress 等最小复现信息 |
| 时效 | 7+ 年；kubectl / API / 容器运行时行为已变 |

## 决策

**关闭 Issue**，理由：

1. **Stale：** 2019 年环境快照，无法在无生产凭据前提下验证。
2. **Out of scope：** Jenkins 运维不属于本 textbook 仓库维护面；读者应参考 [Jenkins 官方文档](https://www.jenkins.io/doc/) 或现网 CI 平台 Runbook。
3. **非安全/架构债务：** 不构成对本仓 `k8s/` 或 `examples/current/` 的 actionable 缺陷。

## 若未来需要 Jenkins 相关内容

建议在 **GitHub Discussions** 开「实践交流」帖，并附带：

- Kubernetes 版本、CRI、资源 requests/limits
- Jenkins 镜像 tag / LTS 线
- 完整 Pod 事件与 `kubectl describe`（脱敏）
- 是否经 Service / Ingress 暴露

**禁止**在 Issue 或 Discussion 中索取生产 kubeconfig、Registry 凭据或内网 IP。

## 执行

- `gh issue close 1 --comment "<处置说明>"` — 见 Issue 评论正文
- 本文件供审计追溯

## 回滚

如需重开：`gh issue reopen 1` 并链接 Discussions 或新复现模板 Issue。
