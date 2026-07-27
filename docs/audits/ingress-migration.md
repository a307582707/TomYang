# Task 41 — Ingress API 迁移对照（extensions/v1beta1 → networking.k8s.io/v1）

**对照对象:**

| 角色 | 路径 |
|------|------|
| 历史教材 | [`k8s/apps/nginx/nginx-ing.yml`](../../k8s/apps/nginx/nginx-ing.yml) |
| 现代示例 | [`examples/current/ingress/demo-web-ingress.yml`](../../examples/current/ingress/demo-web-ingress.yml) |
| 目录说明 | [`examples/current/ingress/README.md`](../../examples/current/ingress/README.md) |

**背景:** `extensions/v1beta1` Ingress 在 Kubernetes 1.22 起已移除；兼容性矩阵见 [`k8s-compatibility-matrix.md`](./k8s-compatibility-matrix.md)。

## 1. API 组与必填字段对照

| 项 | `extensions/v1beta1`（`nginx-ing.yml`） | `networking.k8s.io/v1`（`demo-web-ingress.yml`） |
|----|----------------------------------------|--------------------------------------------------|
| `apiVersion` | `extensions/v1beta1` | `networking.k8s.io/v1` |
| `kind` | `Ingress` | `Ingress` |
| 后端引用 | `backend.serviceName` / `servicePort` | `backend.service.name` / `backend.service.port.name` 或 `.number` |
| `pathType` | 无（隐式） | **必填**：`Exact` / `Prefix` / `ImplementationSpecific` |
| `ingressClassName` | 常靠注解 `kubernetes.io/ingress.class` | **推荐字段** `spec.ingressClassName` |
| TLS | `spec.tls[]`（字段名相近） | 同结构；证书 Secret 名现网定义 |
| 默认后端 | `spec.backend` | `spec.defaultBackend` |

## 2. 本仓文件逐项差异

### 历史：`k8s/apps/nginx/nginx-ing.yml`

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: nginx-ingress
spec:
  rules:
  - host: nginx.k8s.local
    http:
      paths:
      - backend:
          serviceName: nginx
          servicePort: 80
```

要点：

- 无 `path` / `pathType`（旧行为依赖控制器默认）。
- 无 `ingressClassName`；若环境有多控制器，行为依赖注解或默认类（现网定义）。
- 后端 Service 名 `nginx` 对应 [`k8s/apps/nginx/nginx-svc.yml`](../../k8s/apps/nginx/nginx-svc.yml)。
- 在 ≥1.22 集群上 **无法直接 apply**。

### 现代：`examples/current/ingress/demo-web-ingress.yml`

- `ingressClassName: "{{ INGRESS_CLASS_NAME }}"`（示例注释提到可按现网改为如 `nginx`）。
- `path: /` + `pathType: Prefix`。
- 后端 `service.name: demo-web`，`port.name: http`（与 [`examples/current/apps/demo-web.yml`](../../examples/current/apps/demo-web.yml) 一致）。
- 注解示例：`nginx.ingress.kubernetes.io/ssl-redirect: "true"` — **勿照搬** 仓内旧 Ingress NGINX `0.17.0`（`k8s/ExtraAddons/ingress-controller/`）时代注解全集；按现网控制器文档核对。

## 3. pathType

| 值 | 含义 | 迁移建议 |
|----|------|----------|
| `Prefix` | 前缀匹配（常见站点根路径 `/`） | 多数从旧 Ingress 迁出时的默认选择 |
| `Exact` | 精确路径 | 原依赖精确匹配时使用 |
| `ImplementationSpecific` | 控制器自定义 | 仅当现网控制器文档要求 |

旧清单缺 path 时，迁移应显式写出 `path` + `pathType`，并在沙箱用 HTTP 用例验证。

## 4. ingressClassName 与注解

| 机制 | 说明 |
|------|------|
| `spec.ingressClassName` | v1 推荐；对应集群中 `IngressClass` 资源 |
| `kubernetes.io/ingress.class` | 遗留注解；新清单优先字段，避免双写冲突 |
| 控制器专用注解 | 重写、亲和、超时等；以**现网控制器版本**为准，不从本教材仓抄生产值 |

仓内旧控制器清单：`k8s/ExtraAddons/ingress-controller/`（版本旧，仅对照）。

## 5. TLS

两 API 均使用大致如下结构（Secret 名 / hosts **现网定义**，本文不填生产证书）：

```yaml
spec:
  tls:
  - hosts:
    - "{{ INGRESS_TLS_HOST }}"
    secretName: "{{ INGRESS_TLS_SECRET }}"
```

迁移检查：

- Secret 位于 Ingress 同命名空间。
- 控制器能否读取 Secret（RBAC / 命名空间）。
- 是否仍需要 `ssl-redirect` 等注解（视控制器）。

历史 `nginx-ing.yml` **未**声明 TLS；现代示例亦未强制 TLS 段，按现网需要追加。

## 6. 迁移步骤（文档级，非自动执行）

1. 在实验集群确认 `networking.k8s.io/v1` 与目标 `IngressClass` 存在。
2. 以 `demo-web-ingress.yml` 为模板改写每条旧 Ingress（含 `k8s/ExtraAddons/prometheus/grafana/grafana-ing.yml`、`prometheus/prometheus-ing.yml` 等历史件）。
3. 补齐 `path` / `pathType` / `ingressClassName`。
4. 对照 Service 端口名或端口号。
5. 沙箱验证 HTTP(S) 后再计划现网变更；**不要**对生产批量 apply 本审计文档中的示例。

## 7. 验收

- [ ] 仓库内目标清单不再依赖 `extensions/v1beta1` Ingress（新集群路径）
- [ ] 现代示例与 `examples/current/apps/` 标签、端口名一致
- [ ] 注解与控制器版本匹配（现网定义）
