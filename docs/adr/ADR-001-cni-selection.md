# ADR-001：CNI 选型（Calico / Cilium / Flannel）

- **状态:** 提议（Accepted for documentation；**本 ADR 不含安装步骤，禁止在本文触发 CNI 安装**）
- **任务:** Task 42
- **日期:** 2026-07-27
- **决策者:** 仓库维护者 / 现网平台组（最终以现网变更为准）

## 背景

本仓库教材集群使用 Pod CIDR **`10.244.0.0/16`**，并写入多处清单：

| 路径 | 用途 |
|------|------|
| `k8s/master/manifests/kube-controller-manager.yml` | `--cluster-cidr=10.244.0.0/16` |
| `k8s/addons/kube-proxy/kube-proxy.yml` / `kube-proxy.conf` | `clusterCIDR: 10.244.0.0/16` |
| `k8s/addons/flannel/kube-flannel.yml` | `net-conf.json` → `"Network": "10.244.0.0/16"` |
| `k8s/addons/calico/v3.1/calico.yml` | IP 池相关环境变量含 `10.244.0.0/16` |

历史组件版本（见 `docs/MAINTENANCE.md`）：Calico **v3.1.3**、Flannel **v0.10.0**，均属教材归档级别，**不可**作为新生产安装源。

仓内 **无** Cilium 清单；Cilium 仅作为选型候选出现在本文。

## 决策驱动因素

1. 是否需要 Kubernetes **NetworkPolicy**（见 `examples/current/networkpolicy/`、`examples/current/security/`）。
2. 与现有 **`10.244.0.0/16`** 及 Service CIDR（教材 DNS `10.96.0.10`）的兼容 / 迁移成本。
3. 运维复杂度、可观测性、kube-proxy 替代（eBPF）需求。
4. 与自建控制面（非 kubeadm）的集成方式 — 细节属现网 INFRA 变更，不在本 ADR 展开安装。

## 方案比较

| 维度 | Calico | Cilium | Flannel |
|------|--------|--------|---------|
| 仓内历史清单 | `k8s/addons/calico/v3.1/` | 无 | `k8s/addons/flannel/` |
| NetworkPolicy | 支持（教材版本亦声明 NP/GNP CRD） | 支持（含扩展策略能力） | **默认不执行** K8s NetworkPolicy |
| 数据平面 | iptables / eBPF（视发行版） | eBPF 为主 | VXLAN/host-gw 等 |
| `10.244.0.0/16` | 可配置为同 CIDR；**勿直接复用 v3.1 YAML** | 可配置同 CIDR；需现网发行版清单 | 教材已用该网段 |
| kube-proxy | 通常保留 | 可选 kube-proxy-free | 通常保留 |
| 运维成本 | 中高（Felix/Typha 等） | 中高（Agent/Operator） | 较低 |
| 适合 | 需要策略与成熟路由/策略模型 | 需要 eBPF、Hubble、现代可观测 | 仅连通、无策略需求的实验 |

## `10.244.0.0/16` 兼容性结论

- **保留该 Pod CIDR** 时：三种 CNI 均可在**新安装**中配置为同一网段，前提是与 `kube-controller-manager --cluster-cidr`、`kube-proxy clusterCIDR` 一致。
- **禁止**在运行中的集群上「换 CNI 却不重做节点网络」；CIDR 冲突或双 CNI 并存会导致现网事故。迁移 = 现网定义的维护窗口 + 回滚方案（`MAINTENANCE.md`）。
- Service CIDR / `clusterDNS: 10.96.0.10`（`k8s/*/etc/kubelet/kubelet-conf.yml`）与 CNI 选型正交，但改 Pod CIDR 时需同步整链配置。

## 决策（文档立场）

| 场景 | 建议 |
|------|------|
| 新集群且需要 NetworkPolicy / 与 `examples/current/networkpolicy` 对齐 | **优先 Calico 或 Cilium（现网发行版）**；二选一由平台组按 eBPF/技能栈拍板 |
| 仅临时实验、明确不需要 NetworkPolicy | Flannel 可接受；须在文档标明「无 NP」 |
| 沿用本仓 `k8s/addons/calico/v3.1` 或 `flannel` YAML 装生产 | **拒绝** |

**本 ADR 不选择具体生产版本号、不提供 install 命令、不修改节点。**

## 后果

- 正：与 Task 40 策略示例、安全基线一致时，CNI 必须具备策略执行能力。
- 负：选定 Cilium 需另建清单来源（仓外）；选定 Calico 需摆脱 v3.1 教材文件。
- 中性：无论选谁，教材 CIDR `10.244.0.0/16` 仅作兼容参考，现网可另选网段（**现网定义**）。

## 参考

- `docs/MAINTENANCE.md` — Calico / Flannel 台账
- `docs/audits/k8s-compatibility-matrix.md` — CNI 行
- `docs/audits/networkpolicy-design.md` — 策略与 CNI 前提
- Wiki [INFRA-01](https://github.com/a307582707/TomYang/wiki/INFRA-01-本仓HA控制面与节点接入) — 搭建步骤权威正文
