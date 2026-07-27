# 控制面部署模式：systemd vs 静态 Pod（Task 71）

**操作权威:** Wiki [INFRA-01](https://github.com/a307582707/TomYang/wiki/INFRA-01-本仓HA控制面与节点接入)。
本文仅说明本仓两种交付方式的差异与互斥规则；端口、文件名、启动顺序以 INFRA-01 + 仓库清单为准。

## 1. 结论（先读）

| 模式 | 本仓路径 | 适用 |
|------|----------|------|
| **静态 Pod（推荐教材路径）** | `k8s/master/manifests/*.yml` + kubelet `staticPodPath` | Keepalived / HAProxy / etcd / apiserver / CM / scheduler 与 INFRA-01 主流程一致 |
| **宿主机 systemd** | `k8s/master/systemd/*.service` | 希望由 systemd 管生命周期、或静态 Pod 不便调试时的备选 |

**硬性规则: 同一组件不要 systemd 与静态 Pod 双跑。** 双跑会导致端口争用（尤其 HAProxy `:8443`、apiserver `:5443`、etcd `:2379`）、VIP 异常与难以排障。

## 2. 静态 Pod 模式

1. kubelet 已安装；`kubelet-conf.yml` 中 `staticPodPath: /etc/kubernetes/manifests`。
2. 渲染后的清单放入该目录（etcd → HAProxy/Keepalived → apiserver → CM/scheduler），见 INFRA-01 §3。
3. 生命周期由 kubelet 守护；排障看 `crictl`/`docker` 日志与 kubelet 日志。
4. HA 入口仍为 **VIP:8443 → 各节点 apiserver:5443**。

## 3. systemd 模式

1. 单元模板在 `k8s/master/systemd/`（如 `kube-apiserver.service`、`etcd.service` 等）。
2. 证书与配置路径须与单元 `ExecStart` 参数一致（通常仍是 `/etc/kubernetes/pki`、`/etc/etcd/...`）。
3. 启用前确认 **未** 在 `manifests/` 放置同名组件静态 Pod。
4. Keepalived/HAProxy 若改 systemd，同样勿再放 `manifests/haproxy.yml` / `keepalived.yml`。

## 4. 选择建议

- **新集群跟 INFRA-01 教材:** 静态 Pod。
- **已有主机级编排/配置管理强绑定 systemd:** 可改 systemd，但须自备与 INFRA-01 等价的健康检查与 VIP 漂移验证。
- **混合:** 仅允许「etcd 一种模式 + apiserver 一种模式」且文档写清；禁止同一二进制双监督。

## 5. 验收

- [ ] `systemctl list-units` 与 `/etc/kubernetes/manifests` 无同一组件重叠。
- [ ] `curl -k https://<VIP>:8443/healthz` 与本机 `:5443` 行为符合 INFRA-01。
- [ ] 停主节点后 VIP 漂移，无双主 HAProxy。

## 6. 相关

- [certificate-rotation.md](./certificate-rotation.md)（两种模式下证书路径相同，重启方式不同）
- [ha-control-plane-test-plan.md](../audits/ha-control-plane-test-plan.md)
- [MAINTENANCE.md](../MAINTENANCE.md)
