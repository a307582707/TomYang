# Task 33 — HA 控制面隔离实验室测试计划

**范围:** 仅隔离实验室（非生产、非共享现网）。
**拓扑假设（与仓库一致）:** 客户端/VIP **`:8443`**（HAProxy）→ 各 master 上 apiserver **`:5443`**；etcd client **`:2379`**。
**节点/VIP 地址:** 现网选定或实验室网段占位（本文用 `{{ LAB_VIP }}`、`{{ M1 }}`、`{{ M2 }}`、`{{ M3 }}`）。

## 安全前提

1. **禁止**在生产或承载真实业务的集群执行本计划的故障注入。
2. 实验室集群与生产网络隔离；不复用生产证书、Token、`.env` 真实值。
3. 测试前确认无 systemd / 静态 Pod 双开 apiserver（见正确性审计：静态 Pod `5443` vs 历史 systemd `6443`）。
4. 保留 console/IPMI 或带外访问，避免 VIP/SSH 同时丢失时无法恢复。

## 前置检查

| 步骤 | 动作 | 期望 |
|------|------|------|
| P1 | 三节点均运行 keepalived / haproxy / etcd / apiserver / CM / scheduler 静态 Pod | `kubectl get pods -n kube-system`（经 VIP）可见控制面组件 |
| P2 | `ip -br a` 仅一台持有 `{{ LAB_VIP }}` | 单 owner |
| P3 | `curl -k https://{{ LAB_VIP }}:8443/healthz` | `ok` |
| P4 | 直连 `https://{{ M1 }}:5443/healthz`（及 M2/M3） | 各节点 apiserver 健康 |
| P5 | HAProxy 配置中 backend `server` 指向三台 `:5443` 且非注释 | 现网选定 IP 已填入 `haproxy.cfg` |
| P6 | `etcdctl endpoint status --cluster`（实验室证书路径） | 有且仅一 leader |

---

## 测试用例

### T1 — VIP 所有权

1. 在三台 master 上观察 `{{ LAB_VIP }}` 出现位置与 keepalived 日志。
2. 记录 MASTER/BACKUP 状态（`ip addr`、容器日志）。
3. **通过标准:** 任意时刻仅一节点拥有 VIP；VIP 与 HAProxy 同节点或按设计可达。

### T2 — VIP / Keepalived 故障转移

1. 在 VIP 持有者上：停止 keepalived 静态 Pod，或 `ip link set {{ INTERFACE }} down`（实验室可控网卡）。
2. 观察 VIP 在 ≤ keepalived 超时窗口内漂移到另一节点。
3. 持续 `curl -k https://{{ LAB_VIP }}:8443/healthz`（允许短暂失败后恢复）。
4. **通过标准:** VIP 迁移成功；kubectl 经 VIP 恢复可用。
5. **恢复:** 恢复原节点 keepalived/网卡，确认无双 VIP（脑裂）。

> 注意：静态 Pod `keepalived.yml` 的 `CHECK_PORT=2379`；宿主机脚本 `k8s/master/etc/keepalived/check_haproxy.sh` 探测 `VIP:8443`。实验室应明确当前使用哪套检查，避免误判。

### T3 — HAProxy 后端与 apiserver 摘除

1. 在 `{{ M1 }}` 停止 apiserver 静态 Pod（或阻断 `:5443`）。
2. 观察 HAProxy 将该 backend 标为 DOWN（stats 端口若启用：占位凭据，仅实验室）。
3. 经 VIP:8443 的 API 调用仍成功（流量打到 M2/M3）。
4. **通过标准:** 单 master apiserver 故障不导致全集群 API 不可用。
5. **恢复:** 拉起 M1 apiserver，backend 回 UP。

### T4 — etcd Leader 与成员故障

1. 记录当前 etcd leader。
2. 停止 leader 所在节点的 etcd（或短暂隔离 2379/2380）。
3. 观察新 leader 选出；apiserver 写操作短暂抖动后恢复。
4. **通过标准:** 多数派（3 节点丢 1）下集群可读写；`etcdctl endpoint health` 其余成员健康。
5. **勿**在实验室同时停两台 etcd（会失多数派）除非单独做灾难场景且接受全停。

### T5 — 证书错误注入

1. 在单一节点将 `apiserver.pem` 换为错误 SAN/过期样例（**仅该节点、事先备份**）。
2. 重启该节点 apiserver；确认该 backend 健康检查失败。
3. VIP 路径仍可用（其余节点证书正确）。
4. **通过标准:** 坏证书节点被摘除；修复并恢复后重新加入。
5. **恢复:** 还原正确 PEM/KEY，校验 `openssl x509 -in ... -noout -dates -ext subjectAltName`。

### T6 — 网络分区

1. 用实验室防火墙/tc 将 `{{ M1 }}` 与 `{{ M2 }},{{ M3 }}` 隔离（保留带外）。
2. 观察：多数派侧保持 VIP（或按 keepalived 权重重新选举）；少数派不应对外提供双主写。
3. **通过标准:** 无脑裂双 VIP；客户端只连多数派 VIP；etcd 无双 leader 写。
4. **恢复:** 撤销隔离，成员追赶，确认集群一致。

### T7 — 全量恢复演练

1. 按 T2→T3→T4 顺序注入后，按相反顺序恢复。
2. 检查：VIP 唯一、`/healthz`、etcd leader、CM/scheduler `leader-elect`、kubectl get ns。
3. **通过标准:** 15 分钟内（实验室 SLA 自定）恢复到 P1–P6 基线。

---

## 记录模板

| ID | 开始/结束 | 操作 | 观察 | 结果 | 备注 |
|----|-----------|------|------|------|------|
| T1 | | | | PASS/FAIL | |

## 修改摘要

### 风险
- 误在生产执行会导致 API 中断或 etcd 失多数派。
- Keepalived 双套健康检查不一致时，failover 行为与预期不符。

### 遗留
- HAProxy `server` 行在仓库中为注释示例，实验室必须先填真实后端再测。
- 未规定具体 keepalived 超时数值；以实验室配置与现网选定参数为准。

### 回滚
- 各用例均含恢复步骤；最坏情况从备份恢复 etcd 数据目录与 PKI（实验室快照）。本文件为文档-only。
