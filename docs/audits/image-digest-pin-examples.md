# Task 85 — `examples/current` 镜像 tag+digest 钉扎

**范围:** 仅 `examples/current/`。**不**修改历史 `k8s/` 清单（见 `docs/audits/image-supply-chain.md`）。

## 已钉扎 / 示例引用

| 路径 | 镜像 | 形式 |
|------|------|------|
| `examples/current/apps/nginx/deployment.yml` | `nginx:1.27.5` | **tag@digest**（硬编码） |
| `examples/current/apps/nginx/kustomization.yml` | 同上 | `digest:` 字段 |
| `examples/current/observability/prometheus-skeleton.yml` | `prom/prometheus:v2.53.0` | 占位符 + 注释示例 |
| `examples/current/observability/grafana-skeleton.yml` | `grafana/grafana:11.0.0` | 占位符 + 注释示例 |
| `examples/current/apps/demo-web.yml` | `{{ DEMO_WEB_IMAGE }}` | 渲染示例见 `vars.example.env` |

### 当前 digest（2026-07-28 自 Docker Hub 拉取 manifest）

```
nginx:1.27.5@sha256:6784fb0834aa7dbbe12e3d7471e69c290df3e6ba810dc38b34ae33d3c1c05f7d
prom/prometheus:v2.53.0@sha256:075b1ba2c4ebb04bc3a6ab86c06ec8d8099f8fda1c96ef6d104d9bb1def1d8bc
grafana/grafana:11.0.0@sha256:0dc5a246ab16bb2c38a349fb588174e832b4c6c2db0981d0c3e6cd774ba66a54
```

## 如何获取 digest

```bash
# Docker Hub（需 token）
repo=library/nginx tag=1.27.5
scope="repository:${repo}:pull"
token=$(curl -s "https://auth.docker.io/token?service=registry.docker.io&scope=${scope}" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")
curl -sI -H "Authorization: Bearer $token" \
  -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' \
  "https://registry-1.docker.io/v2/${repo}/manifests/${tag}" \
  | rg -i docker-content-digest

# 或（本地已登录 registry 时）
crane digest nginx:1.27.5
skopeo inspect docker://nginx:1.27.5 --format '{{ .Digest }}'
```

私有仓库：对镜像同步后的内部 tag 执行同样步骤；**以私有仓 manifest 为准**。

## 更新流程（tag 重建 / digest 过期）

1. 在沙箱拉取候选 tag，跑 smoke test（启动 + 健康检查）。
2. 用上一节命令获取新 digest；更新 `deployment.yml` / `kustomization.yml` / `vars.example.env`。
3. 更新本文件「当前 digest」日期与哈希；PR 说明上游 CVE 或版本原因。
4. CI：`check-modern-examples.sh` 仍禁止 `:latest`；可选 cosign/notation 验签在部署流水线执行（见 `image-supply-chain.md`）。

**占位符清单：** 渲染前 `{{ PROMETHEUS_IMAGE }}` 等必须展开为 `repo:tag@sha256:…`；禁止仅 tag 无 digest 上生产。

## 回滚

恢复各文件中的 `image:` 为仅 tag 形式，并删除本文件即可；不影响 `k8s/`。
