# Task 53 — 文档质量检查说明

- 脚本：`scripts/check-doc-quality.sh`（默认告警；`DOC_QUALITY_STRICT=1` 失败）
- **自动修复仅限格式**（本任务未批量改写正文）；技术内容需人工确认
- 检查项：多 H1、代码块语言、裸 URL（启发式）

## 风险
启发式误报（表格中的 URL 等）。

## 回滚
移除脚本调用或 revert。
