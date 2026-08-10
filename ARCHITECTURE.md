# 架构设计

## 系统总览

```mermaid
graph TB
    subgraph "Flutter 客户端 apps/mobile"
        UI[页面层: 首页直聊/行程/复盘/记忆/提醒]
        Ctrl[状态管理: HomeChatController]
        Dio[Dio HTTP/SSE 客户端]
        Drift[Drift SQLite 离线存储]
    end

    subgraph "FastAPI 后端 services/api"
        API[API 路由层]
        Graph["LangGraph TravelMate Agent"]
        Memory[记忆上下文: 用户/scope/status 过滤]
        Planner[受约束 ToolPlan]
        Executor[依赖感知并行执行器]
        Provider[模型 Provider: OpenAI 兼容]
        Tools[工具层: 高德天气/POI/路线]
        DB[(Postgres + Alembic)]
        Audit[审计日志]
    end

    UI --> Ctrl --> Dio
    Dio -->|"POST /api/agent/chat/stream SSE"| API
    Dio -->|"POST /api/agent/chat"| API
    API --> Graph
    API --> Memory --> Graph
    Graph --> Planner --> Executor
    Planner -->|"结构化规划"| Provider
    Executor --> Tools
    Graph -->|"结构化输出校验"| Provider
    Graph --> DB
    Graph --> Audit
    Drift -->|"端侧聊天历史/记忆"| UI
```

## Agent 状态机

TravelMateGraph 是一个 LangGraph 显式状态机，由 19 个节点组成。API 和图节点共用单一 `IntentDecision`，根据结构化意图选择 4 种执行模式：

```mermaid
graph LR
    subgraph "Full 模式 (完整规划)"
        N1[input_normalizer] --> N2[context_loader]
        N2 --> N3[intent_router]
        N3 --> N4[memory_extractor]
        N4 --> N5[memory_writer]
        N5 --> N6[profile_updater]
        N6 --> N7[trip_context_builder]
        N7 --> N8[tool_planner]
        N8 --> N9[tool_executor]
        N9 --> N10[trip_planner]
        N10 --> N11[trip_adjuster]
        N11 --> N12[reminder_checker]
        N12 --> N13[avatar_state_mapper]
        N13 --> N14[response_composer]
    end

    subgraph "Chat 模式 (轻量聊天)"
        C1[input_normalizer] --> C2[context_loader]
        C2 --> C3[intent_router]
        C3 --> C4[fast_chat_response]
    end

    subgraph "Plan 模式 (仅规划)"
        P1[input_normalizer] --> P2[context_loader]
        P2 --> P3[intent_router]
        P3 --> P4[trip_context_builder]
        P4 --> P5[tool_planner]
        P5 --> P6[tool_executor]
        P6 --> P7[trip_planner]
        P7 --> P8[trip_adjuster]
    end

    subgraph "Review 模式 (仅复盘)"
        R1[input_normalizer] --> R2[context_loader]
        R2 --> R3[intent_router]
        R3 --> R4[review_generator]
    end
```

每个节点签名为 `def node(state: TravelMateState) -> TravelMateState`，通过 `_next_state(state, "node_name")` 不可变更新状态。`intent_router` 会把决策写入 Trace；`error_fallback` 作为兜底节点，确保任何异常都不会导致整个图崩溃。

## 记忆上下文

Agent 路由在创建 state 前从数据库加载最小化 `memoryContext`：

- 只查询当前认证用户且 `status=confirmed` 的记忆。
- `longTerm` 可跨行程使用。
- `currentTrip` 必须与当前 `tripId` 匹配。
- `temporary`、待确认和其他行程记忆不会进入规划。
- 长期与当前行程记忆分别限制数量，标题和内容限制字符数。
- 健康、位置、同行人等敏感类别不传完整原文，只保留记忆 ID、标题、scope 和结构化约束。

`context_loader` 按 category 通用聚合饮食、节奏、兴趣、交通和预算画像，不再依赖“不吃香菜”“喜欢夜景”等固定标题。规划结果通过 `memoryReferences` 解释使用了哪些已确认记忆，移动端只展示引用数量，不展示敏感内容。

