# kube-scheduler / controller-manager 指标 Endpoints 示例

`kube-service-discovery/*-svc.yml` 中的 Service **没有 selector**，需要按节点 IP 创建 Endpoints。
将 `NODE_IP` 换成实际控制面节点地址后再应用。

```yaml
apiVersion: v1
kind: Endpoints
metadata:
  name: kube-scheduler-prometheus-discovery
  namespace: kube-system
subsets:
- addresses:
  - ip: NODE_IP
  ports:
  - name: http-metrics
    port: 10251
    protocol: TCP
---
apiVersion: v1
kind: Endpoints
metadata:
  name: kube-controller-manager-prometheus-discovery
  namespace: kube-system
subsets:
- addresses:
  - ip: NODE_IP
  ports:
  - name: http-metrics
    port: 10252
    protocol: TCP
```

注意：静态 Pod 若将 scheduler/controller-manager 绑定在 `127.0.0.1`，则节点外 Prometheus 无法抓取，需改 listen 地址或使用 node 本地采集。
