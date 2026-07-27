# Task 60 — etcd 备份与恢复 Runbook（仅实验 / Lab）

**适用:** 沙箱与演练环境。**禁止**在未变更窗口与回滚预案的情况下对生产控制面直接执行。
**本仓对照:** 历史静态 Pod 见 `k8s/master/manifests/etcd.yml`（镜像 `quay.io/coreos/etcd:v3.3.9` 量级）；现网请使用与 Kubernetes 发行版匹配的 etcd 小版本。

占位符：`{{ ETCD_ENDPOINT }}`、`{{ ETCD_CERT_DIR }}`、`{{ SNAPSHOT_PATH }}`、`{{ BACKUP_OFFSITE }}`、`{{ MEMBER_PEER_URLS }}`。

---

## 1. 快照（snapshot）

在可访问 etcd 客户端证书的控制面节点或运维跳板上：

```bash
export ETCDCTL_API=3
export ENDPOINT="{{ ETCD_ENDPOINT }}"   # 例: https://127.0.0.1:2379
export CERT="{{ ETCD_CERT_DIR }}"

etcdctl --endpoints="${ENDPOINT}" \
  --cacert="${CERT}/ca.crt" \
  --cert="${CERT}/server.crt" \
  --key="${CERT}/server.key" \
  snapshot save "{{ SNAPSHOT_PATH }}/etcd-$(date -u +%Y%m%dT%H%M%SZ).db"
```

建议：

- 保留最近 N 份本地快照 + 校验和文件（`sha256sum`）
- 快照文件权限仅运维组可读；勿提交到 Git

---

## 2. 校验快照

```bash
etcdctl --write-out=table snapshot status "{{ SNAPSHOT_PATH }}/etcd-….db"
# 关注: hash / revision / total key / total size
sha256sum "{{ SNAPSHOT_PATH }}/etcd-….db" | tee "{{ SNAPSHOT_PATH }}/etcd-….db.sha256"
```

异常：`snapshot status` 失败或 hash 与记录不一致 → **不要**用于恢复；重新拍摄。

---

## 3. 加密与异地（原则，非具体厂商步骤）

| 原则 | 说明 |
|------|------|
| 静态加密 | 快照落盘后用现网 KMS / age / gpg 加密；密钥与密文分离保管 |
| 传输 | 仅经 TLS / 受限通道推送到 `{{ BACKUP_OFFSITE }}` |
| 最小权限 | 异地桶/目录仅备份身份可写、恢复身份可读 |
| 保留策略 | 日/周/月分层；演练用副本与生产副本隔离 |
| 验证 | 定期在**独立** lab 解密并 `snapshot status`，勿只测上传成功 |

本仓不提供具体云厂商 CLI；按现网备份平台填充。

---

## 4. 单节点恢复（破坏性 — 仅 Lab）

前提：该节点 etcd 已停止；数据目录已备份到旁路路径。

```bash
# 1) 停止 etcd（静态 Pod 则移走 manifest 或停 kubelet 侧对应单元——按现网方式）
# 2) 清空或重命名旧 data-dir
mv /var/lib/etcd /var/lib/etcd.bak-$(date +%s)   # 路径按现网

# 3) 从快照恢复为新数据目录
export ETCDCTL_API=3
etcdctl snapshot restore "{{ SNAPSHOT_PATH }}/etcd-….db" \
  --data-dir=/var/lib/etcd \
  --name="{{ MEMBER_NAME }}" \
  --initial-cluster="{{ MEMBER_NAME }}={{ MEMBER_PEER_URL }}" \
  --initial-advertise-peer-urls="{{ MEMBER_PEER_URL }}" \
  --initial-cluster-token="{{ CLUSTER_TOKEN }}"

# 4) 恢复证书与静态 Pod / systemd 单元后启动
# 5) 见第 7 节健康检查
```

单节点：`--initial-cluster` 仅含本成员。恢复后 revision 从快照点继续；**之后**写入的数据会丢失。

---

## 5. 多成员集群重建（破坏性 — 仅 Lab）

典型场景：多数派丢失或需整体回滚到同一快照。

1. **宣布维护窗口**；禁止业务变更与新调度（按需 Cordon）。
2. **全体成员**停止 etcd；保留旧 data-dir 为 `*.bak`。
3. 在**每个**将加入新集群的节点上，对**同一**快照执行 `snapshot restore`，但：
   - `--name` / peer URL **各不相同**
   - `--initial-cluster` **列出全部新成员** peer URL
   - `--initial-cluster-token` 使用**新** token（避免与旧集群混员）
