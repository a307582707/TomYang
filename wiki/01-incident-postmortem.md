# 生产事故复盘：kubelet 磁盘压力导致 37 个节点 NotReady

> 题材类型：生产事故复盘（带时间线）  
> 适合标题改写：`K8s 节点大面积 NotReady：不是 CNI，是磁盘把 kubelet 逼死了`  
> 受众：SRE / 平台 / 业务研发 oncall

## 0. 一句话结论

表面是「节点 NotReady + 业务超时」，根因是 **容器日志与 image layer 打满节点磁盘 → kubelet 进入 DiskPressure → Pod 被驱逐且调度抖动**。  
止血靠扩容临时盘 + 清理日志；根治靠日志轮转、镜像清理策略和磁盘水位告警。

---

## 1. 影响面

| 项 | 内容 |
|----|------|
| 时间窗 | 2025-11-12 21:18 ~ 22:07（CST），约 49 分钟 |
| 影响 | 支付回调成功率从 99.7% 跌到 91.2%；网关 P99 从 180ms 升到 2.4s |
| 范围 | prod-a 集群 worker 共 120 台，其中 37 台 NotReady；核心命名空间 `checkout` / `pay` |
| 用户感知 | App 下单页偶发「系统繁忙」；客服工单 +126 |

严重级别：**Sev-1**（核心交易链路受损，但未完全不可用）。

---

## 2. 时间线（按 UTC+8）

| 时间 | 事件 | 谁 | 动作 / 判断 |
|------|------|----|-------------|
| 21:18 | 告警：`checkout` 错误率 > 5%（5min） | 告警机器人 | oncall 接手 |
| 21:21 | 网关看后端 502/504 上升 | SRE-A | 怀疑下游超时 |
| 21:24 | `kubectl get node \| grep NotReady` 出现 12 台，且在增加 | SRE-A | **误判：先查 CNI / kube-proxy** |
| 21:28 | 抽查 NotReady 节点：`Ready=False`，`message=Kubelet stopped posting node status` | SRE-B | 怀疑 kubelet 挂了 |
| 21:31 | SSH 上节点：`df -h` 显示 `/var/lib/containerd` 所在盘 **100%** | SRE-B | 转向磁盘 |
| 21:33 | `kubectl describe node` 见 `DiskPressure=True`，大量 `Evicted` | SRE-A | 确认根因方向 |
| 21:36 | 决策：对受影响节点紧急清理 + 临时挂盘 | 值班 TL | 开始止血 |
| 21:40 | 清理 20 台节点日志（`/var/log/pods`、containerd 残留） | SRE-B/C | NotReady 开始回落 |
| 21:48 | 对仍满盘节点挂 100Gi 临时盘并 bind mount | 基建 | 节点逐步 Ready |
| 21:55 | 支付成功率回到 98%+ | 监控 | 观察 |
| 22:07 | 错误率恢复基线，宣布缓解 | 值班 TL | 进入复盘准备 |
| T+1 | 根因分析、防再发项立项 | 全员 | 见第 6 节 |

---

## 3. 关键现象与关键排查命令

### 3.1 集群侧

```bash
# 节点状态
kubectl get node | awk '$2!="Ready"{print}'

# 压力与条件
kubectl describe node <node> | sed -n '/Conditions/,/Addresses/p'

# 被驱逐 Pod
kubectl get pod -A --field-selector=status.phase=Failed | grep Evicted | head
```

关键输出片段（脱敏）：

```
Conditions:
  DiskPressure   True   ...   kubelet has disk pressure
  Ready          False  ...   Kubelet stopped posting node status
```

### 3.2 节点侧

```bash
df -h / /var/lib/containerd /var/log
du -xh /var/log/pods 2>/dev/null | sort -h | tail -20
du -xh /var/lib/containerd 2>/dev/null | sort -h | tail -20

# containerd / kubelet 是否还活着
systemctl status kubelet containerd --no-pager
journalctl -u kubelet -n 100 --no-pager
```

关键日志：

```
eviction_manager.go: ... attempting to reclaim ephemeral-storage
DiskPressure condition status updated True
```

