# Task 61 — 镜像供应链盘点（Inventory only）

**范围:** `k8s/` 与 `examples/` 中显式 `image:` 行（含归档）。**不**改清单、**不**拉镜像。
**说明:** Prometheus / Alertmanager Operator CR 使用 `baseImage` + `version`（非 `image:`），单列于表末。

扫描日期: 2026-07-27。EOL 为相对现网时间的**粗判**（教材版本普遍过旧）。

## 总表

| 路径 | Registry | 组件 | Tag | EOL / 过旧风险 | Floating (`latest`) | 个人/非官方 Registry | 迁移方向 | Digest / 签名建议 |
|------|----------|------|-----|----------------|---------------------|----------------------|----------|-------------------|
| `k8s/master/manifests/kube-apiserver.yml` | `registry.cn-hangzhou.aliyuncs.com` | kube-apiserver-amd64 | v1.11.1 | **高**（1.11 EOL） | 否 | 云镜像加速（非个人） | 现网发行版控制面镜像 + 私有仓库 | 钉 digest；cosign/notation 验签 |
| `k8s/master/manifests/kube-controller-manager.yml` | 同上 | kube-controller-manager-amd64 | v1.11.1 | **高** | 否 | 同上 | 同上 | 同上 |
| `k8s/master/manifests/kube-scheduler.yml` | 同上 | kube-scheduler-amd64 | v1.11.1 | **高** | 否 | 同上 | 同上 | 同上 |
| `k8s/master/manifests/etcd.yml` | `quay.io` | coreos/etcd | v3.3.9 | **高** | 否 | 否 | 与 K8s 匹配的 etcd 3.5.x；官方或私有仓库 | 钉 digest |
| `k8s/master/manifests/haproxy.yml` | Docker Hub（隐式） | kairen/haproxy | 1.7 | **高**；个人维护镜像 | 否 | **是**（`kairen/`） | 官方 `haproxy` 固定小版本或自建 | 迁出个人仓后钉 digest |
| `k8s/master/manifests/keepalived.yml` | Docker Hub | zhangguanzhang/keepalived | 1.3.9 | **高**；个人镜像 | 否 | **是**（`zhangguanzhang/`） | 自建 keepalived 或发行版包 | 迁出个人仓 |
| `k8s/addons/kube-proxy/kube-proxy.yml` | `registry.cn-hangzhou.aliyuncs.com` | kube-proxy-amd64 | v1.11.3 | **高** | 否 | 云加速 | 与 apiserver 同小版本 | 钉 digest |
| `k8s/addons/coredns/coredns.yml` | Docker Hub | coredns/coredns | 1.2.0 | **高** | 否 | 否 | 现网 CoreDNS（如 1.11+） | 钉 digest |
| `k8s/addons/flannel/kube-flannel.yml` | `quay.io` | coreos/flannel | v0.10.0-amd64 | **高** | 否 | 否 | 现网 CNI 选型（见 ADR）；勿混用 | 钉 digest |
| `k8s/addons/calico/v3.1/calico.yml` | `quay.io` | calico/typha | v0.7.4 | **高** | 否 | 否 | Calico 现网 LTS | 钉 digest |
| 同上 | `quay.io` | calico/node | v3.1.3 | **高** | 否 | 否 | 同上 | 同上 |
| 同上 | `quay.io` | calico/cni | v3.1.3 | **高** | 否 | 否 | 同上 | 同上 |
| `k8s/addons/calico/v3.1/calicoctl.yml` | `quay.io` | calico/ctl | v3.1.3 | **高** | 否 | 否 | 与 node 同版本 calicoctl | 钉 digest |
| `k8s/ExtraAddons/ingress-controller/ingress-controller.yml` | `registry.cn-hangzhou.aliyuncs.com` | defaultbackend | 1.4 | **高** | 否 | 云加速 | 现网 ingress-nginx 配套 | 钉 digest |
| 同上 | `quay.io` | kubernetes-ingress-controller/nginx-ingress-controller | 0.17.0 | **高**（0.17 极旧） | 否 | 否 | 现网 ingress-nginx 控制器 | 钉 digest + 签名 |
| `k8s/ExtraAddons/external-dns/external-dns/external-dns.yml` | `registry.opensource.zalan.do` | teapot/external-dns | v0.5.4 | **高** | 否 | 否 | 现网 external-dns 发行版 | 钉 digest |
| `k8s/ExtraAddons/external-dns/coredns/coredns-dp.yml` | Docker Hub | coredns/coredns | 1.1.4 | **高** | 否 | 否 | 与主 CoreDNS 策略统一 | 钉 digest |
| `k8s/ExtraAddons/external-dns/coredns/etcd-dp.yml` | `quay.io` | coreos/etcd | v3.1.9 | **高** | 否 | 否 | 独立 etcd 现网版本或改存储 | 钉 digest |
| `k8s/ExtraAddons/prometheus/operator/operator.yml` | `quay.io` | coreos/prometheus-operator | v0.22.0 | **高** | 否 | 否 | kube-prometheus-stack / 现网 Operator | 钉 digest |
| `k8s/ExtraAddons/prometheus/grafana/grafana-dp.yml` | Docker Hub | grafana/grafana | 5.1.0 | **高** | 否 | 否 | Grafana 现网 LTS | 钉 digest |
| `k8s/ExtraAddons/prometheus/node-exporter/node-exporter-ds.yml` | `quay.io` | prometheus/node-exporter | v0.15.2 | **高** | 否 | 否 | 现网 node-exporter | 钉 digest |
| 同上 | `quay.io` | coreos/kube-rbac-proxy | v0.3.1 | **高** | 否 | 否 | 现网 kube-rbac-proxy | 钉 digest |
| `k8s/ExtraAddons/prometheus/kube-state-metrics/…` | `quay.io` | coreos/kube-rbac-proxy | v0.3.1 | **高** | 否 | 否 | 同上 | 钉 digest |
| 同上 | `quay.io` | coreos/kube-state-metrics | v1.3.1 | **高** | 否 | 否 | 现网 kube-state-metrics | 钉 digest |
| 同上 | `quay.io` | coreos/addon-resizer | 1.0 | **中高** | 否 | 否 | HPA/现网 resizer 或去掉 | 钉 digest |
| `k8s/apps/nginx/nginx-dp.yml` | Docker Hub | nginx | 1.27.5 | **低**（固定小版本） | 否 | 否 | 可保留；优先私有仓库同步 | **建议**钉 digest |
| `k8s/archived/metrics-server/metrics-server.yml` | Docker Hub | zhangguanzhang/gcr.io.google_containers.metrics-server-amd64 | v0.2.1 | **高**；个人转储 | 否 | **是** | **禁止部署**；用现网 metrics-server | 不迁移该镜像 |
| `k8s/archived/metrics-server/metrics-server-1.12+.yml` | 同上 | 同上 | v0.3.1 | **高** | 否 | **是** | 同上 | 同上 |
| `k8s/archived/kube-dns/kubedns.yml` | `registry.cn-hangzhou.aliyuncs.com` | k8s-dns-*-amd64 | 1.14.7 | **高**（kube-dns 退役） | 否 | 云加速 | CoreDNS | N/A（归档） |
| `k8s/archived/dashboard/kubernetes-dashboard.yml` | 同上 | kubernetes-dashboard-amd64 | v1.8.3 | **高** | 否 | 云加速 | 现网 Dashboard 或禁用 | N/A |
| `k8s/archived/efk/elasticsearch-sts.yml` | 同上 | elasticsearch | v6.2.5 | **高** | 否 | 云加速 | 现网日志栈；勿 apply 归档 | N/A |
| 同上（init） | Docker Hub | alpine | 3.6 | **高**（Alpine 3.6 EOL） | 否 | 否 | 去掉 privileged init / 现网镜像 | N/A |
| `k8s/archived/efk/kibana-dp.yml` | `docker.elastic.co` | kibana/kibana-oss | 6.2.4 | **高** | 否 | 否 | 现网 Kibana/替代 | N/A |
| `k8s/archived/efk/fluentd-es-ds.yml` | `registry.cn-hangzhou.aliyuncs.com` | fluentd-elasticsearch | v2.2.0 | **高** | 否 | 云加速 | fluent-bit / 现网采集 | N/A |
| `k8s/archived/WeaveScope/scope.yml` | `docker.io` | weaveworks/scope | 1.10.1 | **高**；挂 docker.sock | 否 | 否 | **禁止部署** | N/A |
| `examples/current/apps/nginx/deployment.yml` | Docker Hub | nginx | 1.27.5 | **低** | 否 | 否 | 私有仓库 + digest | 部署前钉 digest / 验签 |
| `examples/current/apps/demo-web.yml` | （占位） | `{{ DEMO_WEB_IMAGE }}` | — | 取决于替换值 | 若误填 `latest` 则高 | 取决于替换值 | 替换为批准镜像+digest | 强制 digest |

