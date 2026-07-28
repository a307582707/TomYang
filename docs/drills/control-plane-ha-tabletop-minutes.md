# HA 控制面桌面演练纪要（模板 + 虚构样本）

**适用:** 仅桌面推演 / 隔离 Lab。**禁止**对生产或未授权集群注入故障。
**对照:** [`ha-control-plane-test-plan.md`](../audits/ha-control-plane-test-plan.md)、[`fault-injection-catalog.md`](../audits/fault-injection-catalog.md)、[`control-plane-deployment-mode.md`](../runbooks/control-plane-deployment-mode.md)

**拓扑（与仓库一致）:** Client → Keepalived VIP **`{{ LAB_VIP }}:8443`** → HAProxy → apiserver **`:5443`**；etcd client **`:2379`**。

---

## 复制即用：演练纪要模板

```text
================================================================================
HA 控制面桌面演练纪要
================================================================================
演练编号:     LAB-CP-YYYYMMDD-NN
类型:         [ ] 桌面推演  [ ] 隔离 Lab 实操
环境:         fictional-lab-ha-3m（勿填生产名）
节点占位:     M1={{ M1 }}  M2={{ M2 }}  M3={{ M3 }}  VIP={{ LAB_VIP }}
执行人:       ________________
监督人:       ________________
日期 (UTC):   ________________
参考文档:     ha-control-plane-test-plan.md / fault-injection-catalog.md

--- 前置基线 (P1–P6) -----------------------------------------------------------
[ ] P1  三节点 keepalived/haproxy/etcd/apiserver/CM/scheduler 静态 Pod 就绪
[ ] P2  仅一节点持有 VIP（ip -br a）
[ ] P3  curl -k https://{{ LAB_VIP }}:8443/healthz → ok
[ ] P4  各节点 https://{{ M* }}:5443/healthz 正常
[ ] P5  HAProxy backend server 已填（非注释）
[ ] P6  etcdctl endpoint status — 单一 leader

--- 场景记录 -------------------------------------------------------------------
场景 ID | 注入摘要           | 开始 UTC | 结束 UTC | 观察摘要              | 结果    | 回滚
--------|--------------------|----------|----------|-----------------------|---------|------
S1      | VIP 漂移           |          |          |                       | PASS/FAIL|
S2      | 单 master 宕机     |          |          |                       | PASS/FAIL|
S3      | HAProxy backend 故障|         |          |                       | PASS/FAIL|
S4      | etcd 成员不可用    |          |          |                       | PASS/FAIL|

--- S1 VIP 漂移（对照 T2）------------------------------------------------------
注入: 在 VIP 持有者停止 keepalived 或 down 演练网卡 {{ INTERFACE }}
预期: ≤ keepalived 超时内 VIP 迁移；curl VIP:8443/healthz 短暂失败后恢复
观察: VIP 新持有者 ________  漂移耗时 ________  是否双 VIP: [ ] 是 [ ] 否
回滚: 恢复原节点 keepalived/网卡；确认单 VIP

--- S2 单 master 宕机（对照 T3 +「单 master down」）----------------------------
注入: 在 {{ M1 }} 停止 apiserver 静态 Pod 或阻断 :5443
预期: HAProxy 标 M1 DOWN；经 VIP 的 API 仍可用（M2/M3）
观察: backend 状态 ________  kubectl get ns 经 VIP: [ ] 成功 [ ] 失败
回滚: 拉起 M1 apiserver；backend 回 UP

--- S3 HAProxy backend 故障 -----------------------------------------------------
注入: 在 VIP 持有者停止 haproxy 静态 Pod（或错误 backend 配置 — 桌面假设）
预期: VIP:8443 healthz 失败；Keepalived 可能触发漂移（视 check 脚本）
观察: check_haproxy.sh vs CHECK_PORT=2379 哪套生效: ________
      故障持续时间 ________  是否触发 VIP 迁移: [ ] 是 [ ] 否
回滚: 恢复 haproxy Pod/配置；确认 VIP:8443 ok

--- S4 etcd 成员不可用（对照 T4）-----------------------------------------------
注入: 停止 leader 节点 etcd（或 FI 隔离 2379/2380）— 仅丢 1 成员
预期: 新 leader 选出；apiserver 写操作短暂抖动后恢复；3 丢 1 仍多数派
观察: 原 leader ________  新 leader ________  选举耗时 ________
      endpoint health: [ ] 全绿 [ ] 部分 down
回滚: 拉起 etcd；member list 一致

--- 汇总 -----------------------------------------------------------------------
整体结果:     [ ] 通过  [ ] 部分通过  [ ] 失败
RTO 备注:     从首次注入到 P1–P6 基线恢复: ________ min（Lab 自定 SLA）
遗留问题:     ________________________________________________
后续动作:     ________________________________________________
签字: 执行人 ________  监督人 ________  日期 ________
================================================================================
```

