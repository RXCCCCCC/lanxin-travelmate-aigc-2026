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

### 2. 真实链路与降级策略（fallback 体系）
- 问题：真实模型/第三方 API 会超时、限流、输出不合 schema。
- 方案：每个节点 try 真实 provider → Pydantic schema 校验失败或超时则落到规则兜底；所有调用写入 toolTrace（provider/fallback/errorType/retryCount/cacheHit/circuitOpen），前端可见降级原因。
- 原则：mock 只作为异常降级，不冒充真实完成；无 Key 时显式返回 unconfigured。

### 3. 目的地漂移防线
- 问题：用户说“规划广州行程”，模型结构化输出可能漂移成北京。
- 方案：_enforce_requested_destination 在规划节点后校验，明确请求的目的地强制写回 trip_plan，并替换 title/summary 中的错误目的地；有回归测试覆盖。

### 4. 多轮对话上下文
- 方案：客户端携带最近 8 条消息（截断 200 字/条）作为 context.recentMessages，后端注入 companion_chat 模型输入；轻量、不依赖服务端会话存储，会话历史本地 Drift 持久化。

### 5. 隐私与审计
- 模型调用日志脱敏：密钥/Authorization/Token 统一 [REDACTED]，用户原文只保留字符数摘要。
- 照片只上传远程 URL/文件名/类型，不上传本地路径；发布类文案必须用户确认。

## 四、架构速览

- 请求流：Flutter → /api/agent/chat → LangGraph（input_normalizer → intent_router → memory_extractor → trip_context_builder → trip_planner(工具调用) → avatar/rapport → response_composer）→ 结构化响应（replyText/avatarState/emotion/cards/memoryCandidates/toolTrace/nextActions）。
- 端云分工：端侧 Drift 存聊天历史与离线兜底；云端 Postgres 存记忆/行程/复盘/审计。
- 工程文档：docs/engineering/（API 契约、Agent 图、隐私合规、数据库迁移）。

## 五、常见追问准备

- 为什么不用 LangChain Agent/AutoGPT 式自由循环？→ 出行场景步骤有限且需可解释，显式状态机每个节点可单测、可降级，延迟与成本可控。
- 性能？→ 纯聊天约 2.5s；带天气+POI+规划全链路约 8s，可优化方向：工具并行、流式输出、规划结果缓存。
- 如何扩展新工具/新触发？→ 工具层统一 provider/fallback 契约新增即可；提醒触发（time/location/status）为可枚举类型，新增触发只扩展评估函数。
- 测试策略？→ 核心链路定向测试（图回归、API 契约、目的地防漂移、隐私标记），mock provider 注入测试模型异常路径。

## 六、当前状态与已知不足（诚实回答用）

- 已完成：记忆闭环、个性化规划、主动提醒（3 类触发）、复盘、盲盒、旅拍文案、多人协调后端、真机验证、公网部署、多轮上下文。
- 进行中：聊天体验优化（本轮）、release 正式签名。
- 已知不足：响应为一次性返回（无流式）；2D 数字人目前为静态立绘+表情状态切换（Live2D 评估后未上，成本收益不匹配）；iOS 未支持（刻意收敛范围）。
