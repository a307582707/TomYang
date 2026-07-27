# 发布与版本规则（TomYang 教材仓库）

**任务:** Task 48
**相关:** [`CHANGELOG.md`](../CHANGELOG.md)、[`docs/MAINTENANCE.md`](./MAINTENANCE.md)

## 1. 两套版本，禁止混用

| 版本种类 | 含义 | 记录位置 | 示例（说明用，非承诺现网） |
|----------|------|----------|----------------------------|
| **仓库 / 教材版本** | 本 Git 仓库文档与清单组织的 SemVer | `CHANGELOG.md`、Git tag `vMAJOR.MINOR.PATCH` | `v0.1.0` |
| **上游 Kubernetes 版本** | 控制面/组件镜像与 API 兼容目标 | 清单 `image:` 标签、`docs/MAINTENANCE.md` 台账 | 教材中曾出现 `apiserver v1.11.1` |

**错误示例:** 将仓库打成 `v1.28.0` 暗示「集群已是 K8s 1.28」——禁止。
**正确示例:** 仓库 `v0.2.0` 的说明中写：「文档支持对照上游 K8s ≥1.28 的迁移审计；仓内历史清单仍为 1.11 教材」。

## 2. SemVer（仓库版本）语义

| 级别 | 何时递增 |
|------|----------|
| MAJOR | 不兼容的目录/契约变更（例如删除读者依赖的路径且无迁移说明） |
| MINOR | 向后兼容的新增（新 `examples/`、新审计文档、新 ADR） |
| PATCH | 文案修正、坏链修复、不影响契约的小改 |

上游组件 EOL 或 API 废弃：**先**更新 `MAINTENANCE.md` / 审计；**再**按上文规则升仓库版本（通常 MINOR）。

## 3. Git Tag 规则

- 格式：`vMAJOR.MINOR.PATCH`（前缀 `v`）。
- 仅对已合并主线、且 `CHANGELOG.md` 已将对应章节从 `Unreleased` 迁出的提交打 tag。
- Tag 注释说明**仓库**变更，可另起一行写「文档基线对照上游 K8s：…」——该行不是集群版本声明。
- 不强制 push tag；是否发布到远端 **现网 / 维护者定义**。
- 禁止用 tag 名编码 VIP、密码或环境名。

## 4. 发布检查单

打仓库版本 tag 或发布说明前：

- [ ] `CHANGELOG.md` 已更新，且与 diff 一致
- [ ] 未把上游 K8s 版本写成仓库 SemVer
- [ ] `docs/MAINTENANCE.md` 台账若涉及组件版本有同步
- [ ] `scripts/run-static-checks.sh` 通过
- [ ] 无密钥：`scripts/check-secrets.sh`；未误加 `.env`
- [ ] 未对 `k8s/archived/**` 提供「可安装」误导入口
- [ ] 新增示例均为占位符，无伪造生产 CIDR/账号
- [ ] Wiki 长文仍以 Wiki 为准（`docs/SSOT.md`）
- [ ] DR / 安全相关变更已链到 Wiki SRE-07（如适用）
- [ ] （可选）更新 `README.md` 文档入口链接

## 5. 与现网发布的关系

- 本仓库 release **不等于** 生产集群升级。
- 生产发布 / 回滚流程：Wiki [SRE-05](https://github.com/a307582707/TomYang/wiki/SRE-05-发布与回滚-金丝雀误判与数据库迁移) + 现网变更系统。
- RPO/RTO：[`docs/disaster-recovery/README.md`](./disaster-recovery/README.md)（现网定义）。

## 6. 首次基线

- 文档任务 40–48 合入后，建议将仓库基线记为 **`0.1.0`**（见 `CHANGELOG.md`），后续文档增量走 `Unreleased` → 下次 tag。
