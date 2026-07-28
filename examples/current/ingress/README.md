# ingress — 路由基线

使用 `networking.k8s.io/v1`。需要集群已安装 IngressClass（示例名 `nginx`，按现网修改）。

现代 **Ingress NGINX** 控制器安装、ADR 与 E2E 见 [`controller/`](controller/README.md)（**勿**使用 `k8s/ExtraAddons/ingress-controller/` 0.17.0 清单）。
