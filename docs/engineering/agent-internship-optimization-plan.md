# 蓝心同行 Agent 开发实习作品完善计划

> 创建日期：2026-08-10  
> 目标岗位：Agent 应用开发实习  
> 实施策略：后端与 Agent 约 80%，移动端体验约 20%  
> 工作流：Trellis `Plan -> Implement -> Verify -> Finish`  
> 提交策略：每完成一个可独立验收的里程碑进行一次本地提交  
> 远程策略：不自动推送、部署或修改生产环境；到达远程操作节点时单独确认

## 1. 总目标

把蓝心同行从“功能较完整的 AI 旅行应用”提升为一个可在 Agent 开发实习面试中证明以下能力的工程化项目：

1. 能够设计可控的 Agent 状态机，而不是只拼接 Prompt。
2. 能够让 Agent 使用真实、用户隔离、隐私可控的长期记忆。
3. 能够进行受约束的动态工具规划、参数校验、并行执行与降级。
4. 能够实现人工确认后继续执行的 Human-in-the-loop 流程。
5. 能够建立 Agent 评测集、回归指标、Trace、延迟与 fallback 统计。
6. 能够处理多用户权限、敏感数据、第三方服务失败和生产部署问题。
7. 能够用 README、架构文档和量化结果让面试官在 5 分钟内理解并验收项目。

## 2. 已确认的产品与技术决策

| 决策项 | 结论 |
| --- | --- |
| 目标岗位 | Agent 应用开发实习 |
| 优化重心 | Agent/后端 80%，移动端 20% |
| 服务端会话 | 保存结构化状态和脱敏摘要，不保存完整聊天原文 |
| 评测方式 | 20-40 条本地 Golden Cases；CI 运行确定性评测；真实 Provider 手动运行 |
| 工具方案 | 结构化 ToolPlan、白名单、参数校验、并行执行、确定性降级 |
| 仓库清理 | 修复路径与状态，不主动删除历史文件 |
| 数字人 | 保留静态立绘和状态表情，不引入 Live2D |
| 语音/图片 | 不作为本轮核心阻塞项 |

## 3. 当前基线

### 3.1 已有优势

- Flutter Android 客户端，具备首页直聊、独立聊天、聊天历史、记忆、行程、提醒、旅拍和复盘。
- FastAPI + LangGraph 后端，具有多执行模式、结构化模型输出、SSE 阶段流式响应。
- OpenAI 兼容和蓝心 Provider，高德天气、POI、路线 Provider。
- 明确的 `provider/fallback/errorType/retryCount/cacheHit/circuitOpen` 降级元数据。
- Drift 本地存储、Postgres 云端存储、Alembic 迁移。
- 模型调用脱敏审计、工具调用记录、CI、Docker、公网 HTTPS API。
- 已覆盖大量后端接口测试和 Flutter 集成测试。

### 3.2 已确认缺口

1. `context_loader` 使用固定画像，没有加载当前用户真实记忆。
2. `profile_updater` 只处理少量固定标题，不具备通用画像聚合能力。
3. HTTP 路由层和 LangGraph 图内存在两套意图路由。
4. `tool_planner` 固定调用天气、夜景 POI 和路线。
5. `tool_executor` 串行执行所有工具。
6. LangGraph 当前主要是固定顺序图，没有真实 interrupt/resume/checkpointer。
7. 多轮上下文由客户端上传最近 8 条消息，服务端没有可信会话状态。
8. 缺少 Agent Golden Cases、成功率、工具选择、Schema、延迟和 fallback 评测。
9. 模型审计没有统一 `runId/requestId`、节点耗时、Token 使用和 Prompt 版本。
10. 单条记忆更新和删除缺少用户范围校验。
11. 审计接口默认公开，缺少按用户隔离或管理员保护。
12. 项目规则和状态文档存在已经归档的旧路径及过期状态。

## 4. 最终验收指标

### 4.1 安全指标

- 任意已认证用户不能读取、修改或删除其他用户的记忆。
- 匿名用户不能读取全局模型或工具审计数据。
- 已认证用户只能读取自己的工具调用记录。
- 模型审计至少按当前用户隔离；实现管理员模式前不开放全局查询。
- 现有游客兼容路径继续工作，不破坏客户端启动。

