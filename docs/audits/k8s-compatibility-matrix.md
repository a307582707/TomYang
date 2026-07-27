# Task 2 — 现代 Kubernetes 兼容性分析（逐文件迁移矩阵）

**分支:** `audit/k8s-compatibility`  
**原则:** 只输出分析与迁移建议，**不批量修改**有运行时风险的历史清单。  
**基线仓库:** Kubernetes ~1.11 / etcd 3.3 / Calico 3.1 / CoreDNS 1.2 时代手工搭建归档。

## 1. 总览

| 维度 | 现状 | 现代目标（建议） | 风险 |
|------|------|------------------|------|
| Kubernetes | 镜像 `v1.11.1` / `v1.11.3` | 新建 ≥1.28+ 集群后迁移工作负载 | 跨大版本原地升级不可行 |
| etcd | `v3.3.9`、`v3.1.9`（external-dns 旁路） | 与目标 K8s 匹配的 etcd 3.5.x | 需快照演练 |
| CNI | Calico 3.1 / Flannel 0.10 | 当前发行版 Calico/Cilium/Flannel | IP 池与策略不兼容直接复用 |
| Ingress | nginx-ingress-controller `0.17.0` + `extensions/v1beta1` Ingress | Ingress NGINX/Gateway API + `networking.k8s.io/v1` | 注解与路径语法变化 |
| 监控 | Prometheus Operator `v0.22.0` | kube-prometheus-stack 现行版本 | CRD/API 大变 |
| 运行时 | kubelet `--network-plugin=cni`、暗示 Docker 时代 | containerd/CRI-O | dockershim 已移除 |
| cgroup | `cgroupDriver: cgroupfs` | 与 runtime 一致的 `systemd` | 混用导致 Evicted/不稳定 |
| RBAC | 大量 `v1beta1` | `rbac.authorization.k8s.io/v1` | beta 已移除 |
| 审计/加密 | `--admission-control`、`experimental-encryption-provider-config`、`aescbc` | `--enable-admission-plugins`、`--encryption-provider-config`、受支持 provider | 参数更名 |

## 2. 已废弃 / 移除的 API（仓库扫描）

| API | 状态（相对现代 K8s） | 出现文件数（约） | 迁移动作 |
|-----|----------------------|------------------|----------|
| `extensions/v1beta1` | 已移除 | DaemonSet/Deployment/Ingress 多处 | → `apps/v1` 或 `networking.k8s.io/v1` |
| `apps/v1beta1` / `apps/v1beta2` | 已移除 | Calico、Dashboard、Grafana、Operator 等 | → `apps/v1` |
| `rbac.authorization.k8s.io/v1beta1` | 已移除 | Calico、CoreDNS、Flannel、Ingress、external-dns 等 | → `v1` |
| `apiregistration.k8s.io/v1beta1` | 已移除 | metrics-server | → `v1` |
| `apiextensions.k8s.io/v1beta1` | 已移除 | Calico CRD | → `v1`（schema 必填） |

## 3. 控制面 / kubelet 参数差异

| 参数 / 配置 | 位置 | 问题 | 迁移 |
|-------------|------|------|------|
| `--insecure-port=0` | apiserver 清单/systemd | 仍出现在旧模板；不安全端口已移除 | 删除相关项，只保留 secure port |
| `--admission-control=...,Initializers,...` | apiserver | `Initializers` 已移除；旗标更名 | `--enable-admission-plugins` / `--disable-admission-plugins` |
| `--experimental-encryption-provider-config` | apiserver | 实验旗标更名 | `--encryption-provider-config` |
| `--allow-privileged=true` | apiserver / kubelet drop-in | 行为变化，默认模型不同 | 按 Pod Security / 策略收敛 |
| `--network-plugin=cni` | kubelet systemd | dockershim/网络插件旗标过时 | CRI + CNI 由 runtime/CNI 管理 |
| `readOnlyPort: 10255` | `kubelet-conf.yml` | 只读端口默认关闭/移除 | 设为 `0`，用鉴权 10250 |
| `cgroupDriver: cgroupfs` | kubelet-conf | 与现代 containerd systemd 驱动常冲突 | 与 runtime 对齐为 `systemd` |
| metrics-server `--deprecated-kubelet-completely-insecure` | metrics-server-1.12+ | 跳过 TLS/鉴权 | 删除；配置 kubelet 鉴权抓取 |
| `--failSwapOn: true` | kubelet-conf | 仍常见 | 可保留；确认节点无 swap |