### 3.3 业务侧（用于定责与影响量化）

```promql
# 网关到 checkout 的失败率
sum(rate(http_requests_total{svc="checkout",code=~"5.."}[5m]))
/
sum(rate(http_requests_total{svc="checkout"}[5m]))

# 节点 DiskPressure
kube_node_status_condition{condition="DiskPressure",status="true"}
```

---

## 4. 误判与纠正（这是复盘的精华）

| 阶段 | 当时判断 | 为什么错 | 正确信号 |
|------|----------|----------|----------|
| 前 10 分钟 | CNI 故障 | NotReady 常被网络背锅；且错误是「超时」像网络 | 多节点同时 DiskPressure，CNI Pod 本身也 Evicted |
| 中段 | kubelet 进程 bug | `systemctl` 显示 active，但上报心跳失败 | 磁盘 100% 时 kubelet 写状态/日志失败，表现为停报 |
| 纠正后 | 磁盘水位 + 日志无轮转 | 某次大促活动日志级别被调到 DEBUG 未收回 | `/var/log/pods` 单日增长 80Gi+/节点 |

**写作提示**：公开承认误判，比假装「第一时间定位」更像大牛。

---

## 5. 根因拆解

1. **直接原因**：节点 ephemeral-storage 耗尽 → DiskPressure → Pod 驱逐 → 核心副本不足 → 超时/502。  
2. **触发条件**：大促前把 `checkout` 日志级别改为 DEBUG；QPS 升高后日志暴涨。  
3. **防护缺失**：
   - 节点磁盘使用率告警阈值 90%，但 **inode / 单目录暴涨** 未覆盖；
   - 无强制日志轮转（应用自己写文件，又绕过 stdout）；
   - image GC 阈值偏高，layer 与日志叠加。

贡献度（复盘用）：触发 40% / 防护缺失 60%。

---

## 6. 止血动作（可复用 Runbook）

**优先级：先恢复交易，再做漂亮清理。**

1. **扩容副本到健康节点**（避开 DiskPressure 节点）  
   ```bash
   kubectl -n checkout scale deploy/checkout-api --replicas=30
   ```
2. **批量清理高危目录**（先 dry-run 统计，再执行）  
   ```bash
   # 示例：清理 7 天前的已终止 Pod 日志（按你们规范改）
   find /var/log/pods -type f -mtime +2 -name '*.log' -print0 | xargs -0 -r rm -f
   crictl rmi --prune   # 谨慎：确认无正在使用的特殊镜像依赖
   ```
3. **临时盘**：对无法立刻腾出空间的节点挂载额外数据盘到 `/var/lib/containerd`（需重启 containerd，安排排水）。  
4. **流量**：网关对 `checkout` 短暂降级非关键路径（验证码、推荐），保障下单主路径。

---

## 7. 防再发（必须带 Owner + 截止日期）

| 项 | 动作 | Owner | 截止 |
|----|------|-------|------|
| P0 | 节点磁盘 75%/85% 分级告警；DiskPressure=true 立即 Sev-2 | 可观测组 | T+3 |
| P0 | 禁止生产 DEBUG 超过 2 小时；变更单强制填写「日志级别回滚时间」 | 发布平台 | T+7 |
| P1 | 所有服务强制 stdout + 集群统一 logrotate；禁止写容器可写层大文件 | 运行时组 | T+14 |
| P1 | kubelet eviction 参数与 imageGC 按机型重算并灰度 | 节点组 | T+21 |
| P2 | 大促前容量检查单增加「日志增长率」项 | SRE | 下一次大促前 |

---

## 8. 可直接发 Wiki 的「金句式摘要」

> 大面积 NotReady，先看 `Conditions` 再看 CNI。  
> DiskPressure 为 True 时，先救磁盘，再聊网络。  
> 日志级别是变更项，不是调试习惯。

---

## 9. 你改写成自己文章时要替换的字段

- 集群名、命名空间、业务名  
- 具体百分比与分钟数（用真实监控截图）  
- 清理命令必须符合你们安全规范（生产慎用 `rm`/`crictl rmi`）  
- 防再发表换成真实负责人和系统名
