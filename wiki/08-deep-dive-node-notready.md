# 深度专题：Node NotReady 根因图谱（运维手册）

> 题材类型：深度专题 / 可检索手册  
> 适合标题：`Node NotReady 不要先重装：一张根因图谱搞定 90% 现场`  
> 目标：一篇写透，成为团队长期检索入口

## 0. 怎么用这篇

遇到 NotReady 时：

1. 先看 **Node Conditions + kubelet 日志**（定大类）  
2. 再进对应章节（磁盘 / 运行时 / 网络 / 证书 / 内核）  
3. 用「确认命令」验证，用「止血」恢复，用「根治」立项  

不要一上来 `reboot` 或重装节点——那会毁掉证据。

---

## 1. 30 秒分流

```bash
kubectl get node <node> -o yaml | sed -n '/conditions:/,/addresses:/p'
kubectl describe node <node> | sed -n '/Conditions/,/Addresses/p'
systemctl is-active kubelet containerd
journalctl -u kubelet -n 80 --no-pager
df -h
```

| 你看到的信号 | 优先怀疑 | 跳转 |
|--------------|----------|------|
| `DiskPressure=True` / 根盘 100% | 磁盘 | §3 |
| `MemoryPressure=True` / OOM | 内存与驱逐 | §4 |
| `NetworkUnavailable=True` | CNI | §5 |
| kubelet inactive / crash loop | 运行时/配置 | §6 |
| `x509` / `certificate has expired` | 证书 | §7 |
| 节点能 ping，但 NotReady，kubelet 报 apiserver timeout | 控制面或路由 | §8 |
| `PLEG is not healthy` | 运行时卡死/海量Pod | §6 |

---

## 2. Ready 的本质（写清原理才像专家）

节点 Ready ≈ **kubelet 能稳定向 apiserver 上报 NodeStatus**，且关键条件为 False（无压力、网络可用等）。

常见断裂点：

```text
磁盘满 → kubelet 无法写状态/驱逐风暴 → 停报
containerd 挂 → PLEG 超时 → kubelet 认为运行时不健康
CNI 未就绪 → NetworkUnavailable
时钟漂移/证书过期 → 与 apiserver 认证失败
内核 hang / 硬件 → 节点「假活」
```

---

## 3. 磁盘类（最高发）

### 3.1 症状

- `DiskPressure=True`  
- 大量 `Evicted`  
- kubelet 日志：`failed to get filesystem` / eviction  

### 3.2 确认

```bash
df -h / /var/lib/containerd /var/log
df -i
du -xh /var/log/pods | sort -h | tail
du -xh /var/lib/containerd | sort -h | tail
```

### 3.3 止血

1. 清理容器日志与无用镜像（谨慎）  
2. 排水后挂盘或扩容  
3. 先把核心业务副本调度到健康节点  

### 3.4 根治

- 统一日志走 stdout + 集群采集  
- 调整 kubelet `imageGCHighThresholdPercent`  
- 磁盘 75/85 告警 + DiskPressure 高优告警  

**典型案例**：见 [01-incident-postmortem.md](./01-incident-postmortem.md)。

---

## 4. 内存类

### 4.1 症状

- `MemoryPressure=True`  
- 节点 `dmesg` 有 OOM Killer  
- 系统组件（kubelet）被杀则直接 NotReady  

### 4.2 确认

```bash
free -h
dmesg -T | grep -i 'killed process' | tail
ps aux --sort=-%mem | head
```

### 4.3 常见根因

- 业务 Limit 过高、节点超卖过度  
- DaemonSet 内存总和被低估（尤其日志/安防 agent）  
- 内核缓存 + 容器匿名页叠加  

### 4.4 处理

- 找出 Top Pod 限流或迁走  
- 重算 DaemonSet 预留（`system-reserved` / `kube-reserved`）  
- 对无 Limit 的失控进程补 Limit  

---

## 5. 网络 / CNI 类

### 5.1 症状

- `NetworkUnavailable=True`  
- 节点 Ready 但业务不通（另一类问题）  
- CNI Pod `CrashLoopBackOff`

### 5.2 确认

```bash
kubectl -n kube-system get pod -o wide | grep -E 'calico|cilium|flannel|weave'
ip link; ip route
iptables -L -n | head   # 或 nft
journalctl -u kubelet | grep -i cni
```

