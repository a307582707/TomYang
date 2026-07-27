# apps — 工作负载基线

使用 `apps/v1` Deployment + ClusterIP Service。镜像标签为占位或固定小版本，部署前钉扎 digest。

| 路径 | 说明 |
|------|------|
| `demo-web.yml` | 占位镜像 demo；标签 `app: demo-web` |
| `demo/` | 入口说明（指向 demo-web 与 nginx） |
| `nginx/` | 完整示例：Deployment / Service / Ingress / kustomization；`nginx:1.27.5`；标签 `app: nginx` |

与 `examples/current/networkpolicy/20-allow-ingress-to-app.yml`：将 `{{ APP_LABEL }}` 设为对应 `app` 值。
