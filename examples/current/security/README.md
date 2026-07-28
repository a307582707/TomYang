# security — 安全基线

## 硬性禁止

- 恢复或新建 `anonymous-proxy` / `system:anonymous` → Dashboard（或任意）高权绑定
- ServiceAccount 直接绑 `cluster-admin`（除非破例变更单）
- 将 `k8s/archived/**` 纳入默认安装
- 在示例中写入真实口令、PAT 或私钥（含 `admin:admin`、历史 Grafana 样例）

## 示例

| 文件 | 说明 |
|------|------|
| `haproxy-stats-hardening.md` | stats 仅管理网 bind、防火墙 ACL、`{{ HAPROXY_STATS_* }}` 与 `:8006` 验证 |
| 归档 metrics-server | **禁止** apply `k8s/archived/metrics-server/`；见 [`../observability/metrics-server-skeleton.yml`](../observability/metrics-server-skeleton.yml) |
| `networkpolicy-default-deny-ingress.yml` | 命名空间级默认拒绝 Ingress |
| `psa-namespace-labels.yml` | Pod Security Admission 标签占位 |
| `secret-injection-note.md` | Secret 外置注入约定 |
| `externalsecret-skeleton.yml` | External Secrets 骨架：Grafana / Alertmanager / HAProxy stats 占位 |

部署前确认 CNI 支持 NetworkPolicy。更完整的策略见 `examples/current/networkpolicy/`。
应用标签与 netpol：`apps/nginx` 使用 `app: nginx`，对应 `20-allow-ingress-to-app.yml` 的 `APP_LABEL`。

## 密钥注入（fictional only）

生产密钥**不得**进入 Git。推荐用外部密钥系统注入，本目录仅提供骨架。

### 约定

1. 骨架中的 `SecretStore`/`ExternalSecret` 与 `{{ PLACEHOLDER }}` 均为**虚构**；`provider.fake` 仅便于阅读，现网应换成 Vault / 云 SM / 企业 KMS 等真实 provider。
2. Grafana：注入后的 Secret 再挂到 Deployment（`env` / `envFrom`），勿把明文写进镜像或清单。
3. Alertmanager：SMTP/webhook 类字段同样只引用 Secret；对照历史 `k8s/ExtraAddons/prometheus/alertmanager/` 时只学结构，换现行版本。
4. HAProxy stats：`{{ HAPROXY_STATS_USER }}` / `{{ HAPROXY_STATS_PASSWORD }}` 见 `docs/placeholders/`；可用渲染脚本 `scripts/render/render.sh` 从**环境变量**注入到 `.rendered/`，不要回写仓库模板。
5. 若组织标准为 Sealed Secrets 而非 ESO：可按同等键名自建 `SealedSecret`，仍禁止提交未加密明文。

### 检查

- 仓级：`bash scripts/check-secrets.sh`
- 危险模式：`bash scripts/check-dangerous-patterns.sh`