## 动态 ToolPlan 与并行执行

`tool_planner` 首选模型生成以下结构化信息：

- `goal`
- `steps[].stepId/tool/reason/input/dependsOn`
- `maxSteps`
- `plannerProvider/fallback`

计划必须通过 Pydantic Schema、工具白名单、非空参数、最大 4 步、依赖存在性和无环校验。无效计划自动回退确定性规则：天气问题只查天气，景点推荐查天气与 POI，有起终点坐标时才增加路线工具。

`tool_executor` 按依赖层级执行 DAG：同一层的独立工具使用线程池并行执行；单步异常转换为结构化 fallback，不取消其他独立步骤；依赖失败的步骤标记为 `blocked`。最终 Trace 顺序与 ToolPlan 一致，并包含 `stepId`、原因、耗时、依赖状态、重试、缓存和错误类型。

## SSE 流式机制

`POST /api/agent/chat/stream` 基于 `LangGraph stream(stream_mode="updates")` 逐节点推送：

1. 每个节点完成后推送 `event: stage`，包含 `node` 和中文 `label`（如"查询实时天气与景点"）。
2. 全部节点完成后推送 `event: final`，包含完整 `AgentChatResponse` JSON。
3. 异常时推送 `event: error`。

客户端 `sendMessageStreaming` 解析 SSE 事件流，在打字指示器实时显示当前阶段；解析失败或服务不可用时自动降级到非流式 `POST /api/agent/chat`。

选择阶段级而非 token 级流式的原因：响应是结构化 JSON，需要整体校验 schema 后才能安全拆分为卡片、记忆候选等组件。阶段级进度已能消除 8-15 秒全链路等待的焦虑感。

## 状态结构

`TravelMateState` 是一个 `TypedDict`，承载整个对话轮次的全部中间状态：

- 输入：`message`、`session_id`、`user_id`、`context`（含 `recentMessages` 多轮上下文）
- 中间产物：`normalized_input`、`intent_decision`、`intent`、`memory_candidates`、`user_profile`、`trip_context`、`tool_plan`、`tool_plan_metadata`、`tool_trace`、`trip_plan`、`reminders`
- 输出：`response`（含 `replyText`、`avatarState`、`emotion`、`cards`、`memoryCandidates`、`toolTrace`、`nextActions`、`syncSuggestions`）
- 审计：`model_call_logs`、`visited_nodes`

## 端云分工

| 职责 | 端侧 Flutter | 云端 FastAPI |
| --- | --- | --- |
| 聊天历史 | Drift SQLite 本地持久化 | 不存储会话历史 |
| 记忆胶囊 | 本地确认/编辑/删除 | 记忆候选生成 + 云端同步 |
| 行程规划 | 卡片展示 + 高德导航跳转 | LangGraph 规划 + 高德工具调用 |
| 用户画像 | 本地缓存 | 云端记忆聚合更新 |
| 模型调用 | 不直接调用 | OpenAI 兼容 Provider 结构化校验 |
| 审计日志 | 不涉及 | 脱敏日志落库 |

## Agent Run、Trace 与 HITL

每次聊天请求先创建或复用 `AgentRunRecord`，主键与关联字段包含 `run_id/request_id/user_id/session_id/trip_id/idempotency_key`。运行记录保存状态、意图、Prompt 版本、创建/更新时间和 24 小时 TTL；`state_json` 只保留旅行约束、记忆引用、ToolPlan、工具 Trace、节点 Trace、模型调用摘要和确认状态，不保存完整用户消息、recentMessages 或完整回复原文。

`TravelMateGraph.invoke_traced()` 复用 LangGraph 逐节点更新流，记录节点名称、`elapsedMs` 和完成状态。模型调用 Trace 关联 provider、scenario、fallback 和错误类型；Provider 未报告 Token usage 时明确写入 `{"status":"unknown"}`，不根据文本长度伪造。

