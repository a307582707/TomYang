# Task 54 — 许可证与第三方来源审计

**不擅自选择许可证。** 本文件仅列风险供维护者决定。

## 仓库许可证

| 项 | 状态 |
|----|------|
| 根目录 `LICENSE` / `LICENSE.md` | **缺失** |
| `package` / chart 许可证文件 | 不适用（非应用包仓库） |

**建议（待维护者确认）：** 明确选用 OSI 许可或“仅内部教材、保留版权”声明；在未决定前对外 fork/再分发存在合规不确定性。

## 第三方 YAML / 镜像 / 教程来源（仓内线索）

| 类别 | 线索路径 | 风险 |
|------|----------|------|
| 旧 Ingress / Dashboard / metrics-server / Prometheus Operator 清单 | `k8s/ExtraAddons/**`、`k8s/archived/**` | 可能源自上游示例；需保留归属与许可证注意 |
| 镜像仓库 | `registry.cn-hangzhou.aliyuncs.com/google_containers`、`quay.io`、`docker.io`、`docker.elastic.co` | 镜像许可与分发条款各异；生产应钉扎并核验 |
| `pull.sh` | 根目录 | 同步外部镜像；注意目标仓库 ToS |
| Wiki 历史长文 | `企业级kubernetes搭建实战` 等 | 可能含外部教程改写；版权来源未在仓内声明 |
| Weave Scope | `k8s/archived/WeaveScope` | 上游停更；许可与安全双重风险 |
| cfssl CSR JSON | `k8s/pki/` | 一般为自建模板；仍建议声明归属 |

## 修改记录建议

- 在 `CHANGELOG.md` / 发布说明中记录引入第三方清单的批次
- 对明显拷贝的上游文件补充 `Origin:` 注释或 docs 引用（人工确认后）

## 回滚

仅文档；revert 即可。