## 4. EOL 镜像与组件（摘录）

| 组件 | 仓库标签 | 评估 | 建议 |
|------|----------|------|------|
| kube-apiserver 等 | `v1.11.1` | EOL | 新集群新版本，不复用 |
| etcd | `v3.3.9` / `v3.1.9` | EOL | 升级路径 + 备份恢复演练 |
| Calico | `v3.1.3` | EOL | 重建 CNI |
| CoreDNS | `1.2.0` / `1.1.4` | EOL | 现行 CoreDNS chart/清单 |
| kube-dns | `1.14.7` | 已由 CoreDNS 取代 | 归档，勿新装 |
| Flannel | `v0.10.0` | EOL | 重建 |
| Ingress NGINX | `0.17.0` | EOL | 现行控制器 + v1 Ingress |
| Dashboard | `v1.8.3` | EOL + 安全差 | 现行 Dashboard 或禁用 |
| Prometheus Operator | `v0.22.0` | EOL | kube-prometheus-stack |
| Grafana | `5.1.0` | EOL | 现行 Grafana |
| ES/Fluentd/Kibana | 6.2.x / v2.2.0 | EOL | 现行 EFK/ELK 或替代 |
| Weave Scope | `1.10.1` | 停更 | 移除 |
| HAProxy 镜像 | `kairen/haproxy:1.7` | 过旧 | 官方/自建镜像并锁定版本 |
| metrics-server | `v0.2.1` / `v0.3.1` | EOL | 现行 metrics-server |

## 5. Docker → containerd

| 现状线索 | 影响 | 迁移要求 |
|----------|------|----------|
| kubelet `network-plugin=cni`、pause 镜像旧标签 | 假设 Docker 时代节点代理 | 安装 containerd、配置 CRI socket、去掉 dockershim 依赖 |
| Weave Scope 挂载 Docker socket（见安全审计） | 强依赖 Docker | 删除或换工具 |
| `crictl`/`nerdctl` 运维命令未出现在旧 Wiki 教程 | 排障手册需更新 | INFRA/Runbook 改用 CRI 命令 |

**建议顺序:** 先新节点 containerd → 再切工作负载 → 最后退役 Docker 节点。

## 6. cgroupfs → systemd

| 文件 | 当前 | 迁移 |
|------|------|------|
| `k8s/master/etc/kubelet/kubelet-conf.yml` | `cgroupDriver: cgroupfs` | 改为 `systemd`，并与 containerd `SystemdCgroup = true` 一致 |
| `k8s/node/etc/kubelet/kubelet-conf.yml` | 同上 | 同上 |
| 运行时 | 未入库 containerd config | 新增示例到 `examples/`（后续任务），勿直接改生产旧清单冒充可用 |

## 7. RBAC / Ingress / CRD / 审计差异摘要

- **RBAC:** `v1beta1` → `v1`；复核 `cluster-admin` 绑定（Dashboard/匿名代理）。
- **Ingress:** `extensions/v1beta1` → `networking.k8s.io/v1`（必填 `pathType`、`ingressClassName`）。
- **CRD:** Calico `apiextensions.v1beta1` → `v1`，需完整 `openAPIV3Schema`。
- **审计:** 策略结构大体兼容，但需按目标版本校验 `omitStages` 等字段；apiserver 旗标路径保持 `/etc/kubernetes/audit-policy.yml`。
- **加密配置:** `aescbc` 仍可用但更推荐 KMS；旗标更名见上。

## 8. 逐文件迁移矩阵（核心）

图例：`H`=高（不可直接 apply）`M`=中 `L`=低（结构可参考）`Skip`=建议归档勿迁

