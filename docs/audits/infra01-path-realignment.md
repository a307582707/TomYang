# Task 67 — Wiki INFRA-01 / 可观测性页路径对齐清单

**目的:** 目录重命名后，Wiki 操作页与仓库路径保持一致。
**权威:** 实际 Wiki 正文改动在 `TomYang.wiki` 仓库完成；本文为本仓对照清单。
**状态:** checklist（仓库侧）；Wiki 本地草稿已在 `/tmp/TomYang.wiki` 预改 INFRA-01 / 05 / 02（**未 push**，由父流程推送）。

## 1. 已落地的仓库路径（以 tip 为准）

| 主题 | 旧路径 / 旧名 | 现行路径 | 备注 |
|------|---------------|----------|------|
| Metrics Server | `k8s/addons/metric-server/`、`addons/metrics-server` 可 apply | stub：`k8s/addons/metrics-server/README.md` → **`k8s/archived/metrics-server/`** | 禁止部署；见 `ARCHIVED.md` |
| Alertmanager 目录 | `k8s/ExtraAddons/prometheus/alertmanater/` | **`k8s/ExtraAddons/prometheus/alertmanager/`** | 组件名 Alertmanager |
| kube-dns | `k8s/addons/Kubedns/` | stub / 归档：`k8s/addons/kube-dns/`、`k8s/archived/kube-dns/` | 新集群用 CoreDNS |
| Bootstrap Secret 文件 | `bootstrap-token-Secret.yml` | **`k8s/master/resources/bootstrap-token-secret.yml`** | 全小写 |
| CM CSR | `manager-csr.json`（映射名） | **`k8s/pki/controller-manager-csr.json`** | INFRA-01 签发列表应对齐 |
| 归档总则 | （分散 README） | **`k8s/archived/ARCHIVED.md`** | 隔离检查依赖此文件 |
| 占位符目录 | （散落文档） | **`docs/placeholders/`**（`CATALOG.md` / `catalog.json`） | 勿提交真实值 |
| 渲染入口 | 手工 sed | **`scripts/render/render.sh`** + `scripts/render/README.md` | 输出默认 `.rendered/` |
| HAProxy 配置 | 后端 server 常空 | **`k8s/master/etc/haproxy/haproxy.cfg`** | `backend k8s-api` 需补各 master `:5443` |

## 2. Wiki 页应对齐项（勾选）

### 2.1 [INFRA-01](https://github.com/a307582707/TomYang/wiki/INFRA-01-本仓HA控制面与节点接入)

- [x] 占位符表：`bootstrap-token-secret.yml`（非 `Secret` 大写）— 本地 wiki 已改
- [x] §4 `kubectl apply` 文件名与上一致 — 本地 wiki 已改
- [x] 签发列表：写明 `controller-manager-csr.json` — 本地 wiki 已改
- [x] §3.3 HAProxy：**前端 `:8443` → 后端各 apiserver `:5443`**；backend 补齐说明 — 本地 wiki 已改
- [x] 增加占位符 / 渲染入口：`docs/placeholders/`、`scripts/render/` — 本地 wiki 已改
- [x] addons 段注明 metrics-server / kube-dns 已归档 — 本地 wiki 已改
- [ ] **父流程 push** `TomYang.wiki` 后复核 GitHub 渲染链接

### 2.2 [05-可观测性…](https://github.com/a307582707/TomYang/wiki/05-可观测性与运维：Metrics-日志-监控)

- [x] Metrics Server → `k8s/archived/metrics-server/` + `ARCHIVED.md`（页面原已正确）
- [x] Prometheus 子目录表：`alertmanager/`（纠正 `alertmanater/`）— 本地 wiki 已改
- [x] EFK / 现代基线路径 — 原已正确；补 ESO 示例链 — 本地 wiki 已改
- [ ] **父流程 push** 后复核

### 2.3 [01-控制面…](https://github.com/a307582707/TomYang/wiki/01-控制面高可用架构与启动流程)

- [x] 端口拓扑仍为 VIP `:8443` → apiserver `:5443`（抽查无需改）
- [x] `etc/haproxy` / `etc/keepalived` / `manifests` 路径抽查（无需改）
- [x] 重申勿双跑 systemd + 静态 Pod（原文已有）

### 2.4 [02-证书…](https://github.com/a307582707/TomYang/wiki/02-证书、鉴权与审计策略)

- [x] `controller-manager-csr.json` 对齐 — 本地 wiki 已改
- [x] 链到 `docs/runbooks/certificate-rotation.md` — 本地 wiki 已改
- [ ] **父流程 push** 后复核

### 2.5 历史长文（低优先级）

- [ ] `企业级kubernetes搭建实战(二).md` 等归档页内 `metric-server` / `Kubedns` / `bootstrap-token-Secret`：**可不改正文**（教材归档）；顶部过时横幅已足够
- [ ] 操作入口页（INFRA-01 / 05）**必须**正确

## 3. HAProxy backend 备注（Wiki 应写清）

```text
VIP:8443  (HAProxy frontend k8s-api)
    →  master-N:5443  (kube-apiserver --secure-port=5443)
```

- 模板 `haproxy.cfg` 中 `backend k8s-api` 的 `server` 行为占位，部署前按节点补齐。
- stats 监听 `:8006`，账密为 `{{ HAPROXY_STATS_USER }}` / `{{ HAPROXY_STATS_PASSWORD }}`（见占位符目录）；限制管理网。
- Keepalived 探测：`check_haproxy.sh` → `https://VIP:8443/`。

## 4. 占位符 / render 入口（Wiki 建议链）

| 用途 | 仓库路径 |
|------|----------|
| 人类可读目录 | `docs/placeholders/CATALOG.md` |
| 机器可读 | `docs/placeholders/catalog.json` |
| 非敏感示例 env | `docs/placeholders/examples/vars.example.env` |
| 渲染脚本 | `scripts/render/render.sh` |

## 5. 验证

1. 打开 INFRA-01 / 05，逐条点击 GitHub tree/blob 链接，确认 404 为零（操作页）。
2. 本仓：`bash scripts/check-repo-path-refs.sh`（若已覆盖 Wiki 跟踪文件则另议）。
3. 勿在本仓 `wiki/` 目录维护第二套正文（见 `docs/MAINTENANCE.md` / `docs/SSOT.md`）。

## 6. 回滚

- Wiki：revert 对应 commit 或检出 `backup/wiki-master-20260727` 后再 cherry-pick 正确路径提交。
- 本清单：文档-only，关闭 PR 即可。