---

## 虚构桌面样本（Lab only — 未连接真实集群）

```text
================================================================================
HA 控制面桌面演练纪要 — 样本（虚构）
================================================================================
演练编号:     LAB-CP-20260728-01
类型:         [x] 桌面推演  [ ] 隔离 Lab 实操
环境:         fictional-lab-ha-3m
节点占位:     M1=192.168.99.11  M2=192.168.99.12  M3=192.168.99.13
              VIP=192.168.99.100（RFC5737 测试网段 — 虚构）
执行人:       演练员 Chen
监督人:       监督员 Li
日期 (UTC):   2026-07-28
参考文档:     ha-control-plane-test-plan.md §T2–T4

--- 前置基线 (P1–P6) -----------------------------------------------------------
[x] P1–P6  桌面确认清单与 INFRA-01 一致（未 SSH 实机）

--- 场景记录 -------------------------------------------------------------------
场景 ID | 注入摘要              | 开始     | 结束     | 观察摘要                    | 结果 | 回滚
--------|-----------------------|----------|----------|-----------------------------|------|------
S1      | M1 keepalived 停止    | 10:00    | 10:08    | VIP→M2，~6s，无双 VIP       | PASS | 启 M1 KV
S2      | M1 apiserver 停止   | 10:10    | 10:18    | HAProxy M1 DOWN，VIP API OK | PASS | 启 M1 API
S3      | M2 haproxy 停止     | 10:20    | 10:28    | :8443 失败 4s 后 VIP→M3     | PASS | 启 M2 HAP
S4      | M3 etcd 停止        | 10:30    | 10:42    | 新 leader@M2，写抖动 ~8s    | PASS | 启 M3 etcd

--- S1 VIP 漂移 ----------------------------------------------------------------
注入: 桌面假设 M1（原 VIP 持有者）keepalived 进程退出
观察: VIP 6s 内迁至 M2；curl healthz 失败 2 次后 ok；无双 VIP
回滚: 启动 M1 keepalived；M1 为 BACKUP

--- S2 单 master 宕机 ----------------------------------------------------------
注入: 桌面假设 M1 apiserver 静态 Pod 移除
观察: HAProxy stats（虚构）显示 server m1 DOWN；kubectl get ns 经 VIP 成功
回滚: 恢复 M1 apiserver manifest

--- S3 HAProxy backend 故障 ----------------------------------------------------
注入: 桌面假设 M2（当前 VIP 持有者）haproxy 停止
观察: VIP:8443 不可达约 4s；keepalived check_haproxy.sh 触发 VIP→M3
备注: 静态 Pod keepalived CHECK_PORT=2379 与脚本 VIP:8443 检查不一致 — 实验室须统一
回滚: 恢复 M2 haproxy

--- S4 etcd 成员不可用 ---------------------------------------------------------
注入: 桌面假设 M3 etcd 停止（原 leader 在 M3）
观察: ~8s 后 leader 迁至 M2；endpoint health 2/3→3/3；ConfigMap 读写恢复
回滚: 启动 M3 etcd；revision 追赶正常

--- 汇总 -----------------------------------------------------------------------
整体结果:     [x] 通过（桌面）
RTO 备注:     末场景恢复后 12 min 回到 P1–P6 基线（含叙述间隔，非连续注入）
遗留问题:     keepalived 双套健康检查（2379 vs 8443）需在 Lab 文档化选用一套
后续动作:     下季度隔离 Lab 实操 T2–T4；补齐 HAProxy backend 真实 IP 后再测
签字: 执行人 Chen  监督人 Li  日期 2026-07-28
================================================================================
```

---

## 场景与测试计划映射

| 本模板场景 | `ha-control-plane-test-plan` | `fault-injection-catalog` |
|------------|------------------------------|---------------------------|
| S1 VIP 漂移 | T1, T2 | FI-09（客户端侧，勿生产关 HAProxy） |
| S2 单 master down | T3 | — |
| S3 HAProxy backend 故障 | T3（backend 维度） | FI-09 |
| S4 etcd 成员不可用 | T4 | 排除多数派同时失败 |

---

## 演练前检查清单

- [ ] 确认为 **fictional lab** 或桌面推演；审批与监督人在场
- [ ] 无 systemd + 静态 Pod 双开 apiserver（5443 vs 6443）
- [ ] HAProxy `backend k8s-api` server 行已在 Lab 渲染（非仅注释）
- [ ] 带外/console 可用
- [ ] 不打印 Token / kubeconfig / `.env` 内容
- [ ] 注入顺序建议：S1 → S2 → S3 → S4；每场景独立回滚后再进行下一项（全量恢复见 T7）

---

## 回滚

- **各场景:** 见模板「回滚」列；最坏情况 etcd 快照 + PKI 备份（Lab only）。
- **文档:** revert 本文件即可；不影响集群。
