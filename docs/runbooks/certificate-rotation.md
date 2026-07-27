# 证书轮换 Runbook（Task 70）

**适用范围:** 对照本仓 `k8s/pki/*.json` 签发、落盘于节点 `/etc/kubernetes/pki` 与 `/etc/etcd/ssl` 的自建 HA 控制面。
**操作权威拓扑/端口:** Wiki [INFRA-01](https://github.com/a307582707/TomYang/wiki/INFRA-01-本仓HA控制面与节点接入)。
**仓内审计:** [pki-lifecycle-audit.md](../audits/pki-lifecycle-audit.md)。

> 本仓库默认**只有 CSR JSON**，不含已签发 PEM。下列步骤在实验室/现网节点执行；**不要**把私钥提交回 Git，**不要**读取仓库 `.env`。

## 1. 轮换顺序（非 CA）

推荐「先数据面信任、后滚动重启」：

1. **备份:** etcd 快照；复制当前 `/etc/kubernetes/pki`、`/etc/etcd/ssl` 到带外安全位置。
2. **盘点到期:** 在节点上运行到期检查（见 §6）。
3. **签发新 leaf:** 使用现网 CA（仍信任）为 etcd / apiserver / front-proxy-client / admin / controller-manager / scheduler / kube-proxy / kubelet 签发新证；**SAN 必须含 VIP、各 master IP、`kubernetes` 等**（见 INFRA-01）。
4. **分发:** 先把新 PEM 放到并行目录或 `.new` 后缀，校验链与权限（目录 `600`/`640` 按现网规范）。
5. **滚动 etcd:** 一次一个成员替换证书并确认 `endpoint health`。
6. **apiserver:** 替换证书后重启静态 Pod / 单元；经 VIP:8443 与本机:5443 做 `healthz`。
7. **controller-manager / scheduler:** 更新 kubeconfig 内嵌客户端证或引用文件后滚动。
8. **kube-proxy / kubelet:** 节点分批；关注 `NotReady` 与 CSR 批准流程。
9. **回收:** 确认稳定后再删除旧 leaf；保留备份至下一变更窗。

## 2. 双证书 / 双 CA 窗口（CA 轮换）

CA 轮换必须单独变更窗，建议双信任：

1. 生成 **新 Cluster CA**（及按需新 etcd-CA / front-proxy-CA）。
2. **信任捆绑:** 控制面与 kubelet 在过渡期同时信任旧+新 CA（发行版支持的 `ca.crt` 拼接或等价机制）。
3. 用新 CA **重签全部 leaf**，按 §1 顺序滚动。
4. 确认所有组件与节点仅使用新 leaf 后，**撤下旧 CA**。
5. 更新所有 kubeconfig、bootstrap token 流程与 Ingress/聚合层相关信任。

切勿在未建立双信任时直接替换 CA 文件。

## 3. 组件与路径对照

| 组件 | 典型证书 | 节点路径（约定） | 仓库模板 |
|------|----------|------------------|----------|
| Cluster CA | `ca.pem` / `ca-key.pem` | `/etc/kubernetes/pki/` | `k8s/pki/ca-csr.json` |
| apiserver | `apiserver.pem` | 同上 | `apiserver-csr.json` |
| etcd | `etcd.pem` + etcd-CA | `/etc/etcd/ssl/` | `etcd-*-csr.json` |
| front-proxy | `front-proxy-*` | `/etc/kubernetes/pki/` | `front-proxy-*-csr.json` |
| CM / scheduler | 客户端证 + kubeconfig | pki + `/etc/kubernetes/*.conf` | `controller-manager-csr.json` 等 |
| admin | `admin.pem`（`O=system:masters`） | 管理机 kubeconfig | `admin-csr.json` |
| SA | `sa.pub` / `sa.key` | pki | （仓库无 CSR，运行时生成） |

加密配置 / 审计策略文件本身不是 X.509 轮换对象，但变更窗勿与证书滚动混为一次无回滚操作。

## 4. 回滚

| 阶段 | 动作 |
|------|------|
| leaf 滚动中失败 | 恢复备份 PEM/KEY + 重启对应静态 Pod/systemd；etcd 从快照恢复（若已写坏成员数据） |
| 双 CA 窗口 | 保留旧 CA 于信任包；把 leaf 改回旧证 |
| kubeconfig 损坏 | 用变更前导出的 admin kubeconfig |
| 切勿 | 无快照时强行重置 etcd；把私钥写进 Git |

## 5. 告警阈值（建议）

| 级别 | 剩余天数 | 动作 |
|------|----------|------|
| info | > 60 | 季度复查记录 |
| warn | ≤ 30 | 建变更单；跑到期检查 |
| crit | ≤ 14 | 加速轮换；控制面值班关注 |
| page | ≤ 7 或已过期 | 立即轮换 / 回滚到有效备份 |

与 `ca-config.json` 中超长 `expiry`（如 87600h）并存时，**仍按日历阈值告警**，勿因模板「很长」而跳过监控。

## 6. 到期检查脚本

仓内只读扫描（默认扫仓库内 PEM；教材仓通常无 PEM 则跳过）：

```bash
DAYS_WARN=30 bash scripts/check-cert-expiry.sh
```

现网节点可把 PEM 放在约定目录后复用同一脚本逻辑，或包装为：

```bash
# 示例：在节点上对真实目录检查（勿把输出中的敏感路径贴到公网 Issue）
DAYS_WARN=30 find /etc/kubernetes/pki /etc/etcd/ssl -type f \( -name '*.pem' -o -name '*.crt' \) ...
```

脚本说明见 [`scripts/check-cert-expiry.sh`](../../scripts/check-cert-expiry.sh)。

## 7. 相关链接

- Wiki [02-证书、鉴权与审计策略](https://github.com/a307582707/TomYang/wiki/02-证书、鉴权与审计策略)
- [MAINTENANCE.md](../MAINTENANCE.md) 控制面/etcd 台账
- [control-plane-deployment-mode.md](./control-plane-deployment-mode.md)（轮换时注意勿双跑）
