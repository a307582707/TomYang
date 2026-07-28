# HAProxy stats 面加固（Task 79）

控制面模板 `k8s/master/etc/haproxy/haproxy.cfg` 中 stats 默认 `bind *:8006` 便于实验室阅读，**现网须收敛监听面与凭据**。历史模板可保留占位符；运行副本按本文加固。

## 目标

| 项 | 建议 |
|----|------|
| 监听 | 仅管理网 IP / 内网接口，**勿** `bind *:8006` 对公网 |
| 凭据 | `{{ HAPROXY_STATS_USER }}` / `{{ HAPROXY_STATS_PASSWORD }}` 经环境变量渲染，禁止默认弱口令 |
| 访问面 | 防火墙 / 安全组 + HAProxy ACL 双重限制 |
| 业务 | VIP `:8443` → apiserver 健康检查不受影响 |

## 1. 凭据注入（渲染前 export）

```bash
export HAPROXY_STATS_USER="stats-operator"
export HAPROXY_STATS_PASSWORD="REPLACE_WITH_STRONG_SECRET"
bash scripts/render/render.sh
# 输出在 .rendered/k8s/master/etc/haproxy/haproxy.cfg — 勿回写 Git 模板
```

占位符见 `docs/placeholders/CATALOG.md`；`externalsecret-skeleton.yml` 含 HAProxy stats 虚构键名示例。

**禁止**在仓库或文档中写入历史默认口令（如 `admin` 与 `admin` 拼接形式）；仅使用上述占位符或外置 Secret。

## 2. stats `bind` 仅管理网

将 `listen stats` 段改为管理网地址（示例占位，非真实生产 IP）：

```haproxy
listen stats
  bind {{ HAPROXY_STATS_BIND }}:8006
  mode    http
  stats   enable
  stats   hide-version
  stats   uri       /stats
  stats   refresh   30s
  stats   realm     Haproxy\ Statistics
  stats   auth      {{ HAPROXY_STATS_USER }}:{{ HAPROXY_STATS_PASSWORD }}
  # 可选：限制 URI 与 HTTP 方法
  acl     valid_path path_beg /stats
  http-request deny unless valid_path
```

- `{{ HAPROXY_STATS_BIND }}`：例 `10.0.0.5`（管理网卡）或 `127.0.0.1`（仅本机 + SSH 隧道）。
- 若 HAProxy 跑在 `hostNetwork` Pod 内，`bind` 应对应节点管理 IP，而非 `0.0.0.0`。

可选：按发行版能力改用 Unix socket + 本地 `socat`/SSH 转发，完全关闭 TCP `:8006`。

## 3. 防火墙 / 安全组示例

**firewalld（管理网段示例 `10.0.0.0/24`）：**

```bash
# 默认拒绝 8006，仅放行管理网
sudo firewall-cmd --permanent --remove-port=8006/tcp 2>/dev/null || true
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="{{ HAPROXY_MGMT_CIDR }}" port port="8006" protocol="tcp" accept'
sudo firewall-cmd --reload
```

**iptables（片段）：**

```bash
iptables -A INPUT -p tcp --dport 8006 -s {{ HAPROXY_MGMT_CIDR }} -j ACCEPT
iptables -A INPUT -p tcp --dport 8006 -j DROP
```

**nftables（片段）：**

```nft
tcp dport 8006 ip saddr {{ HAPROXY_MGMT_CIDR }} accept
tcp dport 8006 drop
```

云安全组：入站仅允许跳板机 / 运维网段访问 TCP 8006；业务网段与 `0.0.0.0/0` 拒绝。

## 4. 验证步骤（关闭 / 限制 8006）

在**非管理网**客户端（应失败）：

```bash
curl -sS -o /dev/null -w "%{http_code}" --connect-timeout 3 http://<VIP_OR_NODE>:8006/stats
# 期望：超时、连接拒绝或非 200/401
```

在**管理网**或经 SSH 隧道（应成功且需认证）：

```bash
curl -sS -u "${HAPROXY_STATS_USER}:${HAPROXY_STATS_PASSWORD}" \
  "http://{{ HAPROXY_STATS_BIND }}:8006/stats;csv" | head -3
# 期望：401 无凭据；200 有凭据且为 CSV/HTML stats
```

确认业务面未受影响：

```bash
curl -k -sS -o /dev/null -w "%{http_code}" "https://<VIP>:8443/healthz"
# 期望：200 或集群定义的 health 响应
```

端口扫描（实验环境）：

```bash
nc -zv <node-management-ip> 8006   # 管理网：open
nc -zv <node-business-ip> 8006     # 业务网：closed / filtered
```

## 5. 与历史模板的关系

- **Git 模板** `k8s/master/etc/haproxy/haproxy.cfg` 可继续用 `{{ HAPROXY_STATS_* }}` 占位；本文件描述**部署后**运行副本加固，不要求在本 PR 中改历史 bind 默认值（见 `docs/audits/remaining-security-remediation.md` §3）。
- 渲染脚本：`scripts/render/render.sh` 已列出 `HAPROXY_STATS_USER` / `HAPROXY_STATS_PASSWORD`。

## 6. 回滚

1. 恢复 stats `bind *:8006` 的备份配置并重载 HAProxy。
2. 撤销防火墙 rich-rule / iptables 规则。
3. 凭据轮换若已执行，在 Secret 管理器中回滚上一版本。

## 参考

- `docs/audits/remaining-security-remediation.md` — §3 HAProxy stats
- `docs/audits/haproxy-backend-placeholders.md` — VIP / backend 拓扑
- `examples/current/security/secret-injection-note.md`
