# TomYang

上海海曦技术 · Kubernetes 自建集群清单与运维实践记录。

本仓库保存自建（非 kubeadm）Kubernetes 控制面与插件的原始清单，配套文档发布在
[项目 Wiki](https://github.com/a307582707/TomYang/wiki)。

## 文档入口

正文统一维护在 Wiki，本仓库不再保存长文副本：

- [Wiki 首页](https://github.com/a307582707/TomYang/wiki)
- [运维与平台工程](https://github.com/a307582707/TomYang/wiki#运维与平台工程)：事故复盘、架构决策、发布与安全
- [基础设施与本仓手册](https://github.com/a307582707/TomYang/wiki#基础设施与本仓手册)：对照本仓清单的搭建与排障步骤
- [智算与推理交付](https://github.com/a307582707/TomYang/wiki#智算与推理交付)：GPU 节点与推理服务运维

## 目录结构

| 路径 | 内容 |
|------|------|
| `k8s/pki/` | cfssl 证书请求模板（CA、apiserver、etcd、kubelet、kube-proxy 等） |
| `k8s/master/manifests/` | 控制面静态 Pod：etcd、apiserver、controller-manager、scheduler、haproxy、keepalived |
| `k8s/master/etc/` | etcd、HAProxy、Keepalived、kubelet 配置模板 |
| `k8s/master/systemd/` | 控制面 systemd 单元 |
| `k8s/master/resources/` | bootstrap token 与 kubelet / apiserver RBAC |
| `k8s/master/audit/`、`k8s/master/encryption/` | 审计策略与 Secret 静态加密配置 |
| `k8s/node/` | worker 节点 kubelet 配置与 systemd 单元 |
| `k8s/addons/` | CNI（Calico / Flannel）、CoreDNS、kube-proxy（metrics-server 已迁至归档） |
| `k8s/ExtraAddons/` | Prometheus 栈、Ingress、external-dns 等可选组件（Dashboard / EFK / WeaveScope 已迁至归档） |
| `k8s/archived/` | **禁止部署**的高风险历史清单（见该目录 `ARCHIVED.md`） |
| `k8s/apps/` | 示例应用清单（nginx Deployment / Service / Ingress） |
| `examples/current/` | 现代 Kubernetes 示例基线（不覆盖 `k8s/` 历史清单） |
| `pull.sh` | 通过国内镜像源同步 `gcr.io` / `k8s.gcr.io` / `quay.io` 镜像 |
| `vsphere.sh` | vSphere 侧磁盘处理辅助脚本 |

## 禁止直接部署

以下目录**不得**作为推荐安装入口或一键 apply 目标：

- `k8s/archived/**`（及旧路径跳转说明：`k8s/ExtraAddons/WeaveScope`、`dashboard`、`efk`，`k8s/addons/metrics-server`）
- 任何恢复 `anonymous-proxy-rbac` / 匿名 `cluster-admin` 的清单

新集群请优先阅读 Wiki [INFRA-01](https://github.com/a307582707/TomYang/wiki/INFRA-01-本仓HA控制面与节点接入) 与 `examples/current/`。

## 使用说明

清单中的占位符（如 `{{ VIP }}`、`{{ etcd_servers }}`、`{TOKEN_ID}`）需按实际环境替换后再应用。

搭建顺序、证书签发与验收命令见
[本仓 HA 控制面与节点接入](https://github.com/a307582707/TomYang/wiki/INFRA-01-本仓HA控制面与节点接入)。

## 版本说明

清单基于早期版本编写（apiserver `v1.11.1`、etcd `v3.3.9`、Calico `v3.1`），保留为自建流程与参数组织方式的参考。
用于新集群时需要按目标版本核对镜像标签、API 版本与已废弃参数，不建议直接照搬到生产环境。

## 许可证

**尚未选定正式许可证。** 候选方案与利弊见 [docs/audits/license-candidates.md](docs/audits/license-candidates.md)；来源审计见 [docs/audits/license-and-provenance.md](docs/audits/license-and-provenance.md)。

在维护者确认并添加根目录 `LICENSE` 之前：

- 请勿假设本仓可按某一 OSI 许可再分发
- 第三方 YAML / 镜像仍须遵守其各自上游许可与保留义务

## 维护与事实源

- 组件台账与复查：[docs/MAINTENANCE.md](docs/MAINTENANCE.md)
- 单一事实源速查：[docs/SSOT.md](docs/SSOT.md)
- 审计报告：[docs/audits/](docs/audits/)
