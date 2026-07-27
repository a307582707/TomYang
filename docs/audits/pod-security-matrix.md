# Task 36 — Pod 安全矩阵

**范围:** `k8s/` 工作负载中的 `privileged`、`hostNetwork`、`hostPID`、`hostIPC`、`hostPath`、`docker.sock`、`allowPrivilegeEscalation` 等。
**分类:** **控制面/CNI 必要** vs **可移除/应淘汰（含归档）**。

## 总表

| 文件 | 能力 | 分类 | 说明 |
|------|------|------|------|
| `k8s/master/manifests/kube-apiserver.yml` | hostNetwork；多 hostPath（pki、etcd ssl、audit、encryption） | **必要** | 静态 Pod 读主机证书与策略 |
| `k8s/master/manifests/etcd.yml` | hostNetwork；hostPath ssl/config/data | **必要** | |
| `k8s/master/manifests/kube-controller-manager.yml` | hostNetwork；hostPath pki/kubeconfig/volume plugins | **必要** | |
| `k8s/master/manifests/kube-scheduler.yml` | hostNetwork；hostPath pki/kubeconfig | **必要** | |
| `k8s/master/manifests/haproxy.yml` | hostNetwork；hostPath `haproxy.cfg` | **必要**（本 HA 设计） | VIP:8443 |
| `k8s/master/manifests/keepalived.yml` | hostNetwork；**privileged**；NET_ADMIN | **必要**（本 HA 设计） | VIP 漂移 |
| `k8s/addons/kube-proxy/kube-proxy.yml` | hostNetwork；**privileged**；hostPath xtables/modules | **必要** | |
| `k8s/addons/flannel/kube-flannel.yml` | hostNetwork；**privileged**；hostPath CNI/run | **必要**（若选 flannel） | 与 calico 互斥 |
| `k8s/addons/calico/v3.1/calico.yml` | hostNetwork；calico-node **privileged**；多 hostPath CNI | **必要**（若选 calico） | |
| `k8s/addons/calico/v3.1/calicoctl.yml` | hostNetwork | 运维工具 | 非常驻；限制使用 |
| `k8s/addons/coredns/coredns.yml` | `allowPrivilegeEscalation: false`；drop ALL + NET_BIND_SERVICE；hostPath `/etc/localtime` | 可接受 | localtime hostPath **可移除**（改镜像时区或空） |
| `k8s/ExtraAddons/prometheus/node-exporter/node-exporter-ds.yml` | hostNetwork；**hostPID**；hostPath `/proc` `/sys` | 采集常见 | 可评估改 node exporter 安全模式；非控制面必要 |
| `k8s/ExtraAddons/prometheus/operator/operator.yml` | securityContext（非 privileged） | 可接受 | |
| `k8s/ExtraAddons/prometheus/grafana/grafana-dp.yml` | securityContext | 可接受 | |
| `k8s/ExtraAddons/prometheus/kube-state-metrics/kube-state-metrics-dp.yml` | securityContext | 可接受 | |
| `k8s/ExtraAddons/ingress-controller/ingress-controller.yml` | capabilities drop ALL + NET_BIND_SERVICE；runAsUser 33 | 可接受 | 无 hostNetwork |
| `k8s/ExtraAddons/external-dns/coredns/etcd-dp.yml` | hostPath `/var/lib/coredns-etcd` | 可评估 | 数据目录；注意权限 |
| `k8s/apps/nginx/nginx-dp.yml` | 无上述高危字段 | 低 | 示例应用 |
| `k8s/archived/WeaveScope/scope.yml` | **privileged**；hostNetwork；hostPID；**docker.sock** hostPath | **应淘汰** | 禁止部署 |
| `k8s/archived/efk/elasticsearch-sts.yml` | init **privileged** | **应淘汰**（归档） | sysctl 类历史做法 |
| `k8s/archived/efk/fluentd-es-ds.yaml` | hostPath `/var/log`、docker containers | 归档 | 日志采集常见但 EOL 栈 |
| `k8s/archived/metric-server/metrics-server*.yml` | hostPath `/etc/kubernetes/pki` | 归档 | 另有 insecure kubelet 抓取标志 |

**未发现:** 活跃（非归档）清单挂载 `docker.sock`。
**hostIPC:** 扫描未发现 `hostIPC: true`。

## 区分结论

### 控制面 / 数据面必要（保留并加固节点）
- 静态 Pod：`hostNetwork` + 证书/数据 `hostPath`
- keepalived：`privileged` / `NET_ADMIN`
- kube-proxy、Calico/Flannel：特权与主机网络

加固方式：限制 master/node SSH、文件权限、只读挂载（已多处 `readOnly: true`）、网络策略与审计——而非简单去掉字段。

### 可移除或应迁出
- CoreDNS `hostPath: /etc/localtime`
- node-exporter `hostPID`（按现网采集方案评估）
- 整个 `k8s/archived/**`（Weave docker.sock、ES privileged 等）
- 任何重新引入 Dashboard 匿名高权或 Scope 的尝试

## 修改摘要

### 风险
- 误删 CNI/控制面 privileged 或 hostNetwork 会导致失联。
- 归档清单若被 apply，docker.sock / privileged ES 会扩大逃逸面。

### 遗留
- node-exporter hostPID/hostNetwork 未改为更安全采集。
- WeaveScope / EFK 仍留在树中作反例。

### 回滚
- 文档-only。清单回滚用 git；运行时需按组件滚动恢复静态 Pod/DaemonSet。
