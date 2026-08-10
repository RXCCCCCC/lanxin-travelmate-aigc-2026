# 面试准备文档（蓝心同行）

> 用途：面向简历/面试场景，回答“这个项目是什么、技术难点在哪、为什么这么设计”。随功能优化持续更新。

## 一、项目一句话介绍

蓝心同行是一个全旅程 AI 旅游搭子应用：Flutter Android 客户端 + FastAPI/LangGraph 后端，接入真实大模型与高德地图工具，具备用户可控的长期记忆、个性化行程规划、主动情境提醒、旅行复盘与 2D 角色状态表达。

## 二、技术栈与选型理由

| 层 | 选型 | 理由 |
| --- | --- | --- |
| 客户端 | Flutter (Android/vivo) | 单代码库快速迭代；Drift(SQLite) 做本地聊天历史与离线兜底 |
| 后端 | FastAPI + SQLModel + Alembic | 类型安全的轻量 API 框架，Pydantic 契约与 OpenAPI 文档自动化 |
| Agent 编排 | LangGraph 状态机 | 显式节点图（意图路由→记忆抽取→规划→响应合成），比裸 prompt 链更可控、可测试 |
| 模型接入 | OpenAI 兼容协议多 provider | 一套代码适配 vivo 蓝心/OpenAI 兼容端点，运行时可切换 |
| 工具 | 高德开放平台（天气/POI/路线） | 真实数据；每次调用带 provider/fallback 标记，可审计 |
| 数据库 | 本地 SQLite / 云端 Postgres | 端云协同：隐私记忆端侧优先，复杂推理云端完成 |
| 部署 | Docker Compose + 公网 HTTPS | 一键起 API+Postgres；公网 https://api.rxcccccc.icu 供真机演示 |

## 三、核心技术难点与解决方案

### 1. 可控长期记忆（记忆胶囊）
- 问题：AI 不应默默记住用户隐私；记忆要影响后续规划才有价值。
- 方案：模型抽取记忆候选 → 按类别标记敏感度（饮食=personal、健康/位置=sensitive）→ 用户确认保存范围（longTerm/currentTrip/temporary/ignore）→ 画像沉淀 → 规划时引用并解释（profileMatches）。
- 细节：模型候选与规则候选合并时按标题对齐规范 id 与隐私元数据，保证“不吃香菜”始终是 mem-cilantro 且 requiresExplicitConsent=true（防止模型漂移破坏隐私契约）。
- 服务端读取：只加载当前认证用户、`status=confirmed` 的记忆；`longTerm` 可跨行程，`currentTrip` 必须匹配 `tripId`，`temporary` 不进入长期画像。
- 隐私最小化：敏感类别不会把完整原文交给模型，规划结果只返回 `memoryId/title/scope/appliedReason`，客户端只展示已参考数量。

### 2. 真实链路与降级策略（fallback 体系）
- 问题：真实模型/第三方 API 会超时、限流、输出不合 schema。
- 方案：每个节点 try 真实 provider → Pydantic schema 校验失败或超时则落到规则兜底；所有调用写入 toolTrace（provider/fallback/errorType/retryCount/cacheHit/circuitOpen），前端可见降级原因。
- 原则：mock 只作为异常降级，不冒充真实完成；无 Key 时显式返回 unconfigured。

### 3. 目的地漂移防线
- 问题：用户说“规划广州行程”，模型结构化输出可能漂移成北京。
- 方案：_enforce_requested_destination 在规划节点后校验，明确请求的目的地强制写回 trip_plan，并替换 title/summary 中的错误目的地；有回归测试覆盖。

### 4. SSE 流式体验
- 问题：全链路规划（天气+POI+模型）需 8-15s，用户直面长时间白屏。
- 方案：/api/agent/chat/stream 基于 LangGraph stream(updates) 逐节点推送 SSE stage 事件（中文阶段文案如“查询实时天气与景点”），最后推 final 完整响应；聊天页与首页直聊的打字指示器均实时显示当前阶段，失败自动降级到非流式接口。
- 取舍：未做 token 级流式（因为响应是结构化 JSON 需整体校验），阶段级进度已能消除等待焦虑且实现成本低。

### 5. 多轮对话上下文
- 方案：客户端携带最近 8 条消息（截断 200 字/条）作为 context.recentMessages，后端注入 companion_chat 模型输入；轻量、不依赖服务端会话存储，会话历史本地 Drift 持久化；聊天页与首页直聊两个入口共用同一套上下文策略。
- 追问场景：目的地抽取器过滤疑问词（“去哪里”不会被当成目的地），当前消息无目的地时从历史用户消息（新到旧）继承，助手消息不参与避免文案污染；实测“第一天晚上去哪”能正确继承上轮“重庆”并给出洪崖洞/南山推荐。

### 6. 隐私与审计
- 模型调用日志脱敏：密钥/Authorization/Token 统一 [REDACTED]，用户原文只保留字符数摘要。
- 照片只上传远程 URL/文件名/类型，不上传本地路径；发布类文案必须用户确认。
- 记忆更新和删除按当前用户校验所有权；审计接口要求认证并按用户隔离。

