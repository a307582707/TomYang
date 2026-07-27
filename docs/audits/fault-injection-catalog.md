# Task 47 — 故障注入场景目录

**状态:** 目录 / 设计
**执行策略:** **不自动执行**；仅人工在演练窗口按变更单操作。
**禁止:** 对生产集群无审批注入；禁止在 CI 中默认开启破坏性步骤。

## 1. 通用安全护栏

| 护栏 | 要求 |
|------|------|
| 环境 | 仅 `lab` / `staging` 或显式标记的演练命名空间 |
| 审批 | 变更单 + 回滚负责人在场 |
| 爆破半径 | 单节点或单 Deployment；禁止同时破坏 etcd 多数与全部控制面 |
| 观测 | 注入前确认监控 / 日志可用 |
| 超时 | 预设注入时长与强制恢复时间 |
| 清理 | 场景结束删除故障对象、恢复副本、确认 Ready |
| 密钥 | 不在注入脚本中打印 Token / kubeconfig |

## 2. 场景目录

| ID | 场景 | 注入方式（概念） | 预期信号 | 回滚 / 恢复 | 护栏 |
|----|------|------------------|----------|-------------|------|
| FI-01 | 单 Pod 删除 | `kubectl delete pod`（选定 app） | Deployment 拉起新 Pod；短暂就绪探针失败 | 自动自愈；确认副本数 | 禁止删 etcd / apiserver 静态 Pod |
| FI-02 | 副本打到 0 | `kubectl scale --replicas=0` | Service 无 Endpoints；Ingress 5xx | `scale` 回原值（原值现网定义） | 仅演练 NS |
| FI-03 | 节点 NotReady 模拟 | 演练节点停 kubelet **或** 维护 cordon+drain | 节点 NotReady；Pod 驱逐（视策略） | 启 kubelet / uncordon；对照 Wiki SRE-08 | 禁止同时抽干多数控制面节点 |
| FI-04 | NetworkPolicy 误拒绝 | 在实验 NS apply 过严策略 | 业务超时 / DNS 失败 | 删除策略；对照 `examples/current/networkpolicy/` | 勿对 kube-system 盲目 deny-all |
| FI-05 | DNS 中断 | 临时缩容 CoreDNS 或阻断 53（实验） | 解析失败；应用启动失败 | 恢复 CoreDNS 副本；见 `service-dns-audit.md` | 勿删除 `kube-dns` Service 的 clusterIP 对象除非能重建 |
| FI-06 | Ingress 后端错误 | 改 Ingress path / 错误 Service 名（实验） | 404/502 | 用 Git 清单回滚 | 仅实验 host |
| FI-07 | 镜像拉取失败 | 错误镜像名或拉取密钥无效（实验） | `ImagePullBackOff` | 修正镜像 / 密钥；勿提交真实密码 | 不读仓库 `.env` 写入文档 |
| FI-08 | PVC 磁盘满（应用） | 演练卷内填满（非生产存储） | 写失败 / Evicted | 清空间或扩容（现网定义） | 禁止对 etcd 数据盘做满 |
| FI-09 | API Server 不可达（客户端侧） | 错误 VIP / 断演练客户端网络 | kubectl 超时 | 恢复网络；对照 INFRA-01 | 不在生产关 HAProxy/Keepalived |
| FI-10 | 监控目标丢失 | 临时删除 ServiceMonitor 或 NP 阻断 scrape | Grafana 空洞 / 告警 | 恢复 SM / NP | 确认非唯一告警通道 |

## 3. 明确排除（本目录不覆盖）

- 生产 etcd 多数失败注入
- 故意泄露或吊销生产 Token（泄露应急走 Wiki [SRE-07](https://github.com/a307582707/TomYang/wiki/SRE-07-安全与权限-CI泄漏Token应急)，不是故障演练）
- 对 `k8s/archived/**` 的「安装类」实验

## 4. 记录模板（演练后填写）

```text
场景 ID:
环境:
开始/结束时间:
操作者:
观测指标是否符合预期:
恢复耗时:
后续动作:
```

## 5. 与 DR 的关系

故障注入用于验证监控与自愈；灾难恢复指标见 [`docs/disaster-recovery/README.md`](../disaster-recovery/README.md)（RPO/RTO = 现网定义）。