### 4.2 记忆指标

- Agent 上下文中不再出现固定写死的“不吃香菜、慢节奏、夜景”画像。
- 仅加载当前用户、已确认、允许当前场景使用的记忆。
- `longTerm` 记忆可跨行程使用。
- `currentTrip` 记忆只在匹配行程中使用。
- `temporary` 记忆不写入长期画像。
- 敏感记忆必须保留显式确认和范围限制。
- 规划结果返回 `memoryReferences` 或等价解释，说明使用了哪些记忆。
- Golden Cases 中用户隔离正确率和目的地一致性达到 100%。

### 4.3 工具指标

- ToolPlan 使用 Pydantic Schema 校验。
- 工具名必须来自白名单。
- 单轮最大工具调用数可配置，默认不超过 4。
- 单工具输入经过字段和类型校验。
- 天气与 POI 等无依赖工具可并行执行。
- 路线工具根据坐标和规划需求决定是否调用。
- 模型规划失败时自动回退确定性 Planner。
- 每个工具步骤记录选择原因、耗时、fallback 和错误类型。
- Golden Cases 工具选择准确率目标不低于 90%。
- 并行执行后，真实工具链延迟相对串行基线有可记录的下降；目标为 P50 下降至少 20%，不作为不稳定外部 API 的 CI 硬门槛。

### 4.4 状态与 Human-in-the-loop 指标

- 每次 Agent 请求生成稳定的 `runId`。
- 服务端保存结构化状态、已确认操作和脱敏摘要，不保存完整聊天原文。
- 记忆候选可以进入 `pending_confirmation` 状态。
- 用户确认后可使用 `runId` 或 `resumeToken` 继续执行。
- 重复确认请求具备幂等性。
- 过期或属于其他用户的 resume 请求被拒绝。
- 状态保存具有 TTL 或明确清理策略。

### 4.5 评测与可观测性指标

- 建立不少于 30 条中文旅行 Golden Cases。
- 覆盖聊天、规划、复盘、记忆、敏感记忆、工具选择、目的地漂移和降级。
- CI 确定性评测输出 JSON 和 Markdown 摘要。
- 评测至少输出：
  - 意图路由准确率；
  - 目的地一致性；
  - 记忆抽取命中率；
  - 敏感信息确认规则通过率；
  - 工具选择准确率；
  - Schema 通过率；
  - fallback 比例；
  - P50/P95 延迟。
- 真实 Provider 评测不会作为普通 PR 的阻塞条件。
- Trace 可关联请求、节点、模型调用和工具调用。
- Provider 返回 usage 时记录输入/输出 Token；没有 usage 时标记 `unknown`，不伪造。

### 4.6 简历交付指标

- README 首页能说明问题、架构、Agent 机制、评测结果和运行方式。
- `ARCHITECTURE.md` 与代码一致，不再描述过期结构。
- `INTERVIEW_PREP.md` 覆盖 Agent 评测、动态工具、HITL、状态管理、安全和降级。
- 提供面试官 5 分钟验收命令。
- 输出 3-4 条带量化指标的简历项目描述。
- Flutter analyze、核心 Flutter 测试、后端 Agent 定向测试、评测脚本和 Docker 构建通过。

## 5. 实施阶段

## Phase 0：计划、基线与任务拆分

### 目标

建立 Trellis 父任务、子任务、PRD、研究记录和实施上下文，确保后续可以跨会话继续。

### 产物

- 本计划文档。
- `.trellis/tasks/08-10-agent-internship-hardening/` 父任务。
- 6 个 Trellis 子任务。
- 当前代码审计研究记录。
- 初始基线命令和结果。

### 验收

- Trellis 任务可通过 `task.py validate`。
- 父任务能列出全部子任务。
- `git status` 除计划和 Trellis 文件外无意外改动。

### 提交

`docs: 新增 Agent 实习作品工程化增强计划与 Trellis 任务`

## Phase 1：安全边界与文档基线

### 1A. 记忆接口用户隔离

#### 代码范围

- `services/api/app/api/routes/memory.py`
- `services/api/tests/test_authenticated_user_scope.py` 或独立最小安全测试

#### 实现

