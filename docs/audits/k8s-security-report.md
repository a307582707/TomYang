# Task 3 — 安全配置审计报告

**分支:** `audit/k8s-security`

## 已修复（确定性问题）

| 项 | 处置 |
|----|------|
| Dashboard 匿名代理 + SA `cluster-admin` | 删除 `ExtraAddons/dashboard/anonymous-proxy-rbac.yml`；增加 `dashboard/README.md` |
| HAProxy stats `admin:admin` | 改为 `{{ HAPROXY_STATS_USER }}:{{ HAPROXY_STATS_PASSWORD }}` |
| Grafana Secret 可逆 base64（`admin` / `r00tme`） | 改为 `stringData` 占位符 |
| Grafana `GF_AUTH_ANONYMOUS_ENABLED=true` | 改为 `false` |
| kubelet `readOnlyPort: 10255` | master/node 均改为 `0` |
| Weave Scope 危险能力 | 增加 `WeaveScope/README.md` 明确禁止安装（清单仍在，标为反例） |

## 检查结果摘要

| 类别 | 发现 | 处置 |
|------|------|------|
| Dashboard 匿名访问 | 是 | 已删绑定清单 |
| cluster-admin 过度授权 | Dashboard SA 绑定 | 随文件删除；Dashboard 本体仍过旧 |
| 默认用户名密码 | HAProxy / Grafana | 已改占位符 |
| Git 中 Secret | Grafana base64 | 已改占位符（**注意：历史提交仍含旧值，需轮换**） |
| 特权容器 | Calico/Flannel/kube-proxy/keepalived/ES/Weave | 记录；部分为 CNI/控制面必要 |
| hostPath / hostNetwork / hostPID | 控制面静态 Pod、CNI、node-exporter、Weave | 记录；控制面/CNI 预期存在 |
| Docker socket | Weave Scope | README 禁止使用 |
| TLS 校验跳过 | metrics-server `--deprecated-kubelet-completely-insecure` | 列入整改清单（改动影响采集，未在本 PR 强改） |
| kubelet 只读端口 | 10255 | 已关 |
| HAProxy stats | 明文账密 | 已改占位符；仍建议绑定管理网/ACL |

## 安全整改清单（未改）

1. **metrics-server** 去掉 insecure kubelet 抓取，改为正式 kubelet 鉴权（依赖较新 metrics-server）。  
2. **删除或移出** `WeaveScope/` 目录（本 PR 仅标注）。  
3. **删除/替换** 过旧 Dashboard Deployment，或提供最小权限 Role 示例。  
4. **历史 git 历史** 中 Grafana `r00tme` 仍可找回 → 视为已泄露样例，生产勿复用。  
5. 控制面 `hostNetwork`/`hostPath` 证书目录：保持但限制节点登录与文件权限（运维规程）。  
6. node-exporter `hostPID`/`hostNetwork`：评估是否改为更安全的采集方式。  
7. Elasticsearch `privileged: true`：评估是否可去除。  
8. HAProxy stats 端口 `8006`：建议仅监听内网或加防火墙。

## 风险说明

- 关闭 kubelet 只读端口后，依赖 `10255` 的旧 metrics-server 清单将无法工作（本就不应在现代环境使用）。  
- 删除匿名 Dashboard RBAC 后，若有文档仍引用该文件，需在 Wiki 归档任务中更新。

## 未解决事项

见上方整改清单 1–8；兼容性细节见 Task 2。

## 回滚方法

关闭本 PR；或 `git revert` 合并提交。恢复 `anonymous-proxy-rbac.yml` **不推荐**。

## Task 13 — 深度复核（2026-07-27）

| 检查项 | 结论 |
|--------|------|
| Dashboard 匿名代理权限 | **通过**：`anonymous-proxy-rbac.yml` 已删除；仓库内无 `system:anonymous` 绑定残留 |
| Dashboard `cluster-admin` | **通过**：随匿名代理清单删除；`kubernetes-dashboard.yml` 仅保留常规 RoleBinding，无 `cluster-admin` |
| Grafana Secret 部署注入 | **通过**：改为 `stringData` 占位符；部署前需替换，不可把占位符当密码 |
| Grafana 匿名登录 | **通过**：`GF_AUTH_ANONYMOUS_ENABLED=false` |
| HAProxy 默认凭据 | **通过（由 PR #4）**：master 已为 `{{ HAPROXY_STATS_* }}`；本 PR rebase 后不再重复改该文件 |
| kubelet `readOnlyPort` | **通过**：master/node 均为 `0`；匿名认证保持 `false` |
| 破坏 1.11 历史语义 | **可接受**：关闭 10255 / 删匿名 RBAC 是安全硬化，未改 apiserver `5443` 拓扑；kubelet 文件本身已是 `v1beta1` 形态 |
| README 历史 vs 生产 | **通过**：根 README 已声明早期版本参考；Dashboard/WeaveScope README 明确禁止生产使用 |

### 合并决定

**同意合并。** 剩余风险（metrics-server insecure、WeaveScope 目录仍在、Grafana 历史提交中的样例口令）已记入整改清单，不阻塞本 PR。
