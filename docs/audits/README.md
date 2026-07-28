# docs/audits — 审计与验收索引

本目录存放仓库卫生、安全、兼容性与运维审计材料。操作步骤仍以 Wiki **INFRA-01** 为准；版本与组件风险台账见 **[MAINTENANCE.md](../MAINTENANCE.md)**；SSOT 速查见 [SSOT.md](../SSOT.md)。

**残余风险优先级约定:** P0 阻断生产误用 / 安全回归 · P1 下一季度必须处理 · P2 有计划优化 · P3 记录在案。

| 文件 | 主题 | 状态 | 残余风险优先级 | 残余要点 |
|------|------|------|----------------|----------|
| [k8s-correctness-report.md](./k8s-correctness-report.md) | Task 1 清单正确性 | 已合入 | P2 | 历史清单 API/路径教材性保留；新集群勿原地升级 |
| [k8s-compatibility-matrix.md](./k8s-compatibility-matrix.md) | Task 2 兼容性矩阵 | 已合入 | P1 | 控制面/CNI/Ingress 镜像 EOL；需按现网重建 |
| [k8s-security-report.md](./k8s-security-report.md) | Task 3 安全审计 | 已合入 | P0/P1 | 归档反例仍在树中；git 历史样例口令勿复用；stats 网段限制 |
| [observability-report.md](./observability-report.md) | Task 4 可观测性整理 | 已合入 | P2 | 旧 Prometheus 栈仅参考 |
| [static-checks.md](./static-checks.md) | Task 8 静态检查 | 已合入 | P3 | 持续扩展检查项（见 dangerous-patterns） |
| [observability-completeness.md](./observability-completeness.md) | Task 16 可观测性完整性 | 已合入 | P1 | 无 CRD/PVC；Grafana emptyDir；采集缺口 |
| [final-acceptance-2026-07-27.md](./final-acceptance-2026-07-27.md) | Task 18 阶段验收 | 已完成 | P2 | 遗留项转入后续 Task |
| [naming-normalization-map.md](./naming-normalization-map.md) | Task 29 命名映射 | 映射已出；批次实施中 | P2 | Wiki/文档引用需随 `git mv` 同步 |
| [dependency-graph.md](./dependency-graph.md) | Task 32 依赖与安装序 | 已合入 | P3 | 教材顺序 vs 现网发行版差异 |
| [ha-control-plane-test-plan.md](./ha-control-plane-test-plan.md) | Task 33 HA 实验室计划 | 计划就绪 | P1 | 需隔离环境实测 VIP 漂移 |
| [pki-lifecycle-audit.md](./pki-lifecycle-audit.md) | Task 34 PKI | 已合入 | P1 | CSR 无 hosts；CA/leaf 过长；front-proxy CN |
| [rbac-permission-matrix.md](./rbac-permission-matrix.md) | Task 35 RBAC | 已合入 | P1 | 归档 Weave/metrics 权限面仍在树 |
| [pod-security-matrix.md](./pod-security-matrix.md) | Task 36 Pod 安全 | 已合入 | P1 | 归档 docker.sock / ES privileged；CNI 特权必要 |
| [resource-quota-audit.md](./resource-quota-audit.md) | Task 37 资源配额 | 已合入 | P2 | 控制面 BestEffort 风险 |
| [health-probe-audit.md](./health-probe-audit.md) | Task 38 探针 | 已合入 | P2 | 历史探针与端口对齐抽查 |
| [scheduling-ha-audit.md](./scheduling-ha-audit.md) | Task 39 调度 HA | 已合入 | P2 | 工作负载反亲和/副本遗留 |
| [networkpolicy-design.md](./networkpolicy-design.md) | Task 40 NetworkPolicy | 设计+示例 | P2 | 需现网 CNI 验证 |
| [ingress-migration.md](./ingress-migration.md) | Task 41 Ingress 迁移 | 已合入 | P1 | extensions/v1beta1 → v1 |
| [service-dns-audit.md](./service-dns-audit.md) | Task 43 Service/DNS | 已合入 | P1 | kube-dns 遗留与 CoreDNS 冲突风险 |
| [pull-script-modernization.md](./pull-script-modernization.md) | Task 44 pull 现代化 | 设计稿 | P2 | 空气墙拉取仍依赖旧 `pull.sh` |
| [shell-quality-audit.md](./shell-quality-audit.md) | Task 45 Shell 质量 | 已合入 | P3 | 脚本风格持续收敛 |
| [fault-injection-catalog.md](./fault-injection-catalog.md) | Task 47 故障注入目录 | 已合入 | P2 | 实验室场景待执行 |
| [doc-quality-notes.md](./doc-quality-notes.md) | Task 53 文档质量 | 已合入 | P3 | Wiki 未进自动链接流水线 |
| [license-and-provenance.md](./license-and-provenance.md) | Task 54 许可证来源 | 已合入 | P3 | 第三方清单标注 |
| [quarterly-review-automation.md](./quarterly-review-automation.md) | Task 55 季度复查 | 设计就绪 | P2 | 自动化待接线 |
| [pr2-cleanup-record.md](./pr2-cleanup-record.md) | Task 57 PR #2 清理 | 记录 | P3 | 无关历史 PR |
| [branch-cleanup-inventory.md](./branch-cleanup-inventory.md) | Task 58 分支清理 | **待确认删除** | P2 | 远程主题分支堆积 |
| [infra01-path-realignment.md](./infra01-path-realignment.md) | Task 67 Wiki 路径对齐 | checklist | P1 | INFRA-01/05 路径与 rename 同步 |
| [dangerous-patterns.md](./dangerous-patterns.md) | Task 69 危险模式检查 | 脚本就绪；可选接线 | P0 | 防匿名高权 / insecure kubelet / docker.sock 回流 |
| [hygiene-acceptance-2026-07-27.md](./hygiene-acceptance-2026-07-27.md) | Task 73 卫生验收模板 | **待父流程填写** | — | 合并后最终勾选 |
| [v0.1-risk-board.md](./v0.1-risk-board.md) | **v0.1 后进度/风险板** | 活跃 | P1 | post-v0.1 入口；链 #71–#73 |

## 相关 runbook（非 audits，但常一起查）

- [certificate-rotation.md](../runbooks/certificate-rotation.md)
- [control-plane-deployment-mode.md](../runbooks/control-plane-deployment-mode.md)

## 维护

- 新增审计文件时更新本表一行。
- 季度复查时对照 [MAINTENANCE.md](../MAINTENANCE.md) 更新「残余要点」与优先级。
- 禁止在本目录存放真实密钥、生产 `.env` 或已签发私钥。
