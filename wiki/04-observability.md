# 一次 2.3 秒慢请求：从网关追到一行缺索引 SQL

## 0. 案例摘要

| 项 | 内容 |
|----|------|
| 现象 | 用户反馈「提交订单转圈」；网关 P99 从 180ms → 2.3s（仅 POST /v1/orders） |
| 持续 | 2025-09-03 14:05 ~ 14:41 |
| 结论 | `checkout-api` 调 `inventory` 的连接池打满；根因是库存库出现慢查询（缺索引） |
| 定位耗时 | 41 分钟（路径：RED → Trace → Log → SQL） |

---

## 1. 可观测分层

```text
L1 黄金指标 RED/USE     → 发现「哪里不对」
L2 分布式追踪 Trace     → 发现「慢在哪一段」
L3 结构化日志 + 事件     → 发现「为什么慢」
L4 连续剖析 / DB 诊断    → 发现「哪行代码 / 哪条 SQL」
L5 变更事件关联          → 发现「是不是刚上线导致的」
```

当前栈为 Prometheus + Tempo/Jaeger + Loki + Pyroscope；本文按排查路径展开，不绑定某一厂商。

---

## 2. 排查步骤（Runbook）

### Step 1：用 RED 确认「是真慢，还是个别用户错觉」

```promql
histogram_quantile(0.99,
  sum(rate(http_request_duration_seconds_bucket{route="/v1/orders",method="POST"}[5m])) by (le)
)
```

同时看：

- 错误率是否上升（若只慢不报错，多半是依赖阻塞）  
- 是否只有某一个可用区/节点池  

**本案例**：错误率仅从 0.2% → 0.6%，但 P99 明显升——**阻塞型**问题。

### Step 2：拉一条慢 Trace，拆 span

在 tracing UI 按：

- `http.route=/v1/orders`  
- `duration > 2s`  
- 时间窗 14:05-14:20  

典型 span 瀑布（脱敏）：

```text
gateway                 2300ms
 └─ checkout-api        2280ms
     ├─ auth            12ms
     ├─ risk            35ms
     └─ inventory.Reserve  2210ms   ← 元凶段
         └─ sql SELECT ... FOR UPDATE  2180ms
```

### Step 3：对齐日志（用 trace_id 串起来）

`checkout-api` 日志规范字段：

```json
{
  "ts": "2025-09-03T14:12:08+08:00",
  "level": "warn",
  "trace_id": "8f3c...",
  "span_id": "11ab...",
  "msg": "inventory reserve timeout",
  "timeout_ms": 2000,
  "attempt": 3
}
```

查询：

```logql
{app="checkout-api"} |= "8f3c" | json
```

发现大量 `connection pool exhausted` 前后日志。

### Step 4：看依赖资源 USE

`inventory` 实例：

| 指标 | 值 | 解读 |
|------|----|------|
| CPU | 45% | 非 CPU 打满 |
| 线程等待 | 高 | 像锁 / IO |
| DB sessions active | 接近 max_connections | 数据库侧堵住 |
| pgbouncer waiting | 上升 | 连接排队 |

### Step 5：落到 SQL

DBA 打开 `pg_stat_activity` / performance_schema，对应时间窗：

```sql
SELECT sku_id, warehouse_id, qty
FROM inventory_item
WHERE sku_id = $1 AND warehouse_id = $2
FOR UPDATE;
```

执行计划：Seq Scan，`inventory_item` 8200 万行。  
**缺复合索引 `(warehouse_id, sku_id)`。**

### Step 6：关联变更

发布系统显示：14:01 库存团队上线「多仓路由」，查询条件从 `sku_id` 变为 `sku_id + warehouse_id`，旧索引失效。

---

## 3. 止血与修复

**止血（14:28）**

1. 网关对 `/v1/orders` 限流到安全水位，保护库存库。  
2. 库存服务扩连接与只读副本（对可走读的校验路径）。  
3. 回滚多仓路由特性开关（比回滚整包更快）。

**根治（当日）**

```sql
CREATE INDEX CONCURRENTLY idx_inventory_wh_sku
ON inventory_item (warehouse_id, sku_id);
```

观察 P99：2.3s → 260ms → 190ms。

---

## 4. 这个案例暴露的「可观测债」

| 债 | 当时缺口 | 补齐动作 |
|----|----------|----------|
| Trace 采样 | 生产 1%，慢请求经常采不到 | 错误与 >1s 强制 100% 保留 |
| 日志无 trace_id | 老服务 30% 未打通 | 框架中间件统一注入 |
| 仪表盘只会看 CPU | oncall 先看错方向 | 标准「服务大盘」模板：RED + 依赖 + DB |
| 变更无关联 | 靠问人 | 发布事件写入时间轴（Grafana annotations） |

---

## 5. 标准服务大盘（强制项）

1. **流量**：QPS / 并发  
2. **错误**：5xx、业务错误码  
3. **延迟**：P50/P95/P99，按 route  
4. **饱和**：CPU、内存、队列长度、连接池  
5. **依赖**：下游 3 个最关键依赖的 P99 与错误率  
6. **变更**：部署 annotation  

缺少依赖监控与变更关联的大盘，只能覆盖主机资源，无法支撑服务排障。

---

## 6. 服务接入规范

```text
必须：
- HTTP/gRPC 中间件自动产生 server span
- 出站调用自动产生 client span
- 日志强制字段：trace_id, span_id, tenant_id, error_code
- 延迟直方图 bucket 覆盖 5ms~5s

禁止：
- 用日志字符串拼 trace（必须结构化）
- 在热点路径 debug 打印大 body
- 只上报平均值不上直方图
```

---

## 7. 结论

指标发现问题，链路定位位置，日志给出证据。三样齐备，oncall 才不用猜。
