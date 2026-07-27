# Task 69 — 危险模式静态检查

**脚本:** [`scripts/check-dangerous-patterns.sh`](../../scripts/check-dangerous-patterns.sh)
**接线:** 可选；由父流程加入 `scripts/run-static-checks.sh`（本文件不强制）。

## 扫描模式

| 模式 | 含义 |
|------|------|
| `system:anonymous` | 匿名主体高权绑定风险 |
| `cluster-admin`（Binding / roleRef） | SA/User 直接绑集群管理员 |
| `admin:admin` | 默认明文账密（如 HAProxy stats 历史值） |
| `docker.sock` | 容器逃逸面（Weave Scope 等） |
| `readOnlyPort: 10255` | kubelet 只读端口未关闭 |
| `deprecated-kubelet-completely-insecure` | metrics-server 跳过 kubelet 鉴权 |
| `privileged: true` | 特权容器（入口/示例禁止；归档除外；控制面/CNI 白名单另议于脚本） |

## 规则

1. **`k8s/archived/**`:** 若存在 `k8s/archived/ARCHIVED.md`，允许上述模式作为反例保留。
2. **推荐入口 / 现代示例:** `README.md`（安装相关）、`examples/current/**` 中的清单若出现上述模式 → **失败**（README 中「禁止 / 归档 / 反例」叙述性提及除外，脚本对入口以 YAML/配置为主、并对明显 apply 危险路径告警）。
3. **存活清单（非归档）:** 不得再引入 anonymous、`admin:admin`、`docker.sock`、`readOnlyPort: 10255`、`deprecated-kubelet-completely-insecure`；不得新增非白名单的 `privileged: true` / `cluster-admin` Binding。

## 本地运行

```bash
bash scripts/check-dangerous-patterns.sh
```

## 与隔离检查关系

- [`check-archived-isolation.sh`](../../scripts/check-archived-isolation.sh)：禁止把 archived 当作安装入口。
- 本检查：禁止危险模式回流到推荐路径与存活清单。

## 回滚

文档 + 脚本可选；从 `run-static-checks.sh` 去掉一行即可停用。
