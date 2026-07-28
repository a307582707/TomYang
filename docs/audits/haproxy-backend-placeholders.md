# Task 76 — HAProxy backend server 占位符

## 变更

`k8s/master/etc/haproxy/haproxy.cfg` 的 `backend k8s-api` 现含：

```
server master1 {{ MASTER1_IP }}:5443 check
server master2 {{ MASTER2_IP }}:5443 check
server master3 {{ MASTER3_IP }}:5443 check
```

## Master 数量

| 场景 | 要求 |
|------|------|
| 本仓 HA 教材默认 | **至少 3** 个 master（奇数，与 etcd 仲裁一致） |
| 单节点 lab | 可仅保留 `master1` 一行；注释或删除 2/3（渲染后本地改，勿提交真实 IP） |

拓扑：Client → Keepalived VIP **:8443** → HAProxy → apiserver **:5443**（Wiki **INFRA-01**）。

## Wiki INFRA-01 应对齐文案（维护者同步 Wiki）

- backend 须填写各 master 管理网 IP（占位符 `MASTER{1,2,3}_IP`），端口 **5443**
- 禁止把生产 IP 写回 Git 模板
- 渲染：`docs/placeholders/examples/vars.example.env` + `scripts/render/`

## 验证

- 渲染后 HAProxy 配置含 3 条 `server`；`curl -k https://<VIP>:8443/healthz`（lab）

## 回滚

- revert 本变更；恢复仅注释示例的旧 backend