### Operator `baseImage` + `version`（非 `image:`）

| 路径 | baseImage | version | 风险 | 迁移 |
|------|-----------|---------|------|------|
| `k8s/ExtraAddons/prometheus/prometheus/prometheus-main.yml` | `quay.io/prometheus/prometheus` | v2.3.1 | **高** | 现网 Prometheus |
| `k8s/ExtraAddons/prometheus/alertmanager/alertmanager-main.yml` | `quay.io/prometheus/alertmanager` | v0.15.0 | **高** | 现网 Alertmanager |

## 汇总

| 发现 | 数量级 |
|------|--------|
| Floating tag `latest` | **0**（显式 `image:` 扫描） |
| 个人 / 转储类 Registry（`zhangguanzhang/`、`kairen/`） | 控制面 keepalived/haproxy + 归档 metrics-server |
| 教材 1.11 / 监控 2018 量级 | 绝大多数 `k8s/` 非 examples |
| 现代示例固定 tag | `examples/current/apps/nginx` → `nginx:1.27.5` |

## 建议（文档级，本任务不改清单）

1. 生产只消费私有仓库同步件；禁止直接依赖个人 Docker Hub 命名空间。
2. CI 拒绝 `image:.*:latest`（见 `scripts/check-modern-examples.sh`，仅 `examples/current`）。
3. 归档目录保持只读反例；迁移写在现网 Helm/Operator，而非回改历史 manifest。
4. 部署流水线：`crane digest` / cosign verify 后再写进清单。

## 回滚

文档-only；删除本文件即可。