### 7. 动态工具规划与并行执行
- 模型优先生成结构化 `ToolPlan`，每步包含 `stepId/tool/reason/input/dependsOn`。
- 服务端校验 Pydantic Schema、工具白名单、非空参数、最大 4 步和 DAG 无环；未知工具或非法计划自动回退确定性 Planner。
- 确定性规则保证：天气问题只查天气，景点推荐查天气和 POI，有起终点坐标时才调用路线。
- 同层独立步骤使用线程池并行执行；单步失败不取消其他步骤，依赖失败标记 `blocked`，Trace 顺序仍与计划一致。

### 8. Agent 评测
- 建立 32 条中文 Golden Cases，不依赖 API Key。
- 覆盖聊天、规划、复盘、目的地继承/漂移、长期/本次/敏感记忆、工具选择、Provider/Schema/限流降级。
- 当前确定性基线：32/32 通过；意图、工具选择、目的地、记忆、敏感确认和 Schema 指标均为 100%。
- Runner 输出 JSON 和 Markdown，可直接作为回归证据；GitHub Actions 将确定性评测作为 API job 门禁并上传报告，真实 Provider smoke 仍按 secrets 条件执行。

### 9. Agent Run 与 Human-in-the-loop
- 每次聊天生成 `runId/requestId`，服务端通过 SQLModel + Alembic 持久化用户隔离的结构化状态、节点耗时、模型/工具摘要、Prompt 版本和 TTL，不保存完整聊天原文。
- 需显式同意的记忆候选进入 `pending_confirmation`；resume API 校验当前用户、token 哈希、24 小时 TTL 和既有决策。
- 确认后使用“用户 + 候选 ID”的稳定主键写入记忆，重复确认幂等；取消后 run 继续完成但不写记忆，跨用户读取与恢复统一返回不可见。
- 这里采用业务级 interrupt/resume，而非声称使用 LangGraph checkpointer：中断的是记忆副作用，Agent 回复已完成，边界更清晰且易于演示。

## 四、架构速览

- 请求流：Flutter → `/api/agent/chat` → AgentRun → LangGraph（input_normalizer → intent_router → memory_extractor → trip_context_builder → tool_planner/tool_executor → trip_planner → response_composer）→ 结构化响应与脱敏 Trace → 必要时 HITL resume。
- 端云分工：端侧 Drift 存聊天历史与离线兜底；云端 Postgres 存记忆/行程/复盘/审计。
- 工程文档：docs/engineering/（API 契约、Agent 图、隐私合规、数据库迁移）。

## 五、常见追问准备

- 为什么不用 LangChain Agent/AutoGPT 式自由循环？→ 出行场景步骤有限且需可解释，显式状态机每个节点可单测、可降级，延迟与成本可控。
- 性能？→ SSE 提供阶段级反馈；天气和 POI 等独立步骤已并行执行，测试证明两个慢工具总耗时接近较慢单工具，而非两者之和。真实 Provider 的 P50/P95 会单独测量，不用本地规则耗时冒充线上数据。
- 如何扩展新工具/新触发？→ 工具层统一 provider/fallback 契约新增即可；提醒触发（time/location/status）为可枚举类型，新增触发只扩展评估函数。
- 测试策略？→ 核心链路定向测试 + 32 条确定性 Golden Cases；真实 Provider 只做手动 smoke，不作为普通 PR 的不稳定门禁。

## 六、当前状态与已知不足（诚实回答用）

- 已完成：多用户安全边界、真实按 scope 过滤的记忆上下文、通用画像聚合、`memoryReferences`、受约束动态 ToolPlan、并行工具执行、统一 IntentDecision、AgentRun、业务级 HITL、运行级 Trace、32 条 Golden Cases、CI 评测门禁、移动端 Agent 依据展示，以及原有规划/提醒/旅拍/复盘/SSE/多轮体验。
- 进行中：最终全量回归与文档收尾。
- 已知不足：流式为阶段级而非 token 级；2D 数字人为静态立绘+状态表情；iOS 不在当前范围；不制作 PPT，展示材料以仓库文档和可运行验收为主。

## 七、简历项目描述候选

- 设计并实现 Flutter + FastAPI + LangGraph 旅行 Agent，将用户隔离、scope 记忆、结构化规划、真实地图工具、主动提醒和旅行复盘串成可运行闭环。
- 构建受约束 `ToolPlan`：通过 Pydantic、工具白名单和 DAG 校验限制模型行为，并行执行无依赖工具，单步失败可隔离降级且保留步骤级 Trace。
- 实现隐私可控记忆：仅加载当前用户已确认且场景允许的记忆，敏感内容最小化进入模型，并通过 `memoryReferences` 向用户解释规划依据。
- 建立 32 条无密钥 Golden Cases，当前确定性评测在意图、工具选择、目的地一致性、记忆和敏感确认规则上均达到 100%。
- 实现用户隔离的 Agent Run 与 HITL：持久化脱敏结构化状态和节点耗时，以 token + TTL + 幂等决策控制记忆确认/取消，并提供当前用户范围内 Trace 查询。
