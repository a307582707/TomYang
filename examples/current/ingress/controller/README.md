# Ingress NGINX 控制器 — 最小安装说明

**实验 / 沙箱 only。** 生产请走变更流程与私有 chart 仓库。

## 前提

- Kubernetes ≥ 1.25，已启用 `networking.k8s.io/v1`
- 已阅读 [ADR-001-ingress-nginx.md](./ADR-001-ingress-nginx.md)（**勿**使用 0.17.0 教材清单）

## 安装（Helm 示例）

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.ingressClassResource.name=nginx \
  --set controller.ingressClassResource.enabled=true \
  --set controller.ingressClass=nginx \
  --set controller.service.type=LoadBalancer
```

按现网调整：`LoadBalancer` / `NodePort`、资源限制、PodSecurity、内部 LB 注解等。

## 验证控制器

```bash
kubectl -n ingress-nginx get deploy,svc
kubectl get ingressclass
# 期望存在 IngressClass nginx（名称与 {{ INGRESS_CLASS_NAME }} 一致）
```

## 本目录清单

| 文件 | 说明 |
|------|------|
| `ingressclass-nginx.yml` | 可选：显式 `IngressClass`（Helm 通常已创建） |
| `tls-secret-placeholder.yml` | TLS Secret 占位符骨架 |
| `reference-ingress-v1.yml` | `networking.k8s.io/v1` 最小样例 |
| [E2E-NOTES.md](./E2E-NOTES.md) | 与 `apps/nginx` 的联调步骤 |

## TLS

1. 渲染或创建 `kubernetes.io/tls` Secret（见 `tls-secret-placeholder.yml`）。
2. 在 Ingress `spec.tls` 引用 Secret 名（nginx 示例见 `apps/nginx` 扩展说明）。

## 删除（Lab）

```bash
helm uninstall ingress-nginx -n ingress-nginx
```
