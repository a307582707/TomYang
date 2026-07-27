# Task 43 — Service / DNS 审计

**范围:** 本仓库清单中的 Service 选择器、CoreDNS、历史 kube-dns、external-dns、集群 DNS IP `10.96.0.10`。
**不包含:** 现网生产 endpoint 实值；占位与教材值仅作对照。

## 1. 关键 DNS 路径（教材）

```text
kubelet clusterDNS → 10.96.0.10
       ↓
Service/kube-system/kube-dns  (CoreDNS Deployment，标签 k8s-app: kube-dns)
       ↓
解析 *.cluster.local / 上游 /etc/resolv.conf
```

| 配置点 | 路径 | 观察 |
|--------|------|------|
| kubelet | `k8s/master/etc/kubelet/kubelet-conf.yml`、`k8s/node/etc/kubelet/kubelet-conf.yml` | `clusterDNS` 含 `10.96.0.10` |
| CoreDNS Service | `k8s/addons/coredns/coredns.yml` | `metadata.name: kube-dns`，`clusterIP: 10.96.0.10`，`selector: k8s-app: kube-dns` |
| CoreDNS Deployment | 同上 | `k8s-app: kube-dns`（兼容历史 kube-dns 服务名） |
| 旧 kube-dns | `k8s/addons/Kubedns/kubedns.yml` | 同样占用 `10.96.0.10` + `k8s-app: kube-dns` — **勿与 CoreDNS 同时安装** |

命名映射建议见 [`naming-normalization-map.md`](./naming-normalization-map.md)（`Kubedns` → 归档）。

## 2. Service 选择器抽查

| Service | 路径 | selector | 后端工作负载标签 | 结论 |
|---------|------|----------|------------------|------|
| `kube-dns`（CoreDNS） | `k8s/addons/coredns/coredns.yml` | `k8s-app: kube-dns` | Deployment 同标签 | 匹配 |
| `kube-dns`（旧） | `k8s/addons/Kubedns/kubedns.yml` | `k8s-app: kube-dns` | 旧 Pod 模板同标签 | 与 CoreDNS **冲突风险** |
| `nginx` | `k8s/apps/nginx/nginx-svc.yml` | `app: nginx` | `k8s/apps/nginx/nginx-dp.yml`（应含 `app: nginx`） | 应用示例 |
| `demo-web` | `examples/current/apps/demo-web.yml` | `app: demo-web` | 同文件 Deployment | 匹配 |
| Prometheus discovery | `k8s/ExtraAddons/prometheus/kube-service-discovery/` | **无 selector** | 依赖手工 Endpoints | 见该目录 README |
| external-dns 侧 CoreDNS | `k8s/ExtraAddons/external-dns/coredns/coredns-svc-*.yml` | `k8s-app: coredns` | 与集群 DNS **不同**标签 | 独立外部 DNS 栈，勿与 `kube-dns` 混淆 |

## 3. CoreDNS 要点

- 镜像教材版：`coredns/coredns:1.2.0`（EOL 风险，见 `MAINTENANCE.md`）。
- Corefile 含 `prometheus :9153`；Service 已暴露端口名 `metrics`（与 `k8s/ExtraAddons/prometheus/servicemonitor/coredns-sm.yml` 对齐情况见 observability 审计）。
- API：清单仍含 `extensions/v1beta1` Deployment、`rbac v1beta1` — 新集群须重建，而非原地 apply。

## 4. kube-dns 遗留

| 风险 | 说明 |
|------|------|
| 双栈 DNS | `Kubedns/` 与 `coredns/` 均想占用 `10.96.0.10` |
| 目录名 | `k8s/addons/Kubedns/` 大小写不规则 |
| 处置 | 新集群只部署 CoreDNS；旧目录文档化归档，禁止推荐安装 |

## 5. external-dns

路径：`k8s/ExtraAddons/external-dns/`

- 内含**另一套** CoreDNS + etcd（用于外部域名），标签 `k8s-app: coredns`。
- `external-dns` Deployment / RBAC 在 `external-dns/external-dns/`。
- `k8s/apps/nginx/nginx-svc.yml` 中有注释掉的 `external-dns.alpha.kubernetes.io/hostname` 示例。
- 与集群内 `kube-dns` **并行存在时**必须隔离命名空间与入口，避免运维误把外部 CoreDNS 当成集群 DNS。

## 6. `10.96.0.10` 检查清单

- [ ] 仅一个 Service 声明该 clusterIP（应为 CoreDNS 的 `kube-dns`）
- [ ] 所有 kubelet `clusterDNS` 指向同一地址（或现网 DNS VIP，**现网定义**）
- [ ] 主机 `/etc/resolv.conf` 与上游转发符合 INFRA-01
- [ ] NetworkPolicy 放行 53（见 `examples/current/networkpolicy/10-allow-dns.yml`）

## 7. 排障列表（人工）

按顺序缩小范围；命令在现网执行，本文不绑定生产输出。

1. **Pod 是否有 DNSConfig / 自定义 ndots** — `kubectl get pod -o yaml` 查 `dnsPolicy`。
2. **/etc/resolv.conf** — 是否指向 `10.96.0.10`（或现网）。
3. **Service 是否存在** — `kubectl -n kube-system get svc kube-dns -o wide`。
4. **Endpoints 是否为空** — selector 与 Pod 标签是否一致；副本是否 Ready。
5. **CoreDNS 日志** — 查 `NXDOMAIN` / `SERVFAIL` / 上游超时。
6. **与旧 kube-dns 冲突** — 是否误 apply `k8s/addons/Kubedns/`。
7. **NetworkPolicy** — 业务 NS 默认拒绝 egress 却未放行 53。
8. **kube-proxy / CNI** — Service VIP 是否可达（节点路由、`10.244.0.0/16`）。
9. **external-dns 混淆** — 是否把 `ExtraAddons/external-dns` 的 CoreDNS 当集群 DNS。
10. **搜索域** — `cluster.local` 与业务后缀是否符合预期。
11. **API Server 可达性** — CoreDNS `kubernetes` 插件失败时查 SA / RBAC。
12. **metrics 9153** — 仅监控问题，与解析正交，但可判断进程存活。

## 8. 结论（审计）

- 教材设计以 **CoreDNS 冒充服务名 `kube-dns` + 固定 `10.96.0.10`** 保持 kubelet 兼容。
- **遗留 `Kubedns/` 与 external-dns 内嵌 CoreDNS** 是主要认知陷阱。
- 示例应用 `demo-web` / `nginx` 选择器一致；无 selector 的 Prometheus discovery 属特例，需 Endpoints。
