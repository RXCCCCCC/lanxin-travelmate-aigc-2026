# Agent Run、Trace 与 Human-in-the-loop

## 目标

为每次 Agent 请求提供可关联、可恢复、用户隔离且隐私最小化的运行记录，支持面试时解释一次请求如何经过意图、节点、模型和工具，并演示记忆副作用的人工确认。

## 数据模型

`agent_runs` 由 Alembic revision `0009_agent_runs` 创建，主要字段：

- `run_id/request_id`：运行与请求关联标识；
- `user_id/session_id/trip_id`：用户和业务范围；
- `idempotency_key`：同一用户范围内复用 run；
- `status/intent`：运行状态与意图；
- `state_json/summary`：脱敏结构化状态和摘要；
- `prompt_version`：Prompt 契约版本；
- `created_at/updated_at/expires_at`：生命周期与 24 小时 TTL。

`state_json` 只保存旅行约束、记忆引用、ToolPlan、工具 Trace、节点 Trace、模型调用摘要、错误类型和确认状态。不会保存完整 `message`、`recentMessages`、完整回复原文、密钥或 resume token 明文。

## 运行流程

1. `/api/agent/chat` 或 `/api/agent/chat/stream` 创建或复用 AgentRun。
2. `TravelMateGraph.invoke_traced()` 或 SSE generator 记录节点名称与 `elapsedMs`。
3. 模型调用记录 provider、scenario、fallback、错误类型和 Token usage。
4. Provider 未返回 usage 时保存 `{"status":"unknown"}`，不估算或伪造。
5. 正常完成写入 `completed`；异常只记录异常类型并写入 `failed`。
6. 响应附带 `runId/requestId/status`。

## Human-in-the-loop

需要显式同意的记忆候选会使 run 进入 `pending_confirmation`，响应增加 `resumeToken`。

```text
POST /api/agent/runs/{run_id}/resume
{
  "resumeToken": "...",
  "action": "confirm",
  "candidateIds": ["mem-cilantro"]
}
```

- token 只以 SHA-256 哈希保存；
- run 必须属于当前认证用户且未过期；
- `confirm` 将选中候选写为 `confirmed` 记忆；
- `cancel` 完成 run，但不写入记忆；
- 相同决策重复请求幂等；
- 已确认后改为相反决策返回 409；
- 过期返回 410，错误 token 返回 403，其他用户按不存在处理。

该实现属于业务级 interrupt/resume：Agent 回复已经生成，被中断的是需要用户授权的记忆副作用，不声称使用 LangGraph checkpointer。

## Trace 查询

```text
GET /api/agent/runs/{run_id}
```

接口只返回当前用户的 run，并从结果中移除 token hash 和内部记忆值。可用于面试演示节点耗时、工具执行、fallback、模型调用和确认决策。

## 验证

```powershell
cd services/api
uv run pytest tests/test_agent_runs.py tests/test_agent_api.py tests/test_memory_context.py -q
uv run python scripts/migration_plan.py check
```

确定性评测与真实 Provider smoke 分离；GitHub Actions 在 API pytest 后运行 32 条 Golden Cases，并始终上传 JSON/Markdown 报告。