- `PUT /api/memory/capsules/{memory_id}` 注入 `CurrentUser`。
- `DELETE /api/memory/capsules/{memory_id}` 注入 `CurrentUser`。
- 对目标记忆执行所有权校验。
- 已认证用户不能通过 ID 修改或删除其他用户数据。
- 保留匿名 `guest` 兼容语义。

#### 验收

- 用户 A 修改/删除用户 B 的记忆返回 403。
- 用户 A 修改/删除自己的记忆成功。
- 不存在的记忆返回 404。

#### 提交

`fix(security): 修复单条记忆更新与删除的用户越权`

### 1B. 审计数据访问边界

#### 代码范围

- `services/api/app/api/routes/audit.py`
- `services/api/app/services/model_audit.py`
- `services/api/tests/test_audit_routes.py`
- 如确有必要，后续单独确认数据库迁移

#### 实现

- 工具日志按当前用户过滤。
- 模型日志从脱敏 `requestSummary.userId` 过滤当前用户，先避免数据库迁移。
- 匿名用户只能读取 `guest` 范围，不能读取其他用户。
- 不在本阶段引入管理员账号体系。
- 如果现有数据无法可靠隔离，默认拒绝返回，而不是返回全局日志。

#### 验收

- 用户 A 看不到用户 B 的模型和工具日志。
- 审计输出继续隐藏用户原文和密钥。

#### 提交

`fix(security): 审计接口按当前用户隔离调用记录`

### 1C. 文档状态收敛

#### 文件范围

- `CLAUDE.md`
- `docs/todo.md`
- `docs/handoff/ai-shared-state.md`
- 必要时 `README.md`

#### 实现

- 修正归档后的文档路径。
- 删除“当前进行中”里已经完成的项目。
- 保留历史记录，不删除 `docs/archive/`。
- 将当前主线改为 Agent 工程化增强。

#### 验收

- 所有活动文档链接指向真实文件。
- `rg` 不再发现活动文档引用已移动路径。
- `git diff --check` 通过。

#### 提交

`docs: 收敛 Agent 工程化阶段的规则、状态和待办`

## Phase 2：真实记忆上下文

### 2A. 服务端加载用户记忆

#### 代码范围

- `services/api/app/api/routes/agent.py`
- 新增 `services/api/app/services/memory_context.py`
- `services/api/app/agents/travelmate/state.py`
- `services/api/app/agents/travelmate/nodes/real_nodes.py`
- 相关定向测试

#### 实现

- Agent 路由根据 `effective_user_id` 查询：
  - 当前画像；
  - 已确认长期记忆；
  - 与当前 `tripId` 匹配的本次旅行记忆。
- 转换为最小结构化 `memoryContext`。
- 不把完整敏感原文放入模型输入。
- 每类记忆设置数量和字符上限。
- `context_loader` 从 `memoryContext` 构建 `user_profile`。
- 删除固定画像 fixture。

#### 验收

- 两个用户使用不同记忆时得到不同 Agent 上下文。
- 未确认记忆不进入规划。
- `currentTrip` 不跨行程泄漏。
- 不配置云端记忆时仍能正常聊天。

#### 提交

`feat(agent): 将已确认用户记忆加载到 Agent 上下文`

### 2B. 通用画像聚合与记忆引用

#### 代码范围

- `services/api/app/services/memory_context.py`
- `services/api/app/agents/travelmate/nodes/real_nodes.py`
- `services/api/app/agents/travelmate/schemas/model_outputs.py`
- `services/api/app/schemas/agent.py`
- Flutter 响应模型和行程卡片（仅必要字段）

#### 实现

- 按 category 映射饮食、节奏、兴趣、交通、预算和敏感约束。
- 使用通用字段，不按“喜欢夜景”“不吃香菜”标题硬编码。
- 规划结果增加 `memoryReferences`：
  - memoryId；
  - title；
  - scope；
  - appliedReason。
- 客户端在行程卡片中显示“已参考 X 条已确认偏好”。

#### 验收

- 新增任意饮食偏好无需改代码即可进入画像。
- 响应不会暴露敏感记忆完整原文。
- 老客户端缺少新字段时不崩溃。

#### 提交

