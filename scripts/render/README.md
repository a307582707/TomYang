# 配置渲染（Task 31）

## 用法

```bash
# 非敏感变量
export VARS_FILE=docs/placeholders/examples/vars.example.env
# 敏感变量仅环境注入（示例名，勿填真实生产值到 shell 历史以外的文件）
# export ENCRYPT_SECRET=...
# export HAPROXY_STATS_PASSWORD=...
bash scripts/render/render.sh
```

输出目录默认 `.rendered/`（已 gitignore）。**不会**写回 `k8s/` 或 `examples/` 模板。

## 检查

1. 未替换占位符 → 退出码 2  
2. YAML 可解析  
3. HAProxy / Keepalived 结构关键字  
4. 如有 Shell → `bash -n`

## 风险

- 简单字符串替换，不支持条件逻辑  
- Prometheus 规则中的 `{{ $labels }}` 不应放入 SRC_DIRS 默认路径（默认不含 prometheus rules）
