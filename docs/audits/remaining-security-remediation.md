# Task 64 — 剩余安全整改方案

**原则:** 默认 **不** 修改 `k8s/` 历史清单语义；现网用并行清单 / 发行版 Chart。下列每项含风险、前置、步骤、验证、回滚。

---

## 1. metrics-server insecure kubelet 抓取

**现状:** `k8s/archived/metrics-server/*` 含 `insecureSkipTLSVerify: true` 与 `--deprecated-kubelet-completely-insecure`。

| | |
|--|--|
| **风险** | 任意可打到 kubelet 端口的客户端可伪造/窃听 metrics；与已关闭的 `readOnlyPort: 0` 也不兼容旧抓取方式 |
| **前置** | 现网 metrics-server 版本；kubelet 客户端证书或 ServiceAccount 鉴权；聚合 API 可用 |
| **步骤** | 1) 勿 apply 归档清单 2) 安装现网 metrics-server 3) 配置 kubelet 鉴权抓取与 CA 4) 去掉一切 insecure / skip-verify 长期例外 |
| **验证** | `kubectl top nodes/pods`；metrics-server 日志无 TLS 跳过；参数中无 `deprecated-kubelet-completely-insecure` |
| **回滚** | 回退到上一版 metrics-server Release；**不要**回滚到归档 insecure 清单 |

---

## 2. kubelet TLS / 认证硬化

**现状:** 教材已将 `readOnlyPort: 0`、匿名认证关闭；仍需确认现网 webhook 鉴权与证书轮换。

| | |
|--|--|
| **风险** | 弱 TLS、过期证书或误开 10255 → 节点信息泄露 |
| **前置** | 节点可滚动；PKI 流程见 `docs/audits/pki-lifecycle-audit.md`；与 metrics-server/控制面抓取协调 |
| **步骤** | 1) 确认 `authentication.anonymous.enabled: false`、`authorization.mode: Webhook` 2) `readOnlyPort: 0` 3) 旋转 kubelet 服务证书 4) 限制 10250 仅控制面/监控网段 |
| **验证** | 匿名访问 10250/10255 失败；`kubectl logs/exec` 仍正常；证书 `notAfter` 在窗口内 |
| **回滚** | 恢复上一份 kubelet 配置 drop-in；证书用上一版本密钥对（短窗口） |

**默认不改** `k8s/*/etc/kubelet/` 历史文件以外的“再关端口”类重复编辑；现网用 `examples/current/runtime/kubelet-config.snippet.yml` 对齐。

---

## 3. HAProxy stats 端口 8006

**现状:** 控制面 HAProxy 暴露 stats；口令已改为占位符，端口仍可能对宽网段开放。

| | |
|--|--|
| **风险** | Stats 面信息泄露；弱口令或占位符未替换时被滥用 |
| **前置** | 管理网 / 安全组变更窗口；知晓 VIP 与 health check 依赖 |
| **步骤** | 1) stats `bind` 改管理网地址或 Unix socket（按发行版能力）2) 防火墙仅放行跳板 3) 确认 `{{ HAPROXY_STATS_* }}` 已注入强口令 4) 禁用或限制 CSV 导出 |
| **验证** | 业务 VIP `:8443` 健康检查仍绿；非管理网访问 `:8006` 超时；管理网可认证访问 |
| **回滚** | 恢复原 `bind` 与安全组；保留强口令 |

**默认不改** 历史 `haproxy.cfg` 端口号教材值；现网变更单改运行副本。

---

## 4. Grafana Secret 注入

**现状:** Secret 已改为 `stringData` 占位符；Git 历史仍可能含旧样例口令。

| | |
|--|--|
| **风险** | 清单明文/历史泄露；占位符未渲染即 apply |
| **前置** | SealedSecrets / ExternalSecrets / CI 注入；禁止本地提交真口令 |
| **步骤** | 1) 现网用外部注入创建 Secret 2) Deployment 仅 `secretKeyRef` 3) 轮换曾出现在 Git 的样例口令 4) `GF_AUTH_ANONYMOUS_ENABLED=false` |
| **验证** | 无匿名登录；管理员口令非仓库历史样例；Secret 不在 Git |
| **回滚** | 恢复上一 Secret 版本（集群内）；清单保持占位符 |

参考：`examples/current/security/secret-injection-note.md`。

---

## 5. node-exporter `hostPID` / `hostNetwork`

**现状:** `k8s/ExtraAddons/prometheus/node-exporter/node-exporter-ds.yml`。

| | |
|--|--|
| **风险** | 容器可见主机 PID/网络命名空间，扩大逃逸后侦察面 |
| **前置** | 现网是否依赖 hostNetwork 抓取；kube-rbac-proxy 与 NetworkPolicy |
| **步骤** | 1) 评估改为非 hostNetwork + 节点代理端口 2) 能关则关 `hostPID` 3) 用现网 chart 的安全模式 4) **不**直接改历史 ExtraAddons 当生产 |
| **验证** | 目标指标仍在；Pod 安全上下文无多余 host*；PSA 不报警 |
| **回滚** | 恢复上一 DaemonSet；临时允许 host* 并记例外单 |

---

## 6. Elasticsearch privileged init

**现状:** `k8s/archived/efk/elasticsearch-sts.yml` init `privileged: true`（常为 sysctl）。

| | |
|--|--|
| **风险** | 特权 init 逃逸；归档栈 EOL |
| **前置** | 现网日志方案已替代 EFK 归档 |
| **步骤** | 1) 保持归档、禁止 apply 2) 现网 ES/OpenSearch 用节点级 sysctl 或安全等价 3) 删除 privileged init |
| **验证** | 新栈无 privileged init；归档目录 README 仍禁部署 |
| **回滚** | N/A（不应恢复 privileged 归档到生产） |

---

## 7. Weave Scope `docker.sock`

**现状:** `k8s/archived/WeaveScope/scope.yml` 挂载 docker.sock + privileged。

| | |
|--|--|
| **风险** | 等同节点 root；容器逃逸 |
| **前置** | 无业务依赖 Scope |
| **步骤** | 1) 禁止部署 2) 审计集群是否仍有 Scope 3) 需要拓扑时用无 docker.sock 的现网方案 4) 保持归档反例 |
| **验证** | 无 `weaveworks/scope` Pod；无 docker.sock hostPath |
| **回滚** | 不允许为“方便排障”而回滚挂载 |

---

## 8. Git 历史样例密码

**现状:** 早期提交中 Grafana `r00tme`、HAProxy `admin:admin` 等可能仍可从历史取回（工作区已改占位符）。

| | |
|--|--|
| **风险** | 凭据视为已公开；若生产曾复用则持续有效 |
| **前置** | 确认现网从未使用样例口令，或已轮换；变更窗口 |
| **步骤** | 1) 轮换一切曾与样例相同的口令 2) 扫描现网 Secret 3) 可选：`git filter-repo` / BFG 清洗（另立专项，需协调 fork 与 force-push 政策）4) 文档声明样例已泄露 |
| **验证** | 现网登录旧样例失败；监控无用旧口令成功审计事件 |
| **回滚** | 历史清洗不可轻易回滚；以口令轮换为主 |

---

## 执行优先级（建议）

1. 确认归档 metrics-server / Weave / EFK **未**在现网运行
2. Grafana / HAProxy 口令轮换与 8006 网络收敛
3. 现网 metrics-server + kubelet TLS
4. node-exporter 收敛 host*
5. Git 历史清洗（专项）

## 回滚总则

文档与现网并行变更可逆；**不要**为图省事把 insecure / privileged / docker.sock 历史清单重新 apply。