`feat(memory): 通用聚合旅行画像并解释规划使用的记忆`

## Phase 3：动态工具规划与执行

### 3A. ToolPlan Schema 与 Planner

#### 代码范围

- 新增 `services/api/app/agents/travelmate/schemas/tool_plan.py`
- 新增 `services/api/app/agents/travelmate/tool_planning.py`
- `services/api/app/agents/travelmate/nodes/real_nodes.py`
- `services/api/app/tools/registry.py`
- 相关测试

#### ToolPlan 最小结构

- `goal`
- `steps`
  - `tool`
  - `reason`
  - `input`
  - `dependsOn`
- `maxSteps`
- `plannerProvider`
- `fallback`

#### 实现

- 首选模型生成结构化 ToolPlan。
- 校验工具白名单和参数 Schema。
- 拒绝未知工具、空参数、超过最大步骤的计划。
- 提供确定性 Planner：
  - 普通闲聊不调用工具；
  - 天气问题只调用天气；
  - 景点推荐调用天气和 POI；
  - 行程规划按是否有坐标决定路线调用。
- 模型计划无效时记录 `plannerFallback`。

#### 验收

- “杭州明天天气”不调用路线。
- “推荐广州夜景”调用 POI，可选天气，不强制路线。
- “从当前位置规划到西湖”在有坐标时调用路线。
- 未知工具被拒绝并降级。

#### 提交

`feat(agent): 引入受约束的结构化动态工具规划`

### 3B. 并行工具执行与步骤 Trace

#### 代码范围

- `services/api/app/agents/travelmate/tool_execution.py`
- `services/api/app/agents/travelmate/nodes/real_nodes.py`
- `services/api/app/tools/registry.py`
- 相关测试

#### 实现

- 无依赖步骤并行执行。
- 有 `dependsOn` 的步骤等待依赖完成。
- 保持最终 Trace 顺序与 ToolPlan 一致。
- 单步异常不取消全部独立步骤。
- 增加：
  - `stepId`
  - `reason`
  - `elapsedMs`
  - `dependencyStatus`
  - `retryCount`
  - `fallback`
- 设置总预算和单工具超时。

#### 验收

- 两个慢工具并行时总耗时接近较慢单工具，而非两者之和。
- 一个工具失败时其他工具结果仍被保留。
- 最终输出顺序稳定。

#### 提交

`perf(agent): 并行执行独立工具并记录步骤级 Trace`

### 3C. 统一意图路由

#### 代码范围

- `services/api/app/api/routes/agent.py`
- `services/api/app/agents/travelmate/nodes/real_nodes.py`
- `services/api/app/agents/travelmate/graph.py`
- 相关路由测试

#### 实现

- 移除 HTTP 层与图内重复的关键词表。
- 建立单一结构化 IntentDecision。
- API 层只负责创建状态和执行图。
- 继续提供确定性规则降级。
- 保持 `chat/plan/review` 三种执行模式的延迟优势。

#### 验收

- 中文和英文测试场景路由一致。
- 路由决策能在 Trace 中查看。
- 现有 SSE 阶段事件保持兼容。

#### 提交

`refactor(agent): 统一意图判定与图执行模式`

## Phase 4：服务端状态与 Human-in-the-loop

> 本阶段需要新增数据库表和 Alembic 迁移。执行前必须单独确认数据库变更。

### 4A. Agent Run 与脱敏会话状态

#### 建议数据模型

- `AgentRunRecord`
  - `id/run_id`
  - `user_id`
  - `session_id`
  - `trip_id`
  - `status`
  - `intent`
  - `state_json`
  - `summary`
  - `prompt_version`
  - `created_at/updated_at/expires_at`
- 不保存完整原始对话。
- `state_json` 只保留结构化旅行约束、记忆引用、工具计划和确认状态。

#### 实现

- 每次请求创建或继续 Agent Run。
- 客户端传入的 recentMessages 只作为兼容输入。
- 服务端状态优先于客户端可伪造状态。
- 超过 TTL 的 run 不允许 resume。
- 支持幂等请求 key。

#### 验收

- 同一用户跨设备可恢复结构化行程状态。
- 用户不能读取或恢复其他用户的 run。
- 数据库中不出现完整聊天原文。

