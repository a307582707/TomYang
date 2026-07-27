# demo — 演示应用入口

| 路径 | 说明 |
|------|------|
| [../demo-web.yml](../demo-web.yml) | 通用 demo-web Deployment+Service（占位镜像） |
| [../nginx/](../nginx/) | 完整 nginx 示例（kustomize；`app: nginx`） |

NetworkPolicy 对齐：将 `examples/current/networkpolicy/*.yml` 中
`{{ APP_LABEL }}` 设为 `demo-web` 或 `nginx`，`{{ APP_PORT }}` 与容器端口一致。
