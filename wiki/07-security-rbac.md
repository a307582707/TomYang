# 安全与权限：CI 日志泄漏 GitHub Token 的 45 分钟应急

> 题材类型：安全实战 / 密钥与 RBAC  
> 适合标题：`Token 进了 CI 日志之后：我们如何在 45 分钟内完成吊销、排查与止血`  
> 目标：展示应急节奏与权限设计，而不是背诵安全口号

## 0. 事件摘要

| 项 | 内容 |
|----|------|
| 发现 | 安全扫描告警：公开 CI artifact 含 `github_pat_***` |
| 影响面未知窗口 | 约 2 小时（从写入日志到发现） |
| 处置总时长 | 45 分钟到「吊销 + 轮换 + 流水线阻断」 |
| 结果 | 未发现仓库被恶意推送；2 个内部 Action 被未授权列出（只读） |

定性：**Sev-1 安全事件**（凭据暴露），虽未造成破坏，但按「已泄漏」处理。

---

## 1. 时间线

| 时间 | 动作 |
|------|------|
| 16:02 | 扫描器告警命中 PAT 模式 |
| 16:04 | 安全 oncall 确认：日志原文含完整 token |
| 16:06 | **立即吊销该 token**（先吊销，再分析） |
| 16:08 | 列出该 token 权限与最近访问 IP / API |
| 16:15 | 轮换所有可能同源凭据（GHCR、deploy key、bot 账号） |
| 16:20 | 关闭公开 artifact；CI 改为私有并清理历史 artifact |
| 16:28 | 审计 git push / workflow 变更 / repo settings |
| 16:40 | 临时禁用高危 workflow（`pull_request_target` 类） |
| 16:47 | 宣布「泄漏凭据失效」；进入根因与加固 |

原则：**假设攻击者已经拿到了。**

---

## 2. 根因

1. 某 Job 为了调试把 `env` 打印到日志：  
   ```bash
   printenv | sort   # 灾难写法
   ```  
2. Token 存在 `GITHUB_TOKEN` / 自定义 secret，被一起打出。  
3. Artifact 上传了 `build.log`，仓库 fork PR 场景下可见性被误配为 public。  

不是「黑客攻破」，是 **工程习惯 + 可见性配置** 组合拳。

---

## 3. 应急检查清单（可直接当 Runbook）

### 3.1 凭据

- [ ] 吊销暴露的 PAT / 云 AK / kubeconfig  
- [ ] 轮换派生密钥（镜像仓库、包仓库、Webhook secret）  
- [ ] 检查是否写入过外部系统（Terraform state、Bot 消息）

### 3.2 仓库与 CI

- [ ] 审计最近 push、collaborator、deploy key、webhook  
- [ ] 检查 Actions 运行记录异常  
- [ ] 清理日志与 artifact；必要时删除 workflow run  
- [ ] 暂停可疑 workflow

### 3.3 集群侧（若 token 能间接碰到部署）

- [ ] 检查异常 Deployment 镜像变更  
- [ ] 检查新建的 ClusterRoleBinding  
- [ ] 轮换用于 CD 的服务账号 kubeconfig

```bash
kubectl get clusterrolebinding -o wide
kubectl get deploy -A -o json | jq -r '.items[] | "\(.metadata.namespace)/\(.metadata.name) \(.spec.template.spec.containers[0].image)"' | sort
```

---

## 4. 加固：从「别再泄漏」到「泄漏也难利用」

### 4.1 CI 规范

```yaml
# 禁止
- name: debug
  run: printenv

# 允许的调试
- name: debug-safe
  run: echo "branch=$GITHUB_REF"
```

门禁：

- 日志脱敏 scanner（PAT/AK 模式匹配则 fail）  
- 禁止 `pull_request_target` + 检出 PR 代码的危险组合  
- secret 最小权限：构建用与部署用分离

### 4.2 GitHub / Git 权限

| 身份 | 权限 | 说明 |
|------|------|------|
| 个人 PAT | 禁用或极短有效期 | 改用 OIDC / 应用安装 token |
| CD Bot | 仅目标仓库 contents:write | 不能 org 级 admin |
| 只读 CI | contents:read + packages:read | 默认 |

### 4.3 集群 RBAC 反面典型

**错误**：给 CI 一个 `cluster-admin` kubeconfig 「什么都能部署」。  

**正确**：

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: cd-deployer
  namespace: billing-prod
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "patch", "update"]
- apiGroups: [""]
  resources: ["services", "configmaps"]
  verbs: ["get", "patch", "update"]
```

即使 CI token 泄漏，攻击面被关在一个命名空间的有限动词里。

---

## 5. 另一个短例：过度宽松的 RoleBinding

现象：实习同学账号能 `kubectl get secret -A`。  
根因：把人绑到了 `view` 的 ClusterRole，而某些发行版/自定义聚合角色把 secret 读权限塞进了 view。  

修复：

1. 自建 `RestrictedView`（无 secret）  
2. secret 访问走审批与审计  
3. 定期 `kubectl-who-can` / 权限扫描

---

## 6. 文章结构建议（发 Wiki 时）

1. 先写时间线与决策（先吊销）  
2. 再写根因（不耻笑个人，指向系统设计）  
3. 给出 Runbook 与 RBAC 代码  
4. 用指标收尾：泄漏发现 MTTD、凭据平均寿命、cluster-admin 绑定数  

金句：

> 安全事件里，最快的正确动作往往是「让钥匙失效」，  
> 不是「先写一份完美根因报告」。
