# TomYang

上海海曦技术 · Kubernetes 自建集群清单与运维实践记录。

本仓库保存自建（非 kubeadm）Kubernetes 控制面与插件的原始清单，配套文档发布在
[项目 Wiki](https://github.com/a307582707/TomYang/wiki)。

> **定位：** 历史教材清单（`k8s/`）与现代示例基线（`examples/current/`）**并存**；操作步骤以 Wiki 为准，审计与台账在本仓库 `docs/`。

## 导航总览

| 读者目标 | 入口 | 说明 |
|----------|------|------|
| 搭建 / 排障步骤 | [Wiki · INFRA-01](https://github.com/a307582707/TomYang/wiki/INFRA-01-本仓HA控制面与节点接入) | VIP、端口、证书与节点接入的权威正文 |
| 事故 / 发布 / 安全 | [Wiki · 运维与平台工程](https://github.com/a307582707/TomYang/wiki#运维与平台工程) | SRE、架构决策、智算交付等长文 |
| 现代清单骨架 | [`examples/current/README.md`](examples/current/README.md) | `apps/v1`、Ingress v1、PSA、可观测性示例 |
| 审计与验收 | [`docs/audits/README.md`](docs/audits/README.md) | 安全 / 兼容 / 可观测性报告索引 |
| Runbook | [`docs/runbooks/`](docs/runbooks/) | 证书轮换、etcd 备份、控制面部署模式 |
| 组件台账 | [`docs/MAINTENANCE.md`](docs/MAINTENANCE.md) | 版本、风险、复查日期 |
| Wiki 首页 | [TomYang Wiki](https://github.com/a307582707/TomYang/wiki) | 全部 INFRA / SRE / AIDC 长文 |

## 禁止直接 apply

以下路径**不得**作为推荐安装入口或一键 `kubectl apply` 目标：

| 路径 | 原因 |
|------|------|
| `k8s/archived/**` | 高风险历史反例（Dashboard 匿名 RBAC、EFK privileged、旧 metrics-server 等） |
| `k8s/ExtraAddons/efk/`、`dashboard/`、`WeaveScope/` | 已迁至 `k8s/archived/`；旧路径仅跳转 |
| `k8s/addons/metrics-server/`、`Kubedns/`、`kube-dns/` | 已归档或 stub；现网用 [`examples/current/observability/metrics-server-skeleton.yml`](examples/current/observability/metrics-server-skeleton.yml) 或发行版清单 |
| 任何恢复 `anonymous-proxy-rbac` / 匿名 `cluster-admin` 的清单 | 安全回归 |

新集群请优先阅读 [INFRA-01](https://github.com/a307582707/TomYang/wiki/INFRA-01-本仓HA控制面与节点接入) 与 [`examples/current/`](examples/current/README.md)。

## 目录结构

| 路径 | 内容 | 可否直接 apply |
|------|------|----------------|
| `k8s/pki/` | cfssl 证书请求模板 | 否（需替换占位符、离线签发） |
| `k8s/master/` | 控制面静态 Pod、systemd、HAProxy/Keepalived | 否（教材参考；版本 EOL） |
| `k8s/node/` | worker kubelet 配置 | 否 |
| `k8s/addons/` | CNI、CoreDNS、kube-proxy | 否（历史版本；对照 Wiki） |
| `k8s/ExtraAddons/` | 旧 Prometheus Operator、Ingress 等 | 否（部分已归档） |
| `k8s/archived/` | **禁止部署**清单 | **禁止** |
| `k8s/apps/` | 历史示例应用 | 否 |
| `examples/current/` | 现代 Kubernetes 示例基线 | 可改后试用（占位符必换） |
| `docs/audits/` | 审计报告 | — |
| `docs/runbooks/` | 运维 Runbook | — |
| `wiki/` | Wiki 同步跟踪（非第二套正文） | — |
| `pull.sh` | 国内镜像源同步脚本 | — |
| `vsphere.sh` | vSphere 磁盘辅助 | — |

## 使用说明

清单中的占位符（如 `{{ VIP }}`、`{{ etcd_servers }}`、`{TOKEN_ID}`）需按实际环境替换后再应用。

搭建顺序、证书签发与验收命令见
[本仓 HA 控制面与节点接入](https://github.com/a307582707/TomYang/wiki/INFRA-01-本仓HA控制面与节点接入)。

## 版本说明

清单基于早期版本编写（apiserver `v1.11.1`、etcd `v3.3.9`、Calico `v3.1`），保留为自建流程与参数组织方式的**历史教材**。
用于新集群时需要按目标版本核对镜像标签、API 版本与已废弃参数；**本仓库 release 不等于生产就绪部署**。

## 许可证

**尚未选定正式许可证。** 候选方案与利弊见 [docs/audits/license-candidates.md](docs/audits/license-candidates.md)；来源审计见 [docs/audits/license-and-provenance.md](docs/audits/license-and-provenance.md)。

在维护者确认并添加根目录 `LICENSE` 之前：

- 请勿假设本仓可按某一 OSI 许可再分发
- 第三方 YAML / 镜像仍须遵守其各自上游许可与保留义务

## 维护与事实源

- 组件台账与复查：[docs/MAINTENANCE.md](docs/MAINTENANCE.md)
- 单一事实源速查：[docs/SSOT.md](docs/SSOT.md)
- 变更记录：[CHANGELOG.md](CHANGELOG.md)