| 文件 | 废弃 API | EOL 镜像/参数 | 运行时风险 | 建议动作 | 目标形态 |
|------|----------|---------------|------------|----------|----------|
| `master/manifests/kube-apiserver.yml` | — | v1.11.1；admission-control；experimental-encryption | H | 按目标版本重写静态 Pod/或 kubeadm | 新控制面 |
| `master/manifests/etcd.yml` | — | etcd 3.3.9 | H | 新 etcd 拓扑 + 备份 | etcd 3.5.x |
| `master/manifests/kube-controller-manager.yml` | — | v1.11.1 | H | 重写 | 匹配 apiserver 版本 |
| `master/manifests/kube-scheduler.yml` | — | v1.11.1 | H | 重写 | 同上 |
| `master/manifests/haproxy.yml` | — | haproxy:1.7 | M | 换镜像+配置校验 | 现行 HAProxy |
| `master/manifests/keepalived.yml` | — | keepalived 1.3.9 | M | 复核检查脚本与 VIP | 现行 keepalived |
| `master/systemd/*` | — | 旧旗标；与静态 Pod 双轨 | M | 文档收敛为一种方式 | INFRA-01 为准 |
| `master/etc/kubelet/kubelet-conf.yml` | — | cgroupfs；readOnlyPort 10255 | H | 新 kubelet 配置 | systemd cgroup；只读端口 0 |
| `node/etc/kubelet/kubelet-conf.yml` | — | 同上 | H | 同上 | 同上 |
| `pki/*.json` | — | 结构仍可参考 | L | 保留模板；轮换算法/期限复核 | cfssl/cert-manager |
| `addons/calico/v3.1/*` | extensions/apps beta；CRD v1beta1；rbac beta | Calico 3.1 | H | Skip 重建 | 现行 Calico |
| `addons/flannel/*` | extensions；rbac beta | Flannel 0.10 | H | Skip 重建 | 现行 Flannel/其他 |
| `addons/coredns/coredns.yml` | extensions；rbac beta | CoreDNS 1.2.0 | H | 重建 | 现行 CoreDNS |
| `addons/Kubedns/*` | extensions | kube-dns | Skip | 归档 | 使用 CoreDNS |
| `addons/kube-proxy/*` | extensions；rbac beta | kube-proxy 1.11.3 | H | 随控制面版本重建 | 匹配 K8s |
| `addons/metric-server/*.yml` | extensions；apiregistration beta | 不安全 kubelet 抓取 | H | 重建；去 insecure | 现行 metrics-server |
| `apps/nginx/*` | extensions Ingress/Deploy | `nginx` latest | M | 示例可现代化（Task1 已部分做） | apps/v1 + networking/v1 |
| `ExtraAddons/ingress-controller/*` | extensions；rbac beta | 0.17.0 | H | 重建 | 现行 Ingress 控制器 |
| `ExtraAddons/prometheus/**` | apps/v1beta2；extensions Ingress | Operator 0.22；Grafana 5.1 | H | 换 kube-prometheus-stack | 现行栈 |
| `ExtraAddons/efk/**` | — | ES/Kibana 6.2 | H | 重建日志栈 | 现行方案 |
| `ExtraAddons/external-dns/**` | extensions；rbac beta | external-dns 0.5.4；etcd 3.1.9 | H | 重建 | 现行 external-dns |
| `ExtraAddons/dashboard/**` | apps/v1beta2 | Dashboard 1.8.3；过大权限 | H | Skip 或重建加固 | 现行 + SSO |
| `ExtraAddons/WeaveScope/**` | extensions | 停更 + Docker socket | Skip | 删除/归档 | 其他可观测工具 |
| `ExtraAddons/prometheus/servicemonitor/*` | monitoring CR（随 Operator） | 依赖旧 Operator CRD | M | 随监控栈重建 | 现行 SM API |

## 9. 推荐迁移顺序（不改本仓运行时）

1. 新建目标版本集群（kubeadm/kubean/供应商发行版）。  
2. 重建网络、Ingress、证书与入口 VIP 策略。  
3. 迁移无状态工作负载 → 有状态 → 可观测与日志。  
4. 对照本矩阵逐项勾选退役旧镜像与旧 API。  
5. 本仓库继续作为 **1.11 手工拓扑教材**，新示例放 `examples/`（后续任务）。

## 10. 检查结果

- [x] 扫描 `k8s` 下 apiVersion / image / 关键旗标  
- [x] 形成逐文件矩阵与 Docker/cgroup/RBAC 专节  
- [x] **未**批量修改生产向清单  

## 风险说明

矩阵中的「目标版本」为通用建议，需按海曦现网选定具体发行版后再定镜像标签。错误地对旧清单做半自动 API 改写可能导致「能 apply 但行为错误」。

## 未解决事项

- 选定海曦现网目标 Kubernetes 小版本与 CNI 产品后，可将矩阵「目标形态」列固化为版本钉扎表（Task 9）。  
- 具体安全项（匿名 Dashboard 等）见 Task 3。  

## 回滚方法

本 PR 仅新增文档；关闭 PR 或删除 `docs/audits/k8s-compatibility-matrix.md` 即可。
