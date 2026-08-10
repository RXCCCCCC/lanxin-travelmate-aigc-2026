# Agent 实习作品最终验收

## 面试官 5 分钟路径

### 1. 理解项目，1 分钟

阅读：

- `README.md`
- `ARCHITECTURE.md`

重点确认项目不是单次 Prompt Demo，而是包含用户隔离、记忆、工具规划、降级、评测和移动端体验的完整 Agent 应用。

### 2. 运行确定性评测，1 分钟

```powershell
cd services/api
uv sync --dev
uv run python -m evals.runner --output-dir artifacts/evals
```

期望：

- 32 条 Case 全部通过。
- 意图、工具选择、目的地、记忆、敏感确认和 Schema 指标均为 100%。
- 输出 JSON 和 Markdown 报告。

### 3. 验证关键后端能力，1 分钟

```powershell
uv run pytest `
  tests/test_authenticated_user_scope.py `
  tests/test_memory_context.py `
  tests/test_dynamic_tool_planning.py `
  tests/test_tool_execution.py `
  tests/test_intent_routing.py `
  tests/test_agent_runs.py `
  tests/test_agent_evals.py -q
```

重点确认：

- 用户不能修改或删除其他用户的记忆。
- 只有当前用户已确认且 scope 匹配的记忆进入 Agent。
- 未知工具计划自动降级。
- 独立工具并行执行，失败互不取消。
- API 和图使用同一个意图决策。
- AgentRun 只保存脱敏结构化状态并记录节点耗时。
- HITL 确认/取消具备用户隔离、token、TTL 和幂等语义。

### 4. 验证移动端证据，1 分钟

```powershell
cd ..\..\apps\mobile
flutter analyze --no-pub
flutter test test/trip_page_integration_test.dart --no-pub
```

行程页应显示：

- 已参考的确认记忆数量；
- 已使用的天气、景点和路线工具类型；
- 不显示敏感记忆原文、Provider 名称或内部错误片段。

### 5. 面试讨论，1 分钟

阅读 `INTERVIEW_PREP.md`，重点讨论：

- 为什么选择显式 LangGraph 状态机；
- 如何约束模型生成的 ToolPlan；
- 如何实现 scope 记忆与隐私最小化；
- 为什么确定性评测与真实 Provider 评测分离；
- 并行执行、错误隔离和 Trace 如何设计。
- 为什么采用业务级 HITL，而不是把普通数据库状态描述成 LangGraph checkpointer。

## 当前完成状态

已完成：

- 多用户安全边界；
- 真实、按 scope 过滤的记忆上下文；
- 通用画像和 `memoryReferences`；
- 受约束动态 ToolPlan；
- 依赖感知并行工具执行；
- 统一 IntentDecision；
- 持久化 AgentRun 与 Alembic `0009_agent_runs`；
- 运行级节点、模型和工具 Trace；
- HITL `pending_confirmation`、确认/取消与 resume；
- 32 条 Golden Cases；
- GitHub Actions 确定性评测门禁与报告上传；
- 移动端 Agent 依据展示；
- README、架构和面试材料。

尚未完成：

- 最终全量回归和真实 Provider 手动验收。

## 2026-08-10 自动化验收结果

- 后端完整测试：213 条通过。
- Flutter 完整测试：108 条通过。
- Flutter 静态分析：无问题。
- Agent Golden Cases：32/32 通过。
- Git 工作区：干净。
- 未执行远程推送或部署。

当前已知非阻塞警告：

- FastAPI TestClient 提示未来可迁移到 `httpx2`。
- Flutter 响应式布局测试会提示同一测试进程创建多个 Drift 数据库实例，但全部测试通过；该警告不代表生产数据库共用同一执行器。