### 5.3 典型坑

| 坑 | 现象 | 处理 |
|----|------|------|
| IP 池耗尽 | 新 Pod 无法分配 IP | 扩 CIDR / 回收泄漏 |
| MTU 不匹配 | 大包失败、偶发超时 | 统一 MTU（云网卡/隧道） |
| kube-proxy 模式混用 | 部分服务不通 | iptables/ipvs 统一 |
| 节点安全组漏放行 | 跨节点 Pod 不通 | 放行节点网段/VXLAN 端口 |

---

## 6. 运行时 / PLEG 类

### 6.1 症状

```text
PLEG is not healthy: pleg was last seen active N ago
```

### 6.2 含义

kubelet 通过 PLEG 感知容器状态；运行时卡住或 Pod 过多时，PLEG 超时，节点变 NotReady。

### 6.3 确认

```bash
systemctl status containerd
crictl info
crictl ps | wc -l
journalctl -u containerd -n 100 --no-pager
```

### 6.4 处理

1. 重启 containerd（先排水）  
2. 排查磁盘 IO util 是否 100%（和 §3 联动）  
3. 限制单节点 Pod 密度；拆分 DaemonSet  

---

## 7. 证书 / 时钟类

### 7.1 症状

kubelet 日志：

```text
x509: certificate has expired or is not yet valid
Unable to authenticate ...
```

### 7.2 确认

```bash
# 节点时间
timedatectl
# kubelet 客户端证（路径因发行版而异）
openssl x509 -in /var/lib/kubelet/pki/kubelet-client-current.pem -noout -dates
```

### 7.3 处理

- 同步 NTP（所有节点 + 控制面）  
- 轮换 kubelet 客户端证书 / 重加节点  
- 检查集群 CA 是否临期（控制面更致命）  

---

## 8. 控制面 / 连通类

### 8.1 症状

节点本身资源正常，但：

```text
Error updating node status: ... dial tcp ... i/o timeout
```

### 8.2 分流

| 范围 | 判断 |
|------|------|
| 单节点 | 节点到 apiserver LB 的路由/安全组 |
| 多节点同时 | apiserver / etcd 性能或 LB |
| 仅某机房 | 专线/DNS |

### 8.3 控制面快速看

```bash
kubectl get --raw='/readyz?verbose'
kubectl -n kube-system get pod -l component=kube-apiserver
# etcd 延迟（若有 metrics）
```

---

## 9. 决策树（可放 Wiki 首页）

```text
NotReady
  ├─ Conditions 有 Disk/Memory Pressure → 资源压力章节
  ├─ NetworkUnavailable → CNI
  ├─ kubelet 挂 / PLEG → 运行时
  ├─ x509 / 时间错 → 证书时钟
  └─ 上报 apiserver 超时 → 网络路径或控制面
```

---

## 10. 现场纪律（专业度细节）

1. **先采集证据包再重启**：`describe node`、kubelet/containerd 日志、`df`、`dmesg`、CNI Pod 日志。  
2. **排水优于重启**：`kubectl drain --ignore-daemonsets --delete-emptydir-data`（按业务评估）。  
3. **改配置要留痕**：kubelet 参数变更走 Ansible/Ignition/镜像，不写一次性手改。  
4. **复盘必填**：首次误判是什么——手册才能进化。  

---

## 11. 建议配套监控告警

| 告警 | 阈值建议 | 级别 |
|------|----------|------|
| Node NotReady | > 2min | Sev-1（核心池） |
| DiskPressure | 立即 | Sev-2 |
| 节点磁盘 | 75% warning / 85% critical | Sev-2/1 |
| PLEG unhealthy | > 3min | Sev-2 |
| 证书临期 | 30 天 | Sev-2 |
| apiserver error rate | 基线异常 | Sev-1 |

---

## 12. 和本 Wiki 其他文章的关系

- 完整事故叙事：[01-incident-postmortem.md](./01-incident-postmortem.md)  
- 成本侧的密度与 Request：[03-capacity-cost.md](./03-capacity-cost.md)  
- 排查路径方法论：[04-observability.md](./04-observability.md)  

把本文当作「字典」，把 01 当作「故事」，两者一起发，既有传播点又有长期价值。
