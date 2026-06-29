# AI 会话同步协议

> 适用对象：Claude Code、Codex、以及使用本仓库继续开发的其他 AI 助手。  
> 目标：让不同 AI 会话以相同进度继续开发，同时避免每次新开会话都重新阅读整个项目。

## 核心原则

- 不同步完整聊天记录，只同步项目级结论、下一步和验证状态。
- 共享状态必须短，可被人工当作项目日报阅读。
- 只记录当前有用的信息，不沉淀推理过程、废弃方案和长篇历史。
- 如果 `docs/handoff/ai-shared-state.md` 与 `docs/todo.md` 冲突，以 `docs/todo.md` 的未完成事项为准；如果与 `CLAUDE.md` 冲突，以 `CLAUDE.md` 的项目规则为准。

## 新会话启动流程

1. 先读 `docs/handoff/ai-shared-state.md`。
2. 再读 `docs/todo.md`，确认仍需人工或真实环境介入的事项。
3. 需要代码开发时，再读 `CLAUDE.md` 中的工程规则和相关源码。
4. 只在任务需要时搜索具体模块，避免为了“熟悉项目”全量扫描。

## 工作结束更新流程

每次完成阶段性工作后，AI 应自觉更新 `docs/handoff/ai-shared-state.md`：

- `当前阶段`：如果项目重心变化才更新。
- `当前结论`：只保留会影响后续行动的结论。
- `下一步`：写给下一位 AI 的最小行动清单。
- `最近日报`：追加当天 3 到 8 条短 bullet。
- `未决人工事项`：原则上只引用 `docs/todo.md`，不要复制完整清单。

## 写作格式

- 用中文维护。
- 每条 bullet 只表达一个结论或下一步。
- 不写“我觉得”“可能可以”等过程性文字；不确定的事项直接写“待确认”。
- 不记录完整命令输出，只记录关键验证命令和结果。
- 不记录密钥、Token、私人位置、未授权素材或用户敏感原文。

## Claude Code / Codex 约束建议

后续可在各工具的启动提示或项目规则中加入以下约束：

```md
新会话开始时，必须先阅读 `docs/handoff/ai-shared-state.md` 和 `docs/todo.md`，再决定是否需要读取 `CLAUDE.md` 或具体源码。

阶段性工作结束时，必须更新 `docs/handoff/ai-shared-state.md`，只记录当前结论、下一步和必要验证状态，不同步完整聊天记录。
```

## 升级路径

当前阶段先使用 Markdown 自觉维护。只有当多人/多 AI 高频并发导致状态冲突时，再考虑增加：

- `docs/handoff/ai-daily/YYYY-MM-DD.md`：按天拆分更长日报。
- `scripts/ai_context.ps1`：一键输出共享状态、todo 和 git 状态。
- 本地 MCP 状态服务：提供 `read_project_state`、`update_project_state`、`append_daily_note` 等工具。