4. 按现网静态 Pod / systemd 同时或按文档顺序拉起。
5. 用 `member list` / `endpoint health` 确认多数派；必要时 `member remove` 掉幽灵成员后再 `member add`。
6. 验证 apiserver 可连；跑第 7 节与业务冒烟。

> 切勿在仍有存活多数派的旧集群上对部分节点单独 restore 成另一 `initial-cluster-token`，否则会脑裂。

---

## 6. 证书与成员（certs / members）

| 项 | 检查 |
|----|------|
| 对等/客户端证书 | `openssl x509 -in … -noout -dates -subject`；CA 信任链一致 |
| peer URL | 与证书 SAN / 配置中 advertise URL 一致 |
| `member list` | 无多余 Learner/失联成员；ID 与节点名可追溯 |
| 替换成员 | 先 `member add` 拿 initial 参数 → 新节点 restore 或空启加入 → 再 `member remove` 旧 ID |

证书轮换与 snapshot 恢复解耦：恢复后若证书过期，先修 PKI 再启 etcd。

---

## 7. 健康检查

```bash
export ETCDCTL_API=3
etcdctl --endpoints="${ENDPOINT}" \
  --cacert=… --cert=… --key=… endpoint health --cluster

etcdctl … endpoint status --write-out=table
etcdctl … member list --write-out=table

# Kubernetes 侧（Lab）
kubectl get --raw=/healthz?verbose || true
kubectl get cs 2>/dev/null || kubectl get --raw=/readyz?verbose
```

期望：所有成员 `healthy: true`；无持续 `raft` 选举风暴；apiserver 可读写 ConfigMap。

---

## 8. 演练模板（复制到变更单）

```text
演练编号: LAB-ETCD-YYYYMMDD
环境: [ ] 单节点 lab  [ ] 多控制面 lab
快照来源: {{ SNAPSHOT_PATH }}  hash: ________
执行人 / 监督人: ________ / ________
开始 UTC: ________  结束 UTC: ________

步骤勾选:
[ ] 快照 status + sha256 校验
[ ] 异地密文可下载并可解密（若适用）
[ ] 按单节点 / 多成员章节恢复
[ ] endpoint health / member list 通过
[ ] 创建/删除测试 ConfigMap 成功
[ ] 回滚或保留 bak 目录策略已记录

结果: [ ] 通过  [ ] 失败（根因: ________）
后续动作: ________
```

---

## 9. etcd 3.3 vs 3.5 命令对照

| 目的 | etcd 3.3（本仓历史量级） | etcd 3.5+（现网常见） |
|------|--------------------------|----------------------|
| API 环境变量 | `ETCDCTL_API=3`（必需） | 默认 v3；仍可显式设置 |
| 快照保存 | `etcdctl snapshot save <file>` | 同左 |
| 快照状态 | `etcdctl snapshot status <file>` | 同左；输出字段更稳 |
| 快照恢复 | `etcdctl snapshot restore <file> …` | 同左 |
| 成员列表 | `etcdctl member list` | 同左；支持 learner 显示 |
| 健康 | `etcdctl endpoint health` | 同左；`--cluster` 常用 |
| 后端校验 | 较少强调 | 可用 `etcdutl snapshot status`（3.5 起部分子命令迁到 `etcdutl`） |
| 废弃注意 | v2 API 仍可能出现在旧文档 | 生产应仅 v3；勿混用 v2 |

迁移提示：从 3.3 教材集群升到 3.5，先对齐 Kubernetes 兼容矩阵，再换镜像与 `etcdctl`/`etcdutl`；**不要**把生产快照在未验证版本组合的 lab 上恢复后直接切主。

---

## 风险与回滚

- **风险:** 错误 restore、错误 `initial-cluster-token`、证书 SAN 不匹配 → 控制面不可用。
- **回滚:** 停止新 etcd → 恢复 `data-dir.bak` 与原静态 Pod/单元 → 用原集群配置启动 → 再评估是否改从另一份快照恢复。
- **默认:** 不修改本仓 `k8s/master/manifests/etcd.yml` 历史语义；现网变更走独立清单与变更单。
