# 旧 metrics-server（历史归档）

> **禁止 apply / 禁止生产部署。** 统一说明见 [`../ARCHIVED.md`](../ARCHIVED.md)。

## 为何禁止

| 风险 | 说明 |
|------|------|
| 不安全 kubelet 抓取 | 含 `--deprecated-kubelet-completely-insecure` |
| TLS 跳过 | `insecureSkipTLSVerify: true` |
| 过时 API | `extensions/v1beta1`、`apiregistration.k8s.io/v1beta1` |
| 不可信镜像 | 个人转储 Registry（见 `docs/audits/image-supply-chain.md`） |

**不得** `kubectl apply -f k8s/archived/metrics-server/`；不得写入安装脚本、Wiki 默认步骤或 CI 推荐路径。

## 现代替代

现网与实验环境请使用 **kubelet TLS 鉴权抓取** 的现行 metrics-server：

| 入口 | 路径 |
|------|------|
| 推荐 skeleton | [`examples/current/observability/metrics-server-skeleton.yml`](https://github.com/a307582707/TomYang/blob/master/examples/current/observability/metrics-server-skeleton.yml) |
| 目录说明 | [`examples/current/observability/README.md`](https://github.com/a307582707/TomYang/blob/master/examples/current/observability/README.md) |
| 占位符 | `{{ METRICS_SERVER_IMAGE }}` — `docs/placeholders/CATALOG.md` |

## 验收（现网）

- [ ] 集群 **未** 运行本目录清单
- [ ] `kubectl top nodes/pods` 可用
- [ ] metrics-server 参数中 **无** `deprecated-kubelet-completely-insecure`
- [ ] 与 `readOnlyPort: 0` kubelet 硬化一致

## 参考

- [`docs/audits/remaining-security-remediation.md`](../../docs/audits/remaining-security-remediation.md) §1
- [`docs/audits/quarterly-review-2026-Q3.md`](../../docs/audits/quarterly-review-2026-Q3.md)
- [`examples/current/security/README.md`](../../examples/current/security/README.md)

## 回滚

若误 apply 归档清单：删除对应 Deployment/APIService，改部署 `metrics-server-skeleton.yml`（或发行版 Helm）；**不要**以 insecure 参数作为回滚目标。
