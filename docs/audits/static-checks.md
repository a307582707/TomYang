# Task 8 — 自动化静态检查

## 内容
- `scripts/run-static-checks.sh` 聚合：YAML/JSON 语法、Shell `bash -n` + ShellCheck、敏感信息、YAML 占位符可解析性、废弃 API 告警、Markdown 本地链接、行尾空白提示
- `scripts/test-static-checks.sh` + `scripts/testdata/**`：夹具测试（合法/非法 YAML、占位符、虚构 Token、私钥头、Markdown 链接、废弃 API、Shell 语法、正则自匹配）
- `.github/workflows/static-checks.yml`：PR/push 触发，**不**依赖集群或生产凭据
- `scripts/testdata` 故意含失败样例，**不**纳入生产扫描路径

## 检查结果（本地）
见 CI 与本地执行输出。

## 风险
- 历史清单含大量废弃 API：默认 **告警不失败**（`STRICT_DEPRECATED=1` 可转严格）
- ShellCheck 未安装时仅 `bash -n`

## 回滚
删除 workflow 与 scripts 检查脚本即可。
