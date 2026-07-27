# kube-scheduler / controller-manager 指标 Endpoints 示例

`kube-*-prometheus-discovery` Service **没有 selector**，必须另建 Endpoints。

可复制 [endpoints.example.yml](endpoints.example.yml)，把 `203.0.113.10` 换成真实控制面节点 IP 后再 apply。

注意：静态 Pod 若将 scheduler/controller-manager 绑定在 `127.0.0.1`，则节点外 Prometheus 无法抓取，需改 listen 地址或使用 node 本地采集。完整限制见仓库 `docs/audits/observability-completeness.md`。