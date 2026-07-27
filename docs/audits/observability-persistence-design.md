# Task 65 — 可观测性持久化设计（PVC 骨架）

**范围:** Prometheus / Alertmanager / Grafana / Elasticsearch（或现网日志索引）持久化约定。
**占位:** `{{ STORAGE_CLASS }}`、容量与保留天数均为实验室占位，**非**生产定容。

---

## 通用约定

| 项 | 建议 |
|----|------|
| StorageClass | `storageClassName: "{{ STORAGE_CLASS }}"` |
| AccessMode | 单实例优先 `ReadWriteOnce`；需要多挂载时再评估 `ReadWriteMany`（多数块存储不支持） |
| 备份 | 卷快照 / 应用级（Prometheus remote_write、Grafana 导出、ES snapshot）双轨 |
| 与历史仓 | **不**拷贝 `k8s/ExtraAddons/prometheus` 全量；见 `examples/current/observability/` |

---

## Prometheus

| 字段 | 单实例 Lab | HA 方向 |
|------|------------|---------|
| PVC 名 | `prometheus-data` | 每副本独立 PVC 或 Operator 自动卷 |
| 容量 | `{{ PROMETHEUS_PVC_SIZE }}`（例占位 `50Gi`） | 按保留与基数上调 |
| 保留 | `--storage.tsdb.retention.time={{ PROMETHEUS_RETENTION }}`（例 `15d`） | 同左 + 各副本本地保留 |
| 单 vs HA | Deployment/STS 1 副本 + 1 PVC | 2+ 副本（或 Thanos/Mimir）；**不要**多 Pod 共挂一块 RWO |
| 备份 | 定期 PVC 快照；或 remote_write 到长期存储 | 以 remote / 对象存储为准 |
| 失败行为 | Pod 重建后 RWO 挂回原 Zone 卷则数据在；节点丢失且无快照 → 本地 TSDB 丢，靠 remote 或快照恢复 | 单副本失败 → 刮取中断直至调度成功 |

骨架：`examples/current/observability/prometheus-skeleton.yml`

---

## Alertmanager

| 字段 | 单实例 Lab | HA 方向 |
|------|------------|---------|
| PVC | `alertmanager-data` / `{{ ALERTMANAGER_PVC_SIZE }}`（例 `5Gi`） | 每实例 PVC；gossip 同步静默状态 |
| 保留 | 静默/通知日志非长期指标；以配置与 PVC 为准 | 同左 |
| 单 vs HA | 1 副本 | ≥2 副本 + 正确 cluster.peer |
| 备份 | 备份 `alertmanager.yml` Secret/ConfigMap + PVC 快照 | 同左 |
| 失败行为 | 单实例宕机 → 告警停发直至恢复；**不**丢 Prometheus 指标 | HA 下多数派仍可通知 |

---

## Grafana

| 字段 | 单实例 Lab | HA 方向 |
|------|------------|---------|
| PVC | `grafana-data` / `{{ GRAFANA_PVC_SIZE }}`（例 `10Gi`） | 共享 DB（Postgres）优于多实例共 RWO |
| 保留 | 仪表盘/用户在 PVC 或外部 DB；与指标保留无关 | 外部 DB + 对象存储插件 |
| 单 vs HA | 1 Deployment + 1 PVC | ≥2 + 外部 DB；无外部 DB 时勿多副本抢 RWO |
| 备份 | 导出 dashboard JSON；PVC 快照；Secret 外置 | DB 备份为主 |
| 失败行为 | Pod 漂移到无卷可用区 → Pending；数据在原 PVC | 外部 DB 时 Pod 无状态可快速迁移 |

骨架：`examples/current/observability/grafana-skeleton.yml`

---

## Elasticsearch（或现网等价日志索引）

| 字段 | 单实例 Lab | HA 方向 |
|------|------------|---------|
| PVC | 每节点 `es-data-N` / `{{ ES_PVC_SIZE }}`（例 `100Gi`） | 数据节点 ≥3；主节点角色分离 |
| 保留 | ILM `{{ ES_RETENTION_DAYS }}`（例 `30`） | 同左 + 热温冷 |
| 单 vs HA | 单节点仅 Lab | 生产必须多节点与副本分片 |
| 备份 | `_snapshot` 到 `{{ ES_SNAPSHOT_REPO }}` | 定期快照 + 恢复演练 |
| 失败行为 | 单节点丢盘 → 索引全丢（无快照） | 副本分片可容忍丢盘；注意脑裂与水位 |

**勿** apply `k8s/archived/efk/`（含 privileged init）。

---

## 容量粗算（占位公式）

```text
Prometheus ≈ scrape_samples/s * bytes/sample * retention_seconds * 1.2
ES        ≈ daily_ingest * retention_days * replica_factor * 1.3
```

填入现网基数后再替换 `{{ *_PVC_SIZE }}`。

---

## 失败与恢复检查清单

- [ ] StorageClass 在目标 Zone 可供给
- [ ] RWO 与副本数匹配（无多挂载冲突）
- [ ] 保留参数与容量匹配（避免持续 WAL/磁盘水位）
- [ ] 至少一次从快照/remote 恢复演练
- [ ] 密钥与仪表盘不依赖唯一空白 PVC 的“运气”

## 回滚

删 PVC 前确认快照；回滚 Deployment 修订不会自动回滚卷内容。
