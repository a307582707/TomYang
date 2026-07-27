# Task 6 — Wiki 与仓库一致性检查

## 权威约定（与仓库清单一致）

| 项 | 约定 |
|----|------|
| 客户端入口 | Keepalived VIP **:8443** |
| apiserver | 静态 Pod **`--secure-port=5443`** |
| HAProxy | 前端 8443 → 后端各 master 5443 |
| etcd 配置 | `/etc/etcd/config.yml`（仓库 `k8s/master/etc/etcd/config.yml`） |
| CM/Scheduler kubeconfig | `controller-manager.conf` / `scheduler.conf` |
| 操作手册 | Wiki **INFRA-01** |

## 已消除的冲突

| 页面 | 原冲突 | 处置 |
|------|--------|------|
| `01-控制面高可用…` | 写 HAProxy/VIP/secure-port 均为 6443 | 改为 8443/5443，并声明 INFRA-01 权威 |
| `INFRA-01` | 权威性不够醒目 | 增加权威声明 |
| `02-证书…` | 缺运行时落盘改名说明 | 补充 encryption/audit 拷贝改名 |

## 仍存在于历史文、不在本任务改写正文

| 页面 | 冲突 | 处置 |
|------|------|------|
| `企业级kubernetes搭建实战(二)` | HAProxy 后端写 6443；etcd 用 `etcd.config.yml`；`*.kubeconfig` 命名 | Task 7 加归档横幅，指向 INFRA-01 |
| systemd 双轨 | 仓库仍保留部分 systemd 控制面 unit | Task 1/9；INFRA-01 已写勿双开 |

## 检查结果
- [x] 对照仓库 haproxy.cfg / apiserver.yml / etcd 路径 / kubeconfig 名
- [x] 更新 INFRA-01、01、02
- [x] Wiki 分支 `wiki/infra-consistency`

## 风险 / 回滚
仅文档；不合并 Wiki 分支即可回滚。