需要显式同意的记忆候选会使 run 进入 `pending_confirmation`：

1. 响应返回 `runId/requestId/resumeToken`。
2. 服务端只保存 resume token 的 SHA-256 哈希和结构化候选，不保存原始对话。
3. `POST /api/agent/runs/{run_id}/resume` 校验当前用户、token、TTL 和既有决策。
4. `confirm` 将选中候选写为当前用户 `confirmed` 记忆；`cancel` 完成 run 但不保存记忆。
5. 相同决策重复调用返回相同结果；冲突决策返回 409。
6. `GET /api/agent/runs/{run_id}` 只允许当前用户读取，并移除 token hash 与内部记忆值。

## Agent 评测

`services/api/evals/` 提供不依赖真实 Provider 的确定性评测：

- 32 条 Golden Cases 覆盖聊天、规划、复盘、多轮目的地、目的地漂移、长期/当前行程/敏感记忆、记忆冲突、天气/POI/路线工具和降级。
- Runner 输出 JSON 与 Markdown 报告。
- 指标包含意图准确率、工具选择准确率、目的地一致性、记忆命中率、敏感确认规则、Schema 通过率及 P50/P95。
- 当前本地基线为 32/32 通过。
- GitHub Actions 的 API job 在 pytest 后运行确定性 Runner；失败时阻塞 CI，并通过 artifact 上传 JSON/Markdown 报告。真实 Provider smoke 继续按 secrets 条件执行，不作为普通 PR 的稳定门禁。

端侧不直接调用大模型 API，所有模型调用通过后端 Agent 统一管理，便于审计和降级控制。

## 降级策略

系统区分三类结果，通过 `provider` 和 `fallback` 字段显式标注：

1. **真实 Provider 结果**：模型或高德工具已配置密钥，返回结构化结果且 schema 校验通过，`fallback=false`。
2. **明确降级结果**：未配置密钥、HTTP 失败或 schema 无效，返回 `fallback=true` 并标注 `provider=unconfigured/mock` 和错误原因。
3. **本地聚合结果**：复盘、dashboard 等来自数据库的真实用户数据，不依赖外部服务。

客户端遇到 SSE 流式失败时自动降级到非流式接口；非流式失败时提供一键重试按钮。任何降级都不会用假数据冒充真实结果。

## 技术选型理由

- **LangGraph 显式状态机** vs LangChain Agent 自由循环：出行场景步骤有限且需要可解释性，显式状态机每个节点可独立测试和降级，延迟与成本可控。
- **阶段级 SSE** vs token 级流式：响应是结构化 JSON 需整体校验，阶段级进度已能消除等待焦虑，实现成本低。
- **Drift SQLite** vs 服务端会话存储：端侧持久化减少网络依赖，聊天历史随设备走，隐私可控；云端不存会话历史降低合规复杂度。
- **OpenAI 兼容 Provider** vs 锁定单一模型：通过统一接口适配蓝心/OpenAI 等多种模型，切换成本低。
- **Flutter** vs 原生：单代码库覆盖 Android，比赛期内交付效率最高；刻意不覆盖 iOS 以收敛范围。

## 目录结构

```
apps/mobile/          Flutter Android 客户端
  lib/
    features/         按功能划分: home/chat/trip/memory/review/reminder/settings
    core/             网络层、路由、主题
    shared/           共享组件: ChatBubble、TripPlanSummaryCard 等
  assets/             蓝小心立绘、开屏动画
services/api/         FastAPI 后端
  app/
    agents/travelmate/  LangGraph Agent: state/graph/nodes
    api/routes/         API 路由: agent/auth/audit/photo
    tools/              外部工具: 高德天气/POI/路线
    models/             SQLModel 数据模型
    db/                 数据库连接 + Alembic 迁移
  migrations/          Alembic 迁移脚本
infra/                 Docker Compose 编排
docs/                  工程文档
  engineering/         技术设计、API 契约、Agent 图、隐私合规
  handoff/             部署指南、交接状态
```

更多细节见 [docs/engineering/](docs/engineering/)。
