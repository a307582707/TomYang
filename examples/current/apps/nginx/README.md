# nginx — 现代工作负载示例（Task 59）

**范围:** 实验 / 沙箱集群。**不要**对生产集群执行本目录。

镜像钉扎为 `nginx:1.27.5@sha256:6784…`（禁止 `latest`）。更新 digest 见 `docs/audits/image-digest-pin-examples.md`。
标签 `app: nginx` 与 `examples/current/networkpolicy/20-allow-ingress-to-app.yml` 的 `APP_LABEL` 约定对齐。

## 部署

控制器安装与 TLS/E2E 见 [`examples/current/ingress/controller/E2E-NOTES.md`](../../ingress/controller/E2E-NOTES.md)。

```bash
# 先替换 Ingress 占位符 {{ INGRESS_CLASS_NAME }} / {{ NGINX_HOST }}
kubectl apply -k examples/current/apps/nginx/
```

## 验证

```bash
kubectl get deploy,svc,ingress -l app=nginx
kubectl rollout status deploy/nginx
kubectl get pods -l app=nginx -o wide
# 可选：端口转发后 curl
kubectl port-forward svc/nginx 8080:80
curl -sI http://127.0.0.1:8080/
```

## 删除

```bash
kubectl delete -k examples/current/apps/nginx/
```

## 说明

- API：`apps/v1` Deployment、`networking.k8s.io/v1` Ingress
- 含 `resources`、readiness/liveness、`runAsNonRoot` securityContext
- 官方 `nginx` 镜像默认监听 80；非 root 实验请挂自定义 conf 或改用 unprivileged 变体，探针端口名保持 `http`
- 历史对照（勿混用）：`k8s/apps/nginx/`（含 `extensions/v1beta1` Ingress）
