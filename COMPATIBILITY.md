# 兼容性与安全基线

本仓库记录 Kubernetes 1.11 时代的手工搭建方式，不是现代集群的可直接部署发行版。保留旧清单是为了展示控制面、证书、网络和监控组件的组织方式。

## 适用边界

- 基线组件：Kubernetes 1.11、etcd 3.3、Calico 3.1、CoreDNS 1.2。
- 清单中的镜像、API 和命令行参数已停止维护，可能包含公开漏洞。
- `k8s/ExtraAddons/` 是历史可选组件集合，不代表安全或受支持的默认方案。
- 所有 `{{ ... }}` 和 `{...}` 占位符必须在部署前渲染，并通过 YAML 与配置语法检查。

## 禁止直接用于生产的内容

| 范围 | 原因 | 现代化方向 |
|------|------|------------|
| `k8s/ExtraAddons/dashboard/` | Dashboard 版本过旧；匿名代理与 `cluster-admin` 绑定权限过大 | 使用受支持版本、最小权限 RBAC 和身份代理 |
| `k8s/ExtraAddons/WeaveScope/` | 特权容器、主机 PID/网络和 Docker socket 暴露 | 使用受支持的可观测工具并限制主机权限 |
| `k8s/addons/metric-server/metrics-server-1.12+.yml` | 依赖 kubelet 10255 和不安全 TLS 跳过 | 使用受支持的 metrics-server 与 kubelet 认证 |
| `k8s/master/encryption/config.yml` | `aescbc` 与旧实验参数不适用于现代版本 | 按目标版本选择受支持 provider 并执行密钥轮换 |
| `k8s/ExtraAddons/prometheus/grafana/grafana-admin-secret.yml` | Git 中的 base64 值不是加密凭据 | 部署时由 Secret 管理系统注入 |

## 现代 Kubernetes 迁移清单

1. 优先新建目标集群并迁移工作负载，不要从 1.11 跨多个版本直接原地升级。
2. 将 `extensions/v1beta1`、`apps/v1beta1`、`apps/v1beta2`、`rbac.authorization.k8s.io/v1beta1`、`apiextensions.k8s.io/v1beta1` 等 API 转换为目标版本支持的稳定 API。
3. 逐项核对 apiserver、controller-manager、scheduler、kubelet 与 kube-proxy 参数；移除 `Initializers`、只读端口和过期 feature gate。
4. 将 Docker 与 `cgroupfs` 假设迁移到受支持的 CRI runtime 和 `systemd` cgroup 驱动。
5. 重建 CNI、Ingress、metrics-server、Dashboard、Prometheus Operator 和 EFK，不复用旧镜像标签。
6. 升级 etcd 前先验证快照恢复；重新签发证书并检查 SAN、有效期和最小 TLS 版本。
7. 对所有 RBAC、Secret、特权容器、hostPath、hostNetwork 和 hostPID 配置进行安全复核。

## 本仓约定

- 控制面入口为 Keepalived VIP `:8443`。
- HAProxy 后端连接各 apiserver 的 `:5443`。
- `haproxy.cfg` 的后端 `server` 行需要按控制面节点清单补齐。
- systemd 与静态 Pod 是两种部署方式，同一组件不要同时启动。
- scheduler 和 controller-manager kubeconfig 文件名统一为 `scheduler.conf` 与 `controller-manager.conf`。
- etcd 配置文件统一放置为 `/etc/etcd/config.yml`。

## 验证

仓库静态检查只能发现语法、路径和已知危险模式，不能证明清单可在目标集群安全运行。部署前至少需要完成：

- 渲染全部占位符并再次执行 YAML/JSON/Shell 检查。
- 在隔离测试环境执行服务启动、证书、etcd 健康、VIP 漂移、DNS、网络策略和监控采集验证。
- 对镜像执行漏洞和签名检查。
- 记录目标 Kubernetes 版本、组件版本、变更与回滚方案。
