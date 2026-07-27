# Task 35 — RBAC 权限矩阵

**范围:** `k8s/` 下全部 Role / ClusterRole / RoleBinding / ClusterRoleBinding / ServiceAccount（含 `archived/`）。
**原则:** 不建议在未评审的情况下自动收紧**运行时关键**绑定（如 apiserver→kubelet、CNI、bootstrap）。

## 1. 清单索引（按路径）

| 区域 | 路径 | 主要对象 |
|------|------|----------|
| 控制面 | `k8s/master/resources/apiserver-to-kubelet-rbac.yml` | ClusterRole + Binding（User `kube-apiserver`） |
| 控制面 | `k8s/master/resources/kubelet-bootstrap-rbac.yml` | 3× ClusterRoleBinding → 内置 bootstrap/CSR 角色 |
| DNS | `k8s/addons/coredns/coredns.yml` | SA + ClusterRole `system:coredns` |
| DNS(旧) | `k8s/addons/Kubedns/kubedns.yml` | SA `kube-dns` only |
| 代理 | `k8s/addons/kube-proxy/kube-proxy.yml` | SA + Binding → `system:node-proxier` |
| CNI | `k8s/addons/flannel/kube-flannel.yml` | SA/CR/CRB `flannel` |
| CNI | `k8s/addons/calico/v3.1/rbac-kdd.yml`、`calico.yml`、`calicoctl.yml` | `calico-node` / `calicoctl` |
| Ingress | `k8s/ExtraAddons/ingress-controller/ingress-controller-{sa,rbac}.yml` | Role + ClusterRole |
| ExternalDNS | `k8s/ExtraAddons/external-dns/external-dns/external-dns-{sa,rbac}.yml` | 只读 Services/Pods/Ingresses/Nodes |
| Prometheus | `k8s/ExtraAddons/prometheus/**/{*-sa.yml,*-rbac.yml}` | operator / prometheus / node-exporter / kube-state-metrics 等 |
| 归档 Dashboard | `k8s/archived/dashboard/kubernetes-dashboard.yml` | 命名空间内 minimal Role（**无** cluster-admin） |
| 归档 EFK | `k8s/archived/efk/*-{sa,rbac}.yml` | ES / fluentd ClusterRole |
| 归档 metrics | `k8s/archived/metric-server/metrics-server*.yml` | metrics-server + auth-delegator |
| 归档 Weave | `k8s/archived/WeaveScope/scope.yml` | ClusterRole 含 delete pods、scale 等 |

> 原 Dashboard 匿名代理 + `cluster-admin` 绑定文件已删除，见 `k8s/archived/ARCHIVED.md`。**禁止恢复。**

## 2. 高风险发现

| 风险 | 对象 | 路径 | 说明 | 处置建议 |
|------|------|------|------|----------|
| `verbs: ["*"]` | ClusterRole `system:kube-apiserver-to-kubelet` | `k8s/master/resources/apiserver-to-kubelet-rbac.yml` | 对 `nodes/proxy|stats|log|spec|metrics` 全动词；**控制面必要** | 保留；勿在未验证 kubectl/logs/exec 前收紧 |
| `verbs: ['*']`（多组资源） | ClusterRole `prometheus-operator` | `k8s/ExtraAddons/prometheus/operator/operator-rbac.yml` | CRD、monitoring CR、StatefulSet、CM/Secret 等全动词 | 升级 Operator 时改用官方最小 Role；**勿盲目删**以免 Operator 无法调和 |
| 隐式 cluster-admin | 用户 `admin`（PKI `O=system:masters`） | `k8s/pki/admin-csr.json` | 非 Binding 文件，但等价最高权 | 限制分发；改用个人低权 kubeconfig |
| Bootstrap 自动批准 | Group `system:bootstrappers` / `system:nodes` | `k8s/master/resources/kubelet-bootstrap-rbac.yml` | 节点 CSR 自动批准 | 生产收紧 bootstrap Token 生命周期与网络 |
| auth-delegator | metrics-server Binding | `k8s/archived/metric-server/*.yml` | 归档；委托认证能力 | 保持归档；现代 metrics-server 用发行版清单 |
| Weave 删 Pod / scale | ClusterRole `weave-scope` | `k8s/archived/WeaveScope/scope.yml` | 归档反例 | **禁止部署** |
| Dashboard 历史 cluster-admin | （已删文件） | 曾位于 ExtraAddons/dashboard | 已移除 | 勿从 git 历史恢复到生产 |

**本仓库当前扫描:** 无存活的 `roleRef.name: cluster-admin` Binding；无 `apiGroups: ["*"]` + `resources: ["*"]` 的超级 ClusterRole。通配主要集中在 **verbs=\*** 的受限资源集合。

## 3. 中风险 / 只读面较大

| 组件 | 路径 | 备注 |
|------|------|------|
| `prometheus-k8s` ClusterRole | `.../prometheus/prometheus-rbac.yml` | 节点/服务/端点等 list/watch（采集所需） |
| `kube-state-metrics` | `.../kube-state-metrics-rbac.yml` | 广读集群对象状态 |
| `nginx-ingress-clusterrole` | `.../ingress-controller-rbac.yml` | Ingress/Endpoints 等写能力（控制器所需） |
| `calico-node` / `calicoctl` | `addons/calico/v3.1/` | 网络策略与节点配置；calicoctl 权限更宽 |
| `fluentd-es` / `elasticsearch-logging` | `archived/efk/` | 归档；日志采集读权限 |

## 4. 评审注意事项

- **不要**用脚本批量删除 `verbs: *` 或 bootstrap Binding。
- 变更前在实验室验证：`kubectl auth can-i --list --as=system:serviceaccount:...`。
- 归档目录权限再高也不应 apply；治理重点是安装入口隔离（见 `scripts/check-archived-isolation.sh`）。

## 修改摘要

### 风险
- Operator / apiserver→kubelet 的通配动词若被误删会导致监控或节点代理功能失败。
- `system:masters` 客户端证书泄露即集群失陷。

### 遗留
- Prometheus Operator RBAC 仍为旧版宽权限。
- 归档 Weave/metrics-server 权限面仍存在于树中（仅文档禁止）。

### 回滚
- 文档-only。若曾手工改 Binding，用 git 中原始 YAML 恢复对应文件。