#### 提交

`feat(agent): 持久化脱敏 Agent Run 与结构化会话状态`

### 4B. 真实记忆确认中断与恢复

#### API 设计

- 首次聊天可能返回：
  - `status=pending_confirmation`
  - `runId`
  - `resumeToken`
  - `memoryCandidates`
- 新增确认接口：
  - `POST /api/agent/runs/{run_id}/resume`
  - 请求包含已确认候选及 scope。

#### 实现

- 将现有 `memory_confirm_interrupt` 从提示节点升级为真实暂停点。
- 用户确认后写入记忆并继续画像、规划和响应合成。
- 拒绝重复、过期和跨用户 resume。
- 客户端维持现有确认面板，必要时增加“继续规划”状态。

#### 验收

- 未确认敏感记忆不会写入数据库。
- 确认后同一 run 继续执行。
- 重复确认不重复写入。
- 用户取消后可以按不记忆继续执行。

#### 提交

`feat(agent): 实现记忆确认的 Human-in-the-loop 暂停与恢复`

## Phase 5：Agent 评测与可观测性

### 5A. Golden Case 数据集

#### 文件范围

- `services/api/evals/cases/*.json`
- `services/api/evals/schema.py`
- `services/api/evals/runner.py`
- `services/api/evals/scorers.py`

#### 场景类别

- 纯聊天；
- 行程规划；
- 多轮目的地继承；
- 目的地漂移；
- 长期记忆；
- 当前行程记忆；
- 敏感记忆；
- 记忆冲突；
- 天气工具；
- POI 工具；
- 路线工具；
- 无工具问题；
- Provider 失败；
- Schema 失败；
- 限流；
- 复盘。

#### 实现

- JSON Case 描述输入、上下文和期望约束。
- 规则 scorer 不依赖真实模型。
- 可选 LLM-as-judge 只作为补充，不作为唯一标准。
- 结果写入 `artifacts/evals/`，目录默认 gitignore。

#### 验收

- 不少于 30 条 Case。
- 无密钥环境可运行。
- 单个失败 Case 输出明确差异。

#### 提交

`feat(eval): 建立 Agent Golden Cases 与确定性评分器`

### 5B. 运行级 Trace 与指标

#### 代码范围

- `services/api/app/services/agent_trace.py`
- 模型 Provider
- 工具执行器
- Agent 路由
- 审计接口

#### 实现

- 统一生成 `runId/requestId`。
- 节点开始、结束和耗时。
- 模型 Provider usage 解析。
- Prompt 版本常量。
- fallback、错误类型和重试关联。
- 新增用户范围内 Trace 查询接口。
- 对敏感字段继续脱敏。

#### 验收

- 一次请求可串联意图、节点、模型和工具。
- Provider 无 usage 时不会伪造 Token。
- Trace 查询受用户范围保护。

#### 提交

`feat(observability): 增加 Agent Run Trace、节点耗时和模型 usage`

### 5C. CI 评测门禁

#### 文件范围

- `.github/workflows/ci.yml`
- 评测脚本
- README

#### 实现

- 普通 CI 运行确定性评测。
- 真实 Provider 评测保持 secrets 条件触发。
- RPM/超时只影响真实评测任务，不阻塞普通 CI。
- 上传评测摘要 artifact。

#### 验收

- 无 Secret 的 PR CI 不调用真实 API。
- 评测失败能明确指出 Case。
- CI 时间保持可接受。

#### 提交

`ci: 增加无密钥 Agent 评测门禁与结果产物`

## Phase 6：简历交付与最终验收

### 6A. 移动端最小展示增强

#### 范围

- 行程卡片显示已使用记忆数量。
- 可查看本轮 Agent 的工具和降级摘要。
- HITL 状态有明确等待、确认、继续和失败反馈。
- 不新增复杂页面，不做视觉大改。

#### 验收

- 用户看得见 Agent 为什么这样规划。
- 调试信息不会污染普通用户界面。
- 真机交互最终由用户验收。

#### 提交

`feat(mobile): 展示记忆引用、工具摘要和 Agent 确认状态`

### 6B. 文档和简历材料

#### 文件范围

