# 占位符目录（Task 30）

**规则:** 本目录只记录占位符元数据；**禁止**写入真实值。渲染见 `scripts/render/`。

| 占位符 | 格式 | 敏感 | 用途（推断） | 出现文件（节选） | 验证规则 |
|--------|------|------|--------------|------------------|----------|
| `{HOSTNAME}` | brace | 否 | 主机/网卡 | `k8s/master/etc/etcd/config.yml` | 非空字符串 |
| `{KUBE_APISERVER}` | brace | 否 | 配置注入 | `k8s/addons/kube-proxy/kube-proxy.yml` | 非空字符串 |
| `{PUBLIC_IP}` | brace | 否 | 配置注入 | `k8s/master/etc/etcd/config.yml` | 非空字符串 |
| `{TOKEN_ID}` | brace | 是 | 凭据（敏感） | `k8s/master/resources/bootstrap-token-Secret.yml` | 仅经环境变量注入；长度≥1；禁止提交 |
| `{TOKEN_SECRET}` | brace | 是 | 凭据（敏感） | `k8s/master/resources/bootstrap-token-Secret.yml` | 仅经环境变量注入；长度≥1；禁止提交 |
| `{{ ALERTMANAGER_ALERT_EMAIL }}` | mustache | 否 | 配置注入 | `k8s/ExtraAddons/prometheus/alertmanager/alertmanager-main-secret.yml` | 邮箱格式或占位符保留至渲染 |
| `{{ ALERTMANAGER_SLACK_API_URL }}` | mustache | 否 | 配置注入 | `k8s/ExtraAddons/prometheus/alertmanager/alertmanager-main-secret.yml` | 非空字符串 |
| `{{ ALERTMANAGER_SLACK_CHANNEL }}` | mustache | 否 | 配置注入 | `k8s/ExtraAddons/prometheus/alertmanager/alertmanager-main-secret.yml` | 非空字符串 |
| `{{ ALERTMANAGER_SMTP_FROM }}` | mustache | 否 | 配置注入 | `k8s/ExtraAddons/prometheus/alertmanager/alertmanager-main-secret.yml` | 非空字符串 |
| `{{ ALERTMANAGER_SMTP_PASSWORD }}` | mustache | 是 | 凭据（敏感） | `k8s/ExtraAddons/prometheus/alertmanager/alertmanager-main-secret.yml` | 仅经环境变量注入；长度≥1；禁止提交 |
| `{{ ALERTMANAGER_SMTP_SMARTHOST }}` | mustache | 否 | 主机/网卡 | `k8s/ExtraAddons/prometheus/alertmanager/alertmanager-main-secret.yml` | 非空字符串 |
| `{{ ALERTMANAGER_SMTP_USER }}` | mustache | 否 | 配置注入 | `k8s/ExtraAddons/prometheus/alertmanager/alertmanager-main-secret.yml` | 非空字符串 |
| `{{ DEMO_WEB_HOST }}` | mustache | 否 | 主机/网卡 | `examples/current/ingress/demo-web-ingress.yml` | 非空字符串 |
| `{{ DEMO_WEB_IMAGE }}` | mustache | 否 | 镜像引用 | `examples/current/apps/demo-web.yml` | 非空字符串 |
| `{{ ENCRYPT_SECRET }}` | mustache | 是 | 凭据（敏感） | `k8s/master/encryption/config.yml` | 仅经环境变量注入；长度≥1；禁止提交 |
| `{{ GRAFANA_ADMIN_PASSWORD }}` | mustache | 是 | 凭据（敏感） | `k8s/ExtraAddons/prometheus/grafana/grafana-admin-secret.yml` | 仅经环境变量注入；长度≥1；禁止提交 |
| `{{ GRAFANA_ADMIN_USER }}` | mustache | 否 | 配置注入 | `k8s/ExtraAddons/prometheus/grafana/grafana-admin-secret.yml` | 非空字符串 |
| `{{ HAPROXY_MGMT_CIDR }}` | mustache | 否 | 网段 | `examples/current/security/haproxy-stats-hardening.md` | CIDR；例 10.0.0.0/24 |
| `{{ HAPROXY_STATS_BIND }}` | mustache | 否 | 主机/网卡 | `examples/current/security/haproxy-stats-hardening.md` | 管理网 bind 地址；禁止真实生产 IP |
| `{{ HAPROXY_STATS_PASSWORD }}` | mustache | 是 | 凭据（敏感） | `k8s/master/etc/haproxy/haproxy.cfg`, `examples/current/security/haproxy-stats-hardening.md` | 仅经环境变量注入；长度≥1；禁止提交 |
| `{{ HAPROXY_STATS_USER }}` | mustache | 否 | 配置注入 | `k8s/master/etc/haproxy/haproxy.cfg`, `examples/current/security/haproxy-stats-hardening.md` | 非空字符串 |
| `{{ INGRESS_CLASS_NAME }}` | mustache | 否 | 配置注入 | `examples/current/ingress/demo-web-ingress.yml` | 非空字符串 |
| `{{ INGRESS_VIP }}` | mustache | 否 | VIP / 入口地址 | `k8s/ExtraAddons/external-dns/coredns/coredns-svc-tcp.yml`, `k8s/ExtraAddons/external-dns/coredns/coredns-svc-udp.yml`, `k8s/ExtraAddons/ingress-controller/ingress-controller-svc.yml` | 非空字符串 |
| `{{ MASTER1_IP }}` | mustache | 否 | 主机/网卡 | `k8s/master/etc/haproxy/haproxy.cfg` | IPv4或主机名；禁止提交真实生产地址 |
| `{{ MASTER2_IP }}` | mustache | 否 | 主机/网卡 | `k8s/master/etc/haproxy/haproxy.cfg` | IPv4或主机名；禁止提交真实生产地址 |
| `{{ MASTER3_IP }}` | mustache | 否 | 主机/网卡 | `k8s/master/etc/haproxy/haproxy.cfg` | IPv4或主机名；禁止提交真实生产地址 |
| `{{ PLACEHOLDER }}` | mustache | 否 | 配置注入 | `examples/current/README.md` | 非空字符串 |
| `{{ REGISTRY_MIRROR }}` | mustache | 否 | 配置注入 | `examples/current/runtime/containerd-config.toml.snippet` | 非空字符串 |
| `{{ TARGET_NAMESPACE }}` | mustache | 否 | Namespace 名 | `examples/current/security/networkpolicy-default-deny-ingress.yml` | 非空字符串 |
| `{{ VIP }}` | mustache | 否 | VIP / 入口地址 | `k8s/master/etc/keepalived/keepalived.conf`, `k8s/master/manifests/keepalived.yml`, `k8s/master/manifests/kube-apiserver.yml` 等 4 处 | 非空字符串 |
| `{{ container }}` | mustache | 否 | 配置注入 | `k8s/ExtraAddons/prometheus/grafana/grafana-dashboard-definitions.yml` | 非空字符串 |
| `{{ container_name }}` | mustache | 否 | 配置注入 | `k8s/ExtraAddons/prometheus/grafana/grafana-dashboard-definitions.yml` | 非空字符串 |
| `{{ container_runtime }}` | mustache | 否 | 配置注入 | `k8s/archived/efk/fluentd-es-cm.yml` | 非空字符串 |
| `{{ etcd_initial_cluster }}` | mustache | 否 | 配置注入 | `k8s/master/etc/etcd/config.yml` | 非空字符串 |
| `{{ etcd_servers }}` | mustache | 否 | 配置注入 | `k8s/master/manifests/kube-apiserver.yml`, `k8s/master/systemd/kube-apiserver.service` | 非空字符串 |
| `{{ interface }}` | mustache | 否 | 配置注入 | `k8s/addons/calico/v3.1/calico.yml`, `k8s/addons/flannel/kube-flannel.yml`, `k8s/master/etc/keepalived/keepalived.conf` 等 4 处 | 非空字符串 |
| `{{ labels.statefulset }}` | mustache | 否 | 配置注入 | `k8s/ExtraAddons/prometheus/prometheus/prometheus-rules.yml` | 非空字符串 |
| `{{ pod_name }}` | mustache | 否 | 配置注入 | `k8s/ExtraAddons/prometheus/grafana/grafana-dashboard-definitions.yml` | 非空字符串 |
| `{{Date}}` | mustache | 否 | 配置注入 | `k8s/archived/WeaveScope/scope.yml` | 非空字符串 |
| `{{K8SVersion}}` | mustache | 否 | 配置注入 | `k8s/archived/WeaveScope/scope.yml` | 非空字符串 |
| `{{KUBE_APISERVER}}` | mustache | 否 | 配置注入 | `k8s/addons/kube-proxy/kube-proxy.yml` | 非空字符串 |
| `{{container_name}}` | mustache | 否 | 配置注入 | `k8s/ExtraAddons/prometheus/grafana/grafana-dashboard-definitions.yml` | 非空字符串 |
| `{{cpu}}` | mustache | 否 | 配置注入 | `k8s/ExtraAddons/prometheus/grafana/grafana-dashboard-definitions.yml` | 非空字符串 |
| `{{device}}` | mustache | 否 | 配置注入 | `k8s/ExtraAddons/prometheus/grafana/grafana-dashboard-definitions.yml` | 非空字符串 |
| `{{namespace}}` | mustache | 否 | Namespace 名 | `k8s/ExtraAddons/prometheus/grafana/grafana-dashboard-definitions.yml` | 非空字符串 |
| `{{node}}` | mustache | 否 | 配置注入 | `k8s/ExtraAddons/prometheus/grafana/grafana-dashboard-definitions.yml` | 非空字符串 |
| `{{pod_name}}` | mustache | 否 | 配置注入 | `k8s/ExtraAddons/prometheus/grafana/grafana-dashboard-definitions.yml` | 非空字符串 |
