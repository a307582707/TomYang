# E2E — Ingress NGINX + nginx 应用

链路：**控制器（本目录）** → **示例应用** [`examples/current/apps/nginx/`](../../apps/nginx/README.md)

## 1. 安装控制器

见 [README.md](./README.md) Helm 步骤。确认：

```bash
kubectl get ingressclass nginx
kubectl -n ingress-nginx get pods
```

## 2. 部署 nginx 示例

```bash
# 替换 apps/nginx/ingress.yml 中占位符：
#   {{ INGRESS_CLASS_NAME }}=nginx
#   {{ NGINX_HOST }}=nginx.lab.example（解析到 LB / NodePort / hosts）
kubectl apply -k examples/current/apps/nginx/
kubectl rollout status deploy/nginx
```

## 3. （可选）TLS

```bash
# 方式 A：kubectl（Lab 自签）
openssl req -x509 -nodes -days 1 -newkey rsa:2048 \
  -keyout /tmp/tls.key -out /tmp/tls.crt -subj '/CN=nginx.lab.example'
kubectl create secret tls nginx-tls --cert=/tmp/tls.crt --key=/tmp/tls.key

# 方式 B：渲染 tls-secret-placeholder.yml 后 apply
```

在 `examples/current/apps/nginx/ingress.yml` 增加：

```yaml
spec:
  tls:
  - hosts:
    - nginx.lab.example
    secretName: nginx-tls
```

重新 `kubectl apply -k examples/current/apps/nginx/`。

## 4. 验证

```bash
kubectl get ingress nginx
# ADDRESS 列出现 LB IP 或 NodePort 入口后：
curl -sI -H 'Host: nginx.lab.example' "http://${INGRESS_IP}/"
# TLS：
curl -skI -H 'Host: nginx.lab.example' "https://${INGRESS_IP}/"
```

## 5. NetworkPolicy（可选）

若启用 `examples/current/networkpolicy/`，将 `APP_LABEL=nginx` 与 Ingress 控制器命名空间标签对齐后再测（见 `20-allow-ingress-to-app.yml`）。

## 6. 清理

```bash
kubectl delete -k examples/current/apps/nginx/
helm uninstall ingress-nginx -n ingress-nginx
```

## 勿用

- `k8s/ExtraAddons/ingress-controller/ingress-controller.yml`（0.17.0 / 旧 API）