- `README.md`
- `ARCHITECTURE.md`
- `INTERVIEW_PREP.md`
- 新增 `docs/engineering/agent-evaluation.md`
- 新增 `docs/engineering/agent-observability.md`

#### 实现

- README 增加真实评测指标表。
- 架构图增加状态存储、ToolPlan、Trace 和 Eval。
- 面试文档增加设计取舍和故障案例。
- 提供 5 分钟验收命令。
- 输出简历 bullet：
  - 架构；
  - 记忆与 HITL；
  - 动态工具；
  - 评测与性能。

#### 提交

`docs: 完成 Agent 实习作品的评测、架构和面试材料`

### 6C. 最终验证

#### 必跑

- `git diff --check`
- GitNexus `detect_changes`
- `cd services/api && uv run pytest` 中的 Agent、安全、评测定向集合
- `cd apps/mobile && flutter analyze --no-pub`
- 核心 Flutter 集成测试
- `python scripts/docker_compose_preflight.py --json`
- Docker API 构建
- debug APK 构建
- 公网部署前只做本地/测试环境 smoke

#### 用户验收

- Android 真机聊天与规划。
- 记忆确认和继续执行。
- Agent Trace 展示。
- 页面文案和交互观感。

## 6. 测试策略

遵循“核心优先、最小必要测试”：

1. Bug 修复先添加最小复现测试。
2. 每个里程碑只运行相关测试。
3. 最终阶段再运行较完整集合。
4. 真实 Provider 测试不放入普通 CI 硬门禁。
5. UI 主观体验由用户真机验收。

## 7. 风险与缓解

| 风险 | 缓解 |
| --- | --- |
| LangGraph interrupt/checkpointer改动过大 | 先实现明确的 AgentRun/Resume 契约，再决定是否接官方 checkpointer |
| 数据库迁移影响公网 | 迁移前备份、检查 revision 长度、先本地 Docker 验证，部署单独确认 |
| 模型 ToolPlan 不稳定 | Pydantic 校验、白名单、最大步骤、确定性 fallback |
| 外部 API RPM 限制 | 本地 Golden Cases 不调用真实 API；真实任务重试、缓存、熔断、定时执行 |
| Trace 泄露隐私 | 保存结构化摘要，沿用统一脱敏函数，不记录完整 Prompt |
| 工具并行导致顺序不稳定 | stepId 和计划顺序归并输出 |
| 新字段破坏客户端 | 后端字段可选、Flutter 默认值兼容 |
| 计划范围过大 | 每阶段独立提交，可在任一完成点形成可展示版本 |

## 8. 回滚策略

- 每个里程碑独立提交，不混入无关重构。
- 数据库迁移必须包含 downgrade 或明确回滚路径。
- ToolPlan 保留旧确定性 Planner 作为 feature flag/fallback。
- 服务端状态上线初期继续接受客户端 `recentMessages`。
- 新响应字段保持可选，旧客户端仍可工作。
- 任何阶段验证失败，只回滚当前里程碑，不回退用户已有改动。

## 9. 明确不在本轮范围

- Live2D。
- iOS、Web、Windows、macOS 客户端。
- 自动发布朋友圈或小红书。
- 完整对象存储图片上传系统。
- 真实 ASR/TTS 供应商接入。
- 复杂向量数据库和通用 RAG 平台。
- 酒店、机票、支付和交易闭环。
- 多 Agent 自由协商框架。

## 10. 执行顺序与提交清单

1. 计划与 Trellis 基线。
2. 记忆接口越权修复。
3. 审计接口用户隔离。
4. 活动文档状态收敛。
5. 真实记忆上下文。
6. 通用画像和记忆引用。
7. 动态 ToolPlan。
8. 并行工具执行。
9. 统一意图路由。
10. 数据库变更确认。
11. Agent Run 状态。
12. Human-in-the-loop resume。
13. Golden Cases。
14. Trace 与 Token/延迟指标。
15. CI 评测门禁。
16. 移动端最小展示增强。
17. 文档、简历 bullet 和最终验收。

每一步完成后：

1. 运行最小定向验证。
2. 执行 GitNexus 影响检查或记录工具不可用的替代核对。
3. 更新 Trellis 任务状态。
4. 本地提交。
5. 继续下一步，不自动推送。
