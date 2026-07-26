# 容量与成本：我们如何把 K8s 月度计算成本降了 38%

> 题材类型：容量 / 成本治理  
> 适合标题：`不是靠「删机器」，而是把 Request 谎言和闲置命名空间算清楚`  
> 目标：证明你会算账，而不只会扩容

## 0. 结果先亮出来

| 指标 | 治理前（月） | 治理后（月） | 变化 |
|------|--------------|--------------|------|
| worker 节点费用 | ¥182,000 | ¥113,000 | **-38%** |
| 平均 CPU 利用率（可调度核） | 23% | 41% | +18pt |
| 平均内存利用率 | 31% | 52% | +21pt |
| 因压缩导致的事故 | — | 0（观察 90 天） | 可控 |

周期：8 周（盘点 2 周 + 治理 4 周 + 观察 2 周）。  
原则：**先消灭浪费，再谈更贵的机型；任何缩容必须可回滚。**

---

## 1. 成本结构拆解（先让读者相信你懂账）

```text
月度集群成本 ≈ 节点费 + 负载均衡 + 块存储 + 公网流量 + 可观测存储
本次主攻：节点费（占比约 72%）
```

节点费驱动因子：

1. **Request 虚高** → 调度认为没空位 → 不断加节点  
2. **命名空间僵尸** → 测试/演示环境常驻生产集群  
3. **DaemonSet / 系统组件过重** → 每节点固定税  
4. **不当的 HPA**：按 CPU Request 百分比，Request 虚高则永远扩不出去/或乱扩

---

## 2. 典型案例 A：Request 是「程序员拍脑袋」

### 现象

`order-api` 配置：

```yaml
resources:
  requests:
    cpu: "2"
    memory: 4Gi
  limits:
    cpu: "4"
    memory: 8Gi
replicas: 12
```

占位：24 核 / 48Gi。  
实际 7 天监控：

| 指标 | P95 | P99 | Max |
|------|-----|-----|-----|
| CPU | 0.18 核 | 0.27 核 | 0.41 核 |
| 内存 | 620Mi | 740Mi | 910Mi |

**浪费倍数**：CPU Request / P95 ≈ 11 倍。

### 纠正方法（可复制）

1. 用 VPA 推荐值做**建议**，不直接自动改生产（先人审）。  
2. 规则：`requests.cpu = max(P95*1.5, P99)`，内存按 P99*1.3 并留峰值余量。  
3. 新配置：

```yaml
resources:
  requests:
    cpu: "300m"
    memory: 1Gi
  limits:
    cpu: "1"
    memory: 2Gi
```

12 副本占位从 24 核降到 3.6 核。  
同类服务批量处理后，集群可调度空闲上升，**两周内缩容 28 台 8C16G 节点**。

### 风险控制

- 灰度：先 20% 副本新 Request，观察 saturation 与 throttling（`container_cpu_cfs_throttled_seconds_total`）。  
- 回滚：GitOps revert，5 分钟内恢复旧 Request。  
- 护栏：若 P99 CPU > request*0.8 持续 30 分钟，自动开 ticket 不允许继续压缩。

---

## 3. 典型案例 B：HPA「看起来很勤快」，实际在烧钱

### 错误配置

```yaml
minReplicas: 8
maxReplicas: 80
metrics:
- type: Resource
  resource:
    name: cpu
    target:
      type: Utilization
      averageUtilization: 50
```

当 `requests.cpu=2` 而真实只用 0.2 时，利用率公式：

```text
utilization ≈ 实际用量 / Request
0.2 / 2 = 10%  → 远低于 50%，HPA 不会扩
```

有人把 Request 改小后，利用率飙到 90%+，HPA 一口气扩到 80，**节点被打满，成本暴涨**。

### 正确姿势

1. Request 先校准，再调 HPA。  
2. 对流量型服务，优先 **QPS / 并发** 自定义指标，而不是纯 CPU。  
3. 设置「扩容速率限制」：

```yaml
behavior:
  scaleUp:
    policies:
    - type: Pods
      value: 4
      periodSeconds: 60
  scaleDown:
    stabilizationWindowSeconds: 300
```

文章金句：

> HPA 放大的是 Request 的错误。Request 不准时，自动化是加速烧钱机器。

---

## 4. 典型案例 C：僵尸命名空间与「临时环境永久化」

盘点脚本逻辑（示意）：

```bash
# 7 天无 Deployment 变更 + 7 天 CPU 用量 < 1 核 分钟 → 候选回收
kubectl get ns -o name | while read ns; do
  ...
done
```

结果：

| 类型 | 命名空间数 | 折合节点 |
|------|------------|----------|
| 已下线业务未删 | 14 | ~9 台 |
| 演示环境常驻 | 6 | ~5 台 |
| 个人调试（prod 集群） | 11 | ~4 台 |

治理：

1. 生产集群禁止个人 ns；统一 `dev-shared`。  
2. 临时环境 TTL：标签 `ttl.hours=72`，控制器到期销毁。  
3. 回收前通知 Owner，保留 PV 快照 7 天。

---

## 5. 执行节奏（读者最爱的「可抄作业」部分）

### Week 1-2：只看不动

- 导出 Top 50 浪费工作负载（`(request - p95)/request`）  
- 标定系统组件「固定税」  
- 对齐财务科目与节点标签（`nodepool=cpu-od` / `nodepool=cpu-spot`）

### Week 3-6：动刀顺序

1. 删僵尸  
2. 校 Request（批量 PR）  
3. 修 HPA  
4. 缩节点池（每次最多 10%，观察 48h）  
5. 评估 spot/竞价（非核心可抢占）

### Week 7-8：固化

- 门禁：CI 检查「Request 超基线 3 倍需审批」  
- 周报：浪费榜 + 节点利用率  
- 复盘会：是否出现 CPU throttle / OOM 上升

---

## 6. 关键指标与 SQL/PromQL

```promql
# 命名空间 Request 总量
sum(kube_pod_container_resource_requests{resource="cpu"}) by (namespace)

# 实际使用
sum(rate(container_cpu_usage_seconds_total{container!=""}[5m])) by (namespace)

# 浪费率
( sum(kube_pod_container_resource_requests{resource="cpu"}) by (namespace)
  -
  sum(rate(container_cpu_usage_seconds_total{container!=""}[5m])) by (namespace)
)
/
sum(kube_pod_container_resource_requests{resource="cpu"}) by (namespace)
```

---

## 7. 防「成本优化事故」清单

- [ ] 缩容前看 **P99 与错误率**，不只看平均利用率  
- [ ] JVM / Node.js 服务内存压缩单独评估（堆配置耦合）  
- [ ] 有本地盘缓存的服务禁止随意迁节点池  
- [ ] 大促前 14 天冻结压缩类变更  
- [ ] 每次治理保留「回补节点」按钮（IaC 一键加回）

---

## 8. 对外表述模板

> 我们把 CPU Request 从「申请制」改成「观测校准制」，  
> 在 90 天零相关事故前提下，节点费用下降 38%。  
> 关键不是更便宜的云厂商，而是更诚实的容量数据。
