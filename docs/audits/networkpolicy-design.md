# Task 40 — NetworkPolicy 设计摘要

**状态:** 教材 / 审计材料
**示例路径:** [`examples/current/networkpolicy/`](../../examples/current/networkpolicy/)
**不用于:** 生产命名空间直接 `kubectl apply -f`（须按现网标签、CIDR、CNI 能力改写并走变更单）

## 1. 设计目标

在默认拒绝前提下，仅为以下路径开孔：

1. 工作负载 → 集群 DNS（`k8s-app: kube-dns`）
2. Ingress Controller → 应用
3. Prometheus → 带抓取标签的目标
4. Grafana → 数据源
5. fluent-bit → 日志后端

矩阵全文见 [`examples/current/networkpolicy/TRAFFIC-MATRIX.md`](../../examples/current/networkpolicy/TRAFFIC-MATRIX.md)。

## 2. 与仓库其他基线的关系

| 路径 | 关系 |
|------|------|
| `examples/current/security/networkpolicy-default-deny-ingress.yml` | 仅 Ingress deny；本 Task 扩展为 Ingress+Egress + 放行样例 |
| `k8s/addons/calico/v3.1/` | 历史 Calico（含 NetworkPolicy CRD）；新集群勿直接复用 v3.1 安装清单 |
| `k8s/addons/flannel/` | 默认无 NetworkPolicy 执行；若选 Flannel 需另接策略实现或改 CNI（见 ADR-001） |
| `k8s/master/manifests/` | 控制面多为 hostNetwork，命名空间策略无效 |

## 3. 控制面结论

- 静态 Pod（etcd、apiserver、scheduler、controller-manager、haproxy、keepalived）通常走主机网络栈。
- NetworkPolicy **不能**替代：节点安全组、主机 firewalld/iptables、VIP 管理网隔离。
- kube-proxy / CNI 节点组件同理；业务 NS 策略与控制面隔离是两套问题。

## 4. 验证 Pod（仅实验环境）

**禁止**在生产自动执行。以下为人工验证思路（镜像与命令按现网沙箱定义）：

| 步骤 | 目的 | 提示 |
|------|------|------|
| A | 确认默认拒绝生效 | 实验 NS apply `00` 后，同 NS 两 Pod `nc`/`wget` 应失败 |
| B | 确认 DNS | apply `10` 后，`nslookup kubernetes.default.svc.cluster.local` 应成功（指向 `10.96.0.10` 或现网 DNS VIP） |
| C | 确认 Ingress 开孔 | apply `20` 后，仅从控制器 Pod 网段/标签可达应用端口 |
| D | 确认 scrape | apply `30` 后，Prometheus targets 变 UP；删策略应变 DOWN |
| E | Grafana / fluent-bit | 分别验证 `40`/`50` 双向策略 |

示例一次性调试 Pod（**占位镜像**，非生产值）：

```yaml
# 勿提交真实镜像仓库账号；仅示意
apiVersion: v1
kind: Pod
metadata:
  name: np-verify-client
  namespace: "{{ TARGET_NAMESPACE }}"
spec:
  containers:
  - name: client
    image: "{{ DEBUG_IMAGE }}"
    command: ["sleep", "3600"]
  restartPolicy: Never
```

验证结束后删除 Pod 与实验策略。

## 5. 验收清单（文档级）

- [ ] CNI 已确认支持 NetworkPolicy
- [ ] 所有 `{{ ... }}` 已替换为现网值（本文不提供生产值）
- [ ] 控制面流量不依赖本目录 YAML
- [ ] 未对 `k8s/archived/**` 或生产 NS 批量 apply
