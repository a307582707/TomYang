# Task 1 — Kubernetes 清单正确性审计报告

**分支:** `audit/k8s-correctness`  
**范围:** `k8s/**/*.yml|yaml`、`k8s/**/*.service`、相关 shell  
**方法:** 人工对照 + PyYAML `safe_load_all`（100/100 通过）+ `bash -n` / `git diff --check`

## 已修复（低风险、可确定）

| 问题 | 文件 | 修复 |
|------|------|------|
| apiserver 探针端口与 `--secure-port` 不一致 | `k8s/master/manifests/kube-apiserver.yml` | probe `6443` → `5443` |
| etcd 配置路径与静态 Pod/仓库文件名不一致 | `k8s/master/systemd/etcd.service` | `etcd.config.yml` → `config.yml` |
| scheduler kubeconfig 文件名不一致 | `k8s/master/systemd/kube-scheduler.service` | `scheduler.kubeconfig` → `scheduler.conf` |
| controller-manager kubeconfig 文件名不一致 | `k8s/master/systemd/kube-controller-manager.service` | `controller-manager.kubeconfig` → `controller-manager.conf` |
| CoreDNS ServiceMonitor 端口名不匹配 | `servicemonitor/coredns-sm.yml` + `addons/coredns/coredns.yml` | SM 使用 `metrics`；Service 增加 `9153/metrics` |
| 缺失 Namespace | ingress / efk / external-dns | 新增各自 `namespace.yml` |
| nginx Deployment 缺少 selector / 旧 API | `k8s/apps/nginx/nginx-dp.yml` | `apps/v1` + `selector` + 固定镜像标签 |
| 未加引号的 `{{ }}` 导致 YAML 无法解析 | keepalived、encryption、ingress/external-dns VIP | 改为带引号字符串 |
| HAProxy stats 明文账密 + 空 backend | `haproxy.cfg` | stats 改为占位符；补充注释示例 `server` 行 |

## 仅记录、未改（需运维上下文）

1. **双轨部署:** systemd apiserver 仍为 `--secure-port=6443`，静态 Pod 为 `5443`（HAProxy VIP:8443 → 后端 5443）。同一节点勿双开。
2. **Keepalived 两套设计:** 静态 Pod 用 `CHECK_PORT=2379`；宿主机 `check_haproxy.sh` 探测 `VIP:8443`。
3. **仓库文件名 vs 运行时路径:** `encryption/config.yml` → `/etc/kubernetes/encryption.yml`；`audit/policy.yml` → `audit-policy.yml`（需拷贝时改名）。
4. **目录拼写:** `ExtraAddons/prometheus/alertmanater/`（历史目录名，重命名会破坏引用，留给后续任务）。
5. **无 selector 的 discovery Service:** kube-scheduler / controller-manager 的 Service 依赖手工 Endpoints。
6. **内置 apiserver ServiceMonitor:** 依赖集群 `default/kubernetes` Service，仓库内无对应清单。

## 检查结果

- [x] PyYAML 解析 `k8s` 下 YAML：100 通过，0 失败  
- [x] `bash -n` keepalived check 脚本  
- [x] `git diff --check` 无行尾空白错误  

## 风险说明

- 探针端口修复后，若有人误用 systemd 6443 模式并仍挂载该静态 Pod 清单，行为会与预期不符——以 INFRA-01 静态 Pod + VIP:8443 为准。
- HAProxy `server` 行仍为注释示例，部署前必须按节点 IP 填写，否则 VIP 健康检查会失败。

## 未解决事项

- alertmanater 目录重命名  
- systemd 与静态 Pod 双轨文档化/收敛（见 Task 6/9）  
- discovery Service 的 Endpoints 样例  
- 现代 API / EOL 镜像（见 Task 2）  

## 回滚方法

```bash
git checkout master
git branch -D audit/k8s-correctness   # 本地
# 或关闭本 PR 且不合并
```
