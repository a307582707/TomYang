# 平台化：从「提工单等三天」到 GitOps 自服务交付

> 题材类型：内部开发者平台 / 自服务  
> 适合标题：`我们把 K8s 交付做成产品：权限、配额、环境，一次申请自动落地`  
> 目标：展示你能「做系统」，而不只是写脚本给人跑

## 0. 前后对比

| 维度 | 人肉工单时代 | 自服务平台后 |
|------|--------------|--------------|
| 新建命名空间 + 权限 | 平均 2.1 天 | 8 分钟（含审批） |
| 标准服务首次上线 | 1~3 天 | 0.5 天（模板生成） |
| 平台组每周重复操作 | ~35 次 | ~4 次（例外） |
| 误配导致的事故 | 月均 2~3 | 90 天内 0 |

核心思想：**把平台当产品**——有用户、有 SLA、有版本、有审计。

---

## 1. 典型用户故事（写 Wiki 要用「人话」）

> 业务研发小王要上线 `invoice` 服务：  
> 需要命名空间、镜像拉取密钥、CPU 配额、Ingress 域名、日志采集、告警人。  
> 以前：提 4 张工单，找 3 个组，口头对齐环境变量。  
> 现在：在平台勾选「标准 Web 服务」模板，填服务名与 Git 仓库，等审批通过后自动出齐。

---

## 2. 平台架构（逻辑视图）

```text
Developer Portal (UI/CLI)
        │
        ▼
  Control API（鉴权 / 校验 / 配额）
        │
        ├─ 写入 Git（期望状态）  ──► GitOps Controller ──► 集群
        ├─ 写审计日志
        └─ 发通知（飞书/邮件）
```

关键设计决策：

1. **平台不直连 kubectl apply 到生产**（紧急例外通道单独审计）。  
2. 所有期望状态进 Git：可评审、可回滚、可追责。  
3. 集群内只跑「调谐器」，人为操作会被漂移检测刷回。

---

## 3. 领域模型（这是「大牛感」来源）

不要只写「我们做了个前端」。把对象讲清楚：

| 对象 | 含义 | 例子 |
|------|------|------|
| Tenant | 成本与权限边界 | 事业部 / 团队 |
| Project | 一组服务 | `billing` |
| Environment | prod/stage/dev | 网络与密钥隔离 |
| WorkloadTemplate | 服务骨架 | Web / Worker / Cron |
| QuotaGrant | 资源授权 | cpu=40, mem=80Gi |
| Binding | 人/服务账号到角色 | SRE-admin, dev-edit |

### API 草图（细节到位）

```http
POST /api/v1/projects
{
  "name": "invoice",
  "tenant": "finance",
  "template": "web-standard",
  "git_repo": "https://git.example.com/finance/invoice.git",
  "owners": ["wang@example.com"]
}
```

校验逻辑：

1. 调用者是否属于 tenant  
2. 配额是否足够（不足则拒绝并返回可申请额度）  
3. 服务名是否符合 DNS1123 / 全局唯一  
4. 生成 PR 到 `platform-state` 仓库，而不是直接落地  

---

## 4. 权限与配额（最容易体现专业度）

### 4.1 RBAC 映射

| 平台角色 | 集群角色 | 能做什么 |
|----------|----------|----------|
| Developer | namespace edit（受限） | 改 Deployment/Config，不能改 NetworkPolicy |
| Ops | namespace admin | 含 Job、探针、HPA |
| Platform Admin | cluster 限定资源 | CRD/节点池，需双人审批 |

禁止：给业务 `cluster-admin`「图省事」。

### 4.2 配额发放

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-invoice
  namespace: invoice-prod
spec:
  hard:
    requests.cpu: "40"
    requests.memory: 80Gi
    pods: "200"
    persistentvolumeclaims: "20"
```

平台规则：

- 默认授予「最小可上线」额度  
- 超额走审批流，自动附最近 14 天利用率（防止拍脑袋要 200 核）

---

## 5. 模板产物示例（用户点一下会得到什么）

GitOps 目录生成：

```text
tenants/finance/invoice/
  prod/
    namespace.yaml
    resourcequota.yaml
    networkpolicy.yaml
    rbac.yaml
    app/
      deployment.yaml
      service.yaml
      httproute.yaml
      servicemonitor.yaml
```

`deployment.yaml` 预置：

- 安全上下文（非 root、只读根文件系统）  
- 资源 Request 占位（强制后续校准）  
- 就绪/存活探针  
- 日志标签与 metrics 端口  

这比「发一份部署文档」强在：**默认安全与默认可观测**。

---

## 6. 漂移与例外通道

| 场景 | 做法 |
|------|------|
| 研发在集群手改副本 | 调谐器 3 分钟内刷回；飞书通知 Owner |
| Sev-1 紧急扩容 | `/breakglass` 命令，有效期 2 小时，事后强制补 Git |
| 平台故障 | 只读模式；状态仓库仍可用手动 PR |

文章金句：

> 自服务不是取消管控，是把管控写成 API。

---

## 7. 度量平台是否成功（产品指标）

- **自服务率**：不经平台工单完成的变更占比（目标 > 85%）  
- **Lead time**：从创建项目到首个生产 deployment  
- **变更失败率** / 回滚率  
- **平台周活跃团队数**  
- **例外通道使用次数**（过高说明产品不好用）

---

## 8. 落地路线（避免一上来做大而全）

1. **MVP**：只做「建 ns + 配额 + 基础 RBAC」  
2. **V1**：标准 Web 模板 + GitOps  
3. **V2**：域名 / 证书 / 告警订阅  
4. **V3**：成本展示与配额建议  

每个阶段都要有真实用户试用，而不是平台自嗨。
