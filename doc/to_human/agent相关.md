**LangGraph 编排、结构化工具调用、记忆系统、轻量 RAG、LangSmith 调试评估、生产级 Agent 工程化**。因为你的产品核心是“记忆胶囊 → 个性化规划 → 主动提醒 → 蓝小心状态 → 旅拍 → 复盘”的全旅程 Agent 闭环，而不是普通单轮聊天机器人。你的仓库说明也明确要求 P0 必须形成“记忆胶囊 → 个性化规划 → 主动提醒 → 蓝小心状态 → 旅行复盘”的演示闭环，并且所有涉及真实 API、地图、照片权限、模型调用的能力都要有模拟数据或降级实现。

## 总体结论

你接下来要补的知识按优先级是：

| 优先级 | 方向                             | 需要程度                                |
| ------ | -------------------------------- | --------------------------------------- |
| P0     | **LangGraph**                    | 必学，项目主 Agent 编排核心             |
| P0     | **Tool Calling / 工具系统设计**  | 必学，地图、天气、POI、照片、语音都靠它 |
| P0     | **结构化输出与 Pydantic Schema** | 必学，前后端稳定对接核心                |
| P0     | **Memory / 记忆系统设计**        | 必学，蓝心同行最大差异点                |
| P0     | **Prompt / Context Engineering** | 必学，控制蓝小心人格、规划、记忆抽取    |
| P1     | **RAG**                          | 要学，但不要一开始做复杂 RAG            |
| P1     | **LangSmith**                    | 要学，用于调试、追踪、评估 Agent        |
| P1     | **生产级 Agent 工程化**          | 要学，部署、日志、缓存、失败兜底        |
| P2     | LangChain 高级组件               | 选学，用到再补                          |
| P2     | 多 Agent / CrewAI / AutoGen      | 暂时不用学                              |

---

# 1. LangChain 你还需要学什么

LangChain 本身现在更适合**当“模型、工具、检索、Agent 基础组件库”**，而不是你项目的主流程框架。官方文档也把 LangChain 定义为**带预构建 Agent 架构和模型/工具集成的框架**；工具本质上是**带明确输入输出的可调用函数，模型可根据上下文决定是否调用工具。**

你只需要学 LangChain 的这些部分：

## 1.1 Chat Model 抽象

需要掌握：

| 内容                                   | 你要会到什么程度                                           |
| -------------------------------------- | ---------------------------------------------------------- |
| `ChatOpenAI` / OpenAI compatible model | 能接 DeepSeek、Qwen、SiliconFlow、OpenRouter、蓝心兼容接口 |
| **message 格式**                       | 会区分 system / user / assistant / tool message            |
| temperature / max_tokens / timeout     | 会为不同任务**设置参数**                                   |
| **model routing**                      | 会**根据任务选择蓝心或其他模型**                           |
| **fallback model**                     | 主模型失败**后自动切备用模型**                             |

你项目里模型不能写死。你应该封装成：

```text
ModelProvider
  - OpenAICompatibleProvider
  - LanxinProvider
  - MockProvider
```

蓝心大模型只处理适合它能力的任务，其他复杂推理或更强模型需求走 OpenAI 兼容模型。你的 PRD 技术架构也强调端云协同：端侧负责隐私记忆和画像读取，云端模型负责复杂规划、多模态理解、长文案生成和复杂推理，外部工具负责地图、天气、地点和照片等能力。fileciteturn0file1

---

## 1.2 Prompt Template

需要掌握：

| 内容              | 你要会到什么程度                           |
| ----------------- | ------------------------------------------ |
| System Prompt     | 写蓝小心人格、行为边界、隐私规则           |
| Task Prompt       | 记忆抽取、规划、复盘、文案生成分别写       |
| Few-shot examples | 给模型几个正确 JSON 输出样例               |
| Dynamic Prompt    | 根据用户画像、旅行阶段、主动程度拼接上下文 |
| Prompt versioning | 后续用 LangSmith 或本地文件管理版本        |

你项目里 Prompt 不应该散落在代码里，应该放成：

```text
services/api/app/agents/travelmate/prompts/
  lanxiaoxin_persona.md
  memory_extract.md
  trip_plan.md
  trip_adjust.md
  reminder_check.md
  photo_analyze.md
  copywriting.md
  review_generate.md
```

---

## 1.3 Structured Output

这是必须学的重点。

你要会：

| 内容           | 作用                                          |
| -------------- | --------------------------------------------- |
| Pydantic Model | 约束模型输出结构                              |
| JSON Schema    | 让前后端稳定对接                              |
| 输出修复       | 模型返回非法 JSON 时自动修复或重试            |
| 字段默认值     | 防止前端空字段崩溃                            |
| 枚举约束       | 限制 `avatarState`、`cardType`、`memoryScope` |

比如记忆抽取不能让模型自由发挥，必须输出：

```text
memoryCandidates: [
  {
    content: "不吃香菜",
    category: "diet",
    suggestedScope: "long_term",
    confidence: 0.92,
    reason: "以后推荐餐厅时需要避开香菜"
  }
]
```

你的原型里记忆胶囊页面要求展示识别内容、建议保存方式、用途说明，并让用户选择长期、本次、当前对话、不记住、编辑后保存。fileciteturn0file2 这类 UI 必须依赖稳定结构化输出。

---

## 1.4 Tool Calling

需要掌握：

| 内容                | 你要会到什么程度                                  |
| ------------------- | ------------------------------------------------- |
| tool schema         | 为天气、POI、路线、照片分析、ASR/TTS 定义输入输出 |
| tool selection      | 让模型判断什么时候调用工具                        |
| forced tool call    | 某些节点强制调用天气/路线工具                     |
| parallel tool call  | 天气、POI、路线可并行                             |
| tool error handling | API 失败时用 Mock 或缓存兜底                      |
| tool trace          | 记录每一步调用，方便比赛展示                      |

你项目最重要的工具包括：

```text
weather_tool
poi_search_tool
route_summary_tool
navigation_link_tool
photo_analyze_tool
asr_tool
tts_tool
memory_search_tool
profile_read_tool
profile_update_tool
```

---

## 1.5 LangChain 里暂时不用深入的内容

下面这些你现在可以不学或只知道名字：

| 内容                      | 原因                                      |
| ------------------------- | ----------------------------------------- |
| 旧版 `Chain` / `LLMChain` | 很多已经不是主流写法，容易学乱            |
| `AgentExecutor` 深入源码  | 你主流程用 LangGraph，不靠它              |
| 旧版 Memory 类            | 你的记忆系统要自研结构化记忆              |
| LangServe                 | 你已经有 FastAPI，不需要优先学            |
| 大量第三方 loader         | 旅行项目短期用不到那么多文档源            |
| CrewAI / AutoGen          | 你的流程是产品型 Agent，不是多 Agent 群聊 |

---

# 2. LangGraph 你还需要学什么

LangGraph 是你这项目最需要重点补的。官方把 LangGraph 定位为 orchestration runtime，强调 durable execution、streaming、human-in-the-loop 和 persistence。citeturn641655search0 这些刚好对应你的记忆胶囊确认、旅行规划中断恢复、主动提醒、用户确认保存范围等需求。

## 2.1 State 设计

你必须学会设计一个稳定的 `TravelMateState`。

需要掌握：

| 内容                       | 用途                                     |
| -------------------------- | ---------------------------------------- |
| TypedDict / Pydantic State | 定义图中流转的数据结构                   |
| State 字段拆分             | 区分用户输入、上下文、工具结果、最终响应 |
| Reducer                    | 多节点更新同一字段时如何合并             |
| MessagesState              | 是否用消息历史作为短期上下文             |
| State 最小化               | 不要把所有无关数据都塞进状态             |

你项目的 State 至少要包含：

```text
user_id
session_id
trip_id
input_type
user_message
destination
trip_context
user_profile
memory_candidates
tool_results
plan_result
reminder_result
photo_analysis_result
copywriting_result
review_result
avatar_state
cards
reply_text
next_actions
tool_trace
errors
```

---

## 2.2 Node 设计

你需要会把业务拆成 LangGraph 节点。

必须掌握：

| 节点类型       | 项目对应                            |
| -------------- | ----------------------------------- |
| 输入标准化节点 | 处理文字、语音、图片、按钮动作      |
| 上下文加载节点 | 读取画像、记忆、旅行状态            |
| 意图路由节点   | 判断规划、记忆、照片、复盘等任务    |
| 工具规划节点   | 判断要调用天气、POI、路线、照片分析 |
| 工具执行节点   | 调真实 API 或 Mock                  |
| 结果生成节点   | 生成规划、提醒、文案、复盘          |
| 状态映射节点   | 把 Agent 状态映射到蓝小心动作       |
| 响应组装节点   | 输出前端需要的统一 JSON             |
| 错误兜底节点   | 失败时返回可用结果                  |

你的第一版总图可以是：

```text
input_normalizer
→ context_loader
→ intent_router
→ memory_extractor / trip_planner / photo_analyzer / review_generator
→ avatar_state_mapper
→ response_composer
```

之后再逐步补：

```text
tool_planner
tool_executor
reminder_checker
copywriter
memory_writer
profile_updater
```

---

## 2.3 Edge / Conditional Edge

你要学会：

| 内容             | 用途                                 |
| ---------------- | ------------------------------------ |
| `START` / `END`  | 图的开始和结束                       |
| 普通 edge        | 固定流程                             |
| conditional edge | 根据 intent 分发到不同节点           |
| router function  | 用函数决定下一步                     |
| 多分支合流       | 不同任务最后都回到 response_composer |
| 错误分支         | 失败进入 error_fallback              |

你项目中典型分支是：

```text
intent == "memory_confirm" → memory_writer
intent == "trip_plan" → tool_planner → trip_planner
intent == "trip_adjust" → tool_planner → trip_adjuster
intent == "photo_upload" → photo_analyzer
intent == "copywriting" → copywriter
intent == "review" → review_generator
intent == "chat" → persona_chat
```

---

## 2.4 Interrupt / Human-in-the-loop

这是你项目的核心必学项。

LangGraph 的 interrupts 可以暂停图执行，等待外部输入后继续；官方说明它会通过持久化层保存图状态，并等待 resume。citeturn641655search11

你要把它用于：

| 场景           | 为什么需要 interrupt             |
| -------------- | -------------------------------- |
| 记忆胶囊确认   | 用户决定长期、本次、临时、不记忆 |
| 记忆冲突处理   | 用户决定覆盖旧记忆还是并存       |
| 路线调整确认   | 用户选择方案 A/B/C               |
| 照片加入候选集 | 用户确认是否加入                 |
| 社交文案发布前 | 用户确认复制/保存，不自动发布    |

你要学到能实现这种流程：

```text
memory_extractor
→ 生成 memory_candidates
→ interrupt 等用户确认
→ memory_writer
→ profile_updater
→ response_composer
```

---

## 2.5 Persistence / Checkpointer

你需要学：

| 内容                  | 用途                   |
| --------------------- | ---------------------- |
| MemorySaver           | 本地开发快速测试       |
| SQLite checkpointer   | 单机部署可用           |
| Postgres checkpointer | 正式部署更稳           |
| thread_id             | 区分用户、会话、旅行   |
| resume                | 用户确认后继续原图执行 |
| 状态恢复              | App 断线后恢复流程     |

LangGraph 的 persistence 文档说明，checkpointer 支持 human-in-the-loop，因为用户需要在任意点查看图状态，图也要在用户更新状态后继续执行。citeturn641655search4

对你项目来说，`thread_id` 不能乱设计。建议：

```text
thread_id = "{user_id}:{trip_id}:{session_id}"
```

游客模式可以：

```text
thread_id = "guest:{device_id}:{session_id}"
```

---

## 2.6 Streaming

你前面说普通聊天要流式，规划/复盘可以不完全流式。

需要学：

| 内容                       | 用途                               |
| -------------------------- | ---------------------------------- |
| token streaming            | 普通聊天逐字输出                   |
| event streaming            | 前端展示“正在查天气”“正在规划路线” |
| node streaming             | 展示当前执行到哪个节点             |
| final response             | 最终结构化卡片                     |
| Flutter SSE/WebSocket 接入 | App 端展示进度                     |

你的项目可以这样做：

```text
普通聊天：token streaming
旅行规划：event streaming + 最终卡片
旅行复盘：event streaming + 最终卡片
照片分析：进度提示 + 最终结果
```

---

## 2.7 Subgraph

你现在问过“先单图还是直接完整”。这里的正确学习目标是：**先会单图完整流程，再学子图拆分**。

LangGraph 官方支持 subgraphs，用于将复杂流程拆成更小的图；文档也提到子图可以继承父图 checkpointer，从而支持中断和持久执行。citeturn641655search25

你后续要能拆：

```text
TravelMateGraph
  MemorySubgraph
  TripPlanningSubgraph
  ReminderSubgraph
  PhotoSubgraph
  ReviewSubgraph
```

但第一版不要急着写五个子图。第一版应该是：

```text
一个 TravelMateGraph
节点按模块命名
目录结构预留 subgraphs
后续稳定后再抽
```

---

## 2.8 Graph 测试

你必须学会测试 LangGraph，不然后期很难 debug。

需要掌握：

| 测试类型       | 示例                                            |
| -------------- | ----------------------------------------------- |
| 单节点测试     | 输入一句话，`memory_extractor` 是否抽出正确记忆 |
| 路由测试       | “帮我规划路线”是否进入 trip_planner             |
| 工具 Mock 测试 | 天气 API 失败是否使用 Mock                      |
| 中断测试       | 记忆胶囊是否真的停在确认节点                    |
| 端到端测试     | 输入旅行需求，最终是否返回 cards 和 avatarState |
| 回归测试       | 改 prompt 后旧测试样例不能明显变差              |

---

# 3. RAG 你还需要学什么

RAG 要学，但你不要一开始就搞复杂。你的项目最核心不是知识库问答，而是**结构化记忆 + 工具实时信息 + 轻量检索**。

LangChain 官方 RAG 文档把 RAG 分成两类常见做法：一种是 RAG agent，让模型决定是否搜索；另一种是两步 RAG chain，用一次检索加一次模型调用，适合简单问题。citeturn641655search1 你项目里两种都会用到，但优先级不同。

## 3.1 先搞清楚 RAG 和 Memory 的区别

| 概念                | 在你项目里的作用                                   |
| ------------------- | -------------------------------------------------- |
| Memory              | 用户偏好、旅行画像、历史互动、关系成长             |
| RAG                 | 检索攻略、地点介绍、历史旅行记录、照片文案素材     |
| Tool                | 获取实时天气、POI、路线、导航链接                  |
| Context Engineering | 决定本次模型调用到底塞哪些记忆、工具结果和历史摘要 |

你的长期记忆不要一开始全丢进向量库。比如“不吃香菜”“喜欢夜景”“不想太累”应该是结构化字段，而不是单纯 embedding。

---

## 3.2 结构化记忆

这是 P0 必学。

你要学：

| 内容         | 用途                                   |
| ------------ | -------------------------------------- |
| 记忆分类     | 饮食、节奏、交通、兴趣、预算、表达风格 |
| 生命周期     | 长期、本次旅行、当前会话、不记忆       |
| 冲突处理     | 旧记忆和新记忆矛盾时询问用户           |
| 置信度       | 低置信度不自动保存                     |
| 用户确认     | 所有长期记忆必须用户确认               |
| 可删除可编辑 | 隐私可控核心                           |

PRD 里记忆胶囊规则已经明确分为长期记忆、本次旅行记忆、临时对话信息和不记忆，并且用户可选择保存范围。fileciteturn0file1

---

## 3.3 短期记忆 / 对话摘要

需要学：

| 内容                 | 用途               |
| -------------------- | ------------------ |
| conversation summary | 长对话压缩         |
| session memory       | 当前聊天上下文     |
| trip memory          | 当前旅行阶段上下文 |
| token budget         | 控制上下文长度     |
| summary update       | 每 N 轮更新摘要    |

LangGraph memory 文档也说明短期记忆通常是 thread-scoped memory，作为 agent state 的一部分，并通过 checkpointer 持久化，以便线程恢复。citeturn641655search32

---

## 3.4 向量检索基础

P1 再做，但你现在要知道：

| 内容            | 要学到什么程度                           |
| --------------- | ---------------------------------------- |
| embedding       | 知道文本怎么转向量                       |
| vector store    | 会用 Chroma / Qdrant / pgvector 任选一个 |
| chunking        | 知道攻略文本、历史复盘怎么切块           |
| metadata filter | 按用户、旅行、地点、时间过滤             |
| top_k           | 控制返回多少条                           |
| rerank          | 后续提高准确率                           |
| hybrid search   | 关键词 + 向量，后期再学                  |

对你项目，向量库适合存：

```text
历史旅行复盘
用户长对话摘要
目的地攻略知识
景点介绍
拍照文案素材
本地向导知识
```

不适合优先存：

```text
不吃香菜
喜欢夜景
预算有限
不想太累
```

这些应该结构化。

---

## 3.5 Agentic RAG

这个可以 P1 学。LangGraph 官方有 custom RAG agent 指南，说明当你需要模型自己决定“是否检索向量库还是直接回答”时，就可以用 retrieval agent；如果需要更深定制，可以直接用 LangGraph 实现。citeturn641655search5

你项目里适合用 Agentic RAG 的场景：

| 场景                             | 是否需要 RAG         |
| -------------------------------- | -------------------- |
| “给我讲讲这个景点有什么冷知识”   | 需要                 |
| “基于我以前旅行风格推荐相似路线” | 需要                 |
| “根据我历史复盘总结我喜欢什么”   | 需要                 |
| “天气怎么样”                     | 不需要，用天气工具   |
| “附近有什么餐厅”                 | 不需要，用 POI 工具  |
| “我不吃香菜以后记住”             | 不需要，用结构化记忆 |

---

## 3.6 RAG 评估

你要学会最基本的评估指标：

| 指标               | 用途                         |
| ------------------ | ---------------------------- |
| retrieval recall   | 应该被检索到的信息有没有拿到 |
| precision          | 检索出来的内容是否相关       |
| groundedness       | 回答是否基于检索内容         |
| hallucination rate | 是否乱编景点/路线            |
| citation coverage  | 输出是否能解释来源           |
| latency            | 检索和生成耗时               |

---

# 4. LangSmith 你还需要学什么

LangSmith 是你后期调 Agent 的关键，但不是第一天就必须深度学。官方文档说 LangSmith 是框架无关的平台，用来构建、调试、部署 AI agent 和 LLM 应用，可以 trace requests、evaluate outputs、test prompts、manage deployments。citeturn641655search13

## 4.1 Tracing

你需要学：

| 内容                        | 用途                         |
| --------------------------- | ---------------------------- |
| trace 一次 Agent 调用       | 看完整执行链路               |
| 查看每个节点输入输出        | Debug LangGraph              |
| 查看 tool call              | 检查高德/天气/POI 是否被调用 |
| 查看 token / latency / cost | 优化性能                     |
| 查看异常节点                | 快速定位失败原因             |

对你项目最有价值的是能看到：

```text
用户输入
→ intent_router
→ memory_extractor
→ interrupt
→ memory_writer
→ trip_planner
→ weather_tool
→ poi_tool
→ response_composer
```

这对比赛展示也有帮助，因为复赛/决赛要求体现大模型 API 实际调用和大模型应用能力。比赛材料中复赛要求提交更完善的策划文档、可运行版本，并展示对大模型矩阵 API 的实际调用；评分也包含大模型应用能力维度。fileciteturn0file3

---

## 4.2 Dataset

你需要学：

| 数据集         | 示例                                                  |
| -------------- | ----------------------------------------------------- |
| 记忆抽取测试集 | “我不吃香菜” → 应抽出饮食偏好                         |
| 规划测试集     | “重庆两天，喜欢夜景，不想太累” → 应生成慢节奏夜景路线 |
| 主动提醒测试集 | “排队60分钟，用户喜欢夜景” → 应提醒改路线             |
| 文案测试集     | 一张夜景照片 → 朋友圈/小红书文案                      |
| 复盘测试集     | 一天事件列表 → 复盘卡                                 |

你不需要一开始做几百条，先做 20-50 条高质量 case 就够。

---

## 4.3 Evaluation

你要学：

| 评估类型        | 项目对应                       |
| --------------- | ------------------------------ |
| exact match     | JSON 字段是否存在              |
| LLM-as-judge    | 规划是否符合用户偏好           |
| rule-based eval | 是否引用了记忆、是否有风险提示 |
| regression eval | 改 prompt 后效果是否退化       |
| human feedback  | 队友手动打分                   |

最重要的评估不是“回答好不好看”，而是：

```text
是否正确抽取记忆
是否等待用户确认
是否把记忆用于规划
是否调用了真实工具
是否给出可执行路线
是否没有越权保存隐私
```

---

## 4.4 Prompt 版本管理

需要学：

| 内容            | 用途                    |
| --------------- | ----------------------- |
| prompt version  | 改 Prompt 后能回滚      |
| prompt A/B      | 对比两个记忆抽取 Prompt |
| prompt metadata | 记录模型、参数、版本    |
| bad case 归档   | 收集失败样例            |

---

## 4.5 LangSmith 暂时不用深入的内容

| 内容             | 原因                          |
| ---------------- | ----------------------------- |
| 复杂线上监控面板 | 你们还没到生产规模            |
| 企业级权限管理   | 三人队伍暂不需要              |
| 大规模自动评估   | 先小样本手工 + 半自动         |
| 部署平台绑定     | 你们后端还是 FastAPI + Docker |

---

# 5. Context Engineering 你需要重点补

这个比“会不会 LangChain API”更重要。LangChain 官方也强调 context engineering，即为 AI 应用提供正确的信息和工具，并以正确格式提供给模型。citeturn641655search26

你要学：

## 5.1 上下文分层

| 上下文   | 来源                       | 作用                     |
| -------- | -------------------------- | ------------------------ |
| 系统人格 | `lanxiaoxin_persona.md`    | 控制蓝小心语气和边界     |
| 用户画像 | SQLite/PostgreSQL          | 个性化推荐               |
| 本次旅行 | trip_context               | 当前目的地、预算、同行人 |
| 当前事件 | location/time/photo/action | 主动提醒和判断           |
| 工具结果 | 天气/POI/路线              | 真实信息                 |
| 对话摘要 | chat_summary               | 保持上下文               |
| 安全规则 | privacy policy             | 防止自动保存/自动发布    |

---

## 5.2 上下文选择

你要学会不是把所有东西都塞给模型，而是按任务选择：

| 任务     | 应该给模型什么                                   |
| -------- | ------------------------------------------------ |
| 记忆抽取 | 最近用户输入 + 当前旅行上下文 + 记忆分类规则     |
| 规划     | 用户画像 + 目的地 + 时间 + 天气 + POI + 路线约束 |
| 主动提醒 | 当前事件 + 原计划 + 用户主动程度 + 用户画像      |
| 文案生成 | 照片标签 + 地点 + 用户文案风格 + 本次情绪        |
| 复盘     | 行程节点 + 照片 + 新增记忆 + 蓝小心状态变化      |

---

## 5.3 模型路由

你要学：

| 任务         | 推荐模型选择               |
| ------------ | -------------------------- |
| 简单意图识别 | 小模型 / 规则              |
| 记忆抽取     | 蓝心或较稳的结构化输出模型 |
| 复杂规划     | 更强 OpenAI 兼容模型       |
| 角色化陪聊   | 蓝心或便宜模型             |
| 图片理解     | 蓝心多模态或视觉模型       |
| 文案生成     | 蓝心 / 通用大模型          |
| ASR/TTS      | 蓝心语音能力或系统兜底     |

你的开发资源里也列出了语言大模型、图片生成、OCR、短语音识别、长语音转写、语音合成、声音复制等能力，这些能力可以映射到蓝心同行的语音输入、语音播报、旅拍理解和文案生成。fileciteturn0file4

---

# 6. 工具系统你需要补什么

这是你项目能不能“像产品”的关键。

## 6.1 Tool Schema 设计

每个工具都要有：

```text
name
description
input_schema
output_schema
timeout
retry_policy
fallback
cache_policy
tool_trace
```

比如天气工具：

```text
input:
  destination
  date

output:
  weather
  temperature
  rain_probability
  risk_level
  suggestion
```

---

## 6.2 高德地图相关能力

你要学：

| 能力         | 项目用途               |
| ------------ | ---------------------- |
| 地理编码     | 用户输入目的地转经纬度 |
| 逆地理编码   | 经纬度转地点名         |
| POI 搜索     | 找景点、餐厅、休息点   |
| 天气查询     | 判断雨天、高温、低温   |
| 路线规划     | 生成两点间路线摘要     |
| 导航跳转 URI | 跳转外部地图 App       |

---

## 6.3 工具降级

每个工具必须有 Mock。

| 工具失败      | 降级                   |
| ------------- | ---------------------- |
| 天气 API 失败 | 使用 mock_weather.json |
| POI API 失败  | 使用 mock_poi.json     |
| 路线 API 失败 | 输出文本规划           |
| 图片理解失败  | 用户手动输入标签       |
| ASR 失败      | 让用户改用文字         |
| TTS 失败      | 系统 TTS 或只显示文本  |

这符合你仓库对 vibe coding 的约束：真实 API、地图、照片权限、模型调用都应先提供模拟数据或降级实现，确保 Demo 可控。fileciteturn0file0

---

# 7. Agent 工程化你需要补什么

## 7.1 FastAPI + LangGraph 集成

你要学：

| 内容                   | 用途                                   |
| ---------------------- | -------------------------------------- |
| FastAPI 路由设计       | `/api/agent/chat`、`/api/agent/action` |
| async 调用             | 模型和工具 API 不阻塞                  |
| SSE                    | 普通聊天流式输出                       |
| request_id             | 追踪每次请求                           |
| user/session/trip 绑定 | 保证状态隔离                           |
| exception handler      | 模型失败不让服务崩                     |
| Swagger                | 队友调试接口                           |

---

## 7.2 生产级配置

你要学：

| 内容              | 用途                  |
| ----------------- | --------------------- |
| `.env`            | 管理 API Key          |
| pydantic-settings | 配置管理              |
| rate limit        | 防止 API 额度爆       |
| timeout           | 防止请求卡死          |
| retry             | 短暂失败自动重试      |
| circuit breaker   | 某模型不可用时切备用  |
| cache             | 天气/POI/TTS 结果缓存 |
| loguru            | 统一日志              |
| Docker Compose    | 后端部署              |

你的服务器是 2C2G，只适合做后端托管和 API 编排，不适合跑大模型推理。所以你要重点学**轻量部署、缓存、超时、降级**，不是学本地大模型部署。

---

## 7.3 前后端协议

你要学会设计统一响应：

```text
replyText
voiceText
avatarState
emotion
cards
memoryCandidates
toolTrace
nextActions
syncSuggestions
errors
```

重点是 `cards` 的 schema。比如：

```text
card.type = memory_capsule
card.type = trip_plan
card.type = reminder
card.type = photo_candidate
card.type = review
```

这样 Flutter 只根据 card type 渲染，不需要理解 Agent 内部逻辑。

---

# 8. 你应该补的 RAG 工程细节

## 8.1 文档加载

P1 再学：

| 来源           | 用途                 |
| -------------- | -------------------- |
| 攻略 markdown  | 目的地冷知识         |
| 景点介绍 JSON  | 景点讲解             |
| 历史复盘       | 长期旅行风格         |
| 用户文案历史   | 模仿用户语气         |
| 本地向导知识库 | 生成更自然的路线解释 |

---

## 8.2 切分策略

需要知道：

| 内容类型 | 切法                 |
| -------- | -------------------- |
| 景点介绍 | 一个景点一块         |
| 攻略文章 | 按标题和段落切       |
| 历史复盘 | 按旅行天数/节点切    |
| 用户文案 | 一条文案一块         |
| 对话历史 | 先摘要，再按主题归档 |

---

## 8.3 Metadata

这是旅行 RAG 的重点。

每条向量记录要带：

```text
user_id
trip_id
destination
destination_type
time
source_type
memory_scope
privacy_level
tags
```

否则后期会出现“拿错用户记忆”“拿错城市攻略”“把私人记忆用于云端”的问题。

---

## 8.4 RAG 在你项目里的落地顺序

| 阶段 | 做什么                                              |
| ---- | --------------------------------------------------- |
| P0   | 不上向量库，只做结构化记忆 + 对话摘要               |
| P1   | 加一个小型本地/后端知识库，用于景点冷知识和历史复盘 |
| P2   | 加 pgvector / Chroma / Qdrant                       |
| P3   | 做 Agentic RAG，让 Agent 判断是否检索               |

---

# 9. 你需要补的 LangSmith 具体操作

按项目最小可用标准，你要会：

## 9.1 本地接入 tracing

目标：

```text
每次 /api/agent/chat 都能在 LangSmith 看到完整 trace
```

要看清：

```text
输入是什么
走了哪个节点
调用了哪个模型
调用了哪个工具
返回了什么
耗时多久
花了多少 token
哪里失败
```

## 9.2 建立测试数据集

至少建这些数据集：

```text
memory_extraction_cases
trip_planning_cases
reminder_cases
photo_copywriting_cases
review_generation_cases
```

## 9.3 写评估器

先写简单规则：

```text
记忆抽取结果必须包含 content/category/scope
规划结果必须包含 route/reason/profileMatches/risks
提醒结果必须包含 trigger/reason/options
复盘结果必须包含 routeSummary/newMemories/suggestions
```

后续再加 LLM judge。

---

# 10. 你需要补的安全和隐私知识

你的产品有“记忆”和“相册”，所以必须会基本隐私工程。

需要学：

| 内容         | 用途                        |
| ------------ | --------------------------- |
| 数据最小化   | 不把无关内容传云端          |
| 本地优先     | 游客模式记忆不上云          |
| 用户确认     | 长期记忆必须确认            |
| 逐条同步     | 用户决定哪些记忆上云        |
| 敏感信息识别 | 身体状态、私人偏好更高确认  |
| 删除机制     | 清空本次旅行 / 清空全部记忆 |
| 日志脱敏     | 不把用户隐私打进日志        |
| 图片权限     | 只处理用户选择/拍摄照片     |

PRD 也明确：位置、相册、相机、麦克风、通知、本地存储都要明示用途、可关闭；相册优先使用用户选择的照片，不默认全量读取；长期记忆不默认保存，用户可查看、编辑、删除。fileciteturn0file1

---

# 11. 你需要补的多模态知识

不需要学多模态模型原理太深，先学工程接入。

## 11.1 图片理解

需要会：

| 内容         | 用途                       |
| ------------ | -------------------------- |
| 图片上传     | Flutter → FastAPI          |
| 图片压缩     | 降低带宽和费用             |
| 图片标签生成 | 夜景、美食、人像、街景     |
| 图片质量评分 | 是否适合分享               |
| 文案上下文   | 图片标签 + 地点 + 用户风格 |
| 隐私确认     | 用户选择后才分析           |

---

## 11.2 语音

需要会：

| 内容         | 用途              |
| ------------ | ----------------- |
| 录音文件格式 | wav / m4a / mp3   |
| 上传音频     | Flutter → FastAPI |
| ASR          | 语音转文字        |
| TTS          | 回复转语音        |
| 播放缓存     | 避免重复生成      |
| 失败兜底     | 系统 TTS / 文字   |

---

# 12. 你需要补的模型选择和成本控制

因为你说蓝心只做适合的任务，服务器只做后端托管，所以必须学模型路由。

## 12.1 模型路由策略

| 任务     | 推荐                     |
| -------- | ------------------------ |
| 意图识别 | 规则 / 便宜小模型        |
| 记忆抽取 | 蓝心 / 稳定结构化模型    |
| 普通陪聊 | 蓝心 / 便宜模型          |
| 复杂规划 | 更强 OpenAI 兼容模型     |
| 图片理解 | 视觉模型，蓝心不稳则切换 |
| 文案生成 | 蓝心或通用模型           |
| 复盘生成 | 通用模型                 |
| ASR/TTS  | 蓝心语音或系统能力       |

---

## 12.2 成本控制

需要学：

| 技术         | 用途               |
| ------------ | ------------------ |
| prompt 压缩  | 少传无关上下文     |
| 对话摘要     | 降低历史 token     |
| 工具结果缓存 | 天气/POI 不重复查  |
| TTS 缓存     | 同一句话不重复合成 |
| 分级模型     | 简单任务用便宜模型 |
| 超时控制     | 防止请求挂住       |
| token 统计   | 估算成本           |

---

# 13. 你不需要现在学的东西

为了避免学散，下面这些先别碰太深：

| 内容                      | 现在不学的原因                         |
| ------------------------- | -------------------------------------- |
| 完整 LangChain 源码       | 投入大，短期收益低                     |
| 旧版 Chains 大量教程      | 容易学到过时模式                       |
| CrewAI / AutoGen 多 Agent | 你的产品不是多角色群聊                 |
| 大规模 RAG 优化           | 现在数据量很小                         |
| 模型微调                  | 比赛后期 vivo 可能支持，但现在不是主线 |
| 本地大模型部署            | 2C2G 服务器不适合                      |
| 全量相册后台监听          | 隐私和权限风险高                       |
| Live2D 工程               | 你现在先用 GIF/WebP/Lottie             |
| 复杂 MLOps                | 当前是应用赛，不是模型训练赛           |
| 企业级 LangSmith 部署     | 先用 tracing/eval 即可                 |

---

# 14. 推荐学习顺序

## 第 1 阶段：LangGraph 最小闭环

目标：能写出 `TravelMateGraph`。

学习内容：

1. State。
2. Node。
3. Edge。
4. Conditional edge。
5. START / END。
6. FastAPI 调用 graph。
7. 返回统一 JSON。
8. 单元测试一个节点。

完成标准：

```text
用户输入“我不吃香菜，喜欢夜景”
→ graph 路由到 memory_extractor
→ 返回 memoryCandidates
→ avatarState = thinking
```

---

## 第 2 阶段：Human-in-the-loop 和记忆胶囊

目标：做出记忆确认。

学习内容：

1. LangGraph interrupt。
2. Checkpointer。
3. thread_id。
4. resume。
5. 记忆写入。
6. 画像更新。
7. 冲突处理。

完成标准：

```text
抽取记忆
→ 暂停等待用户确认
→ 用户选择长期记住
→ 写入 user_profile
→ 下次规划能引用
```

---

## 第 3 阶段：工具系统

目标：接天气、POI、路线。

学习内容：

1. tool schema。
2. tool registry。
3. 高德天气。
4. 高德 POI。
5. 路线摘要。
6. tool trace。
7. fallback mock。
8. cache。

完成标准：

```text
用户说“明天去广州塔附近轻松玩半天”
→ 调天气
→ 调 POI
→ 调路线摘要
→ 生成规划卡
```

---

## 第 4 阶段：Context Engineering

目标：让模型“只看到该看的东西”。

学习内容：

1. 用户画像选择。
2. 旅行上下文选择。
3. 对话摘要。
4. 工具结果注入。
5. Prompt 分层。
6. 模型路由。
7. JSON 输出约束。

完成标准：

```text
同一个目的地
用户A喜欢夜景
用户B喜欢博物馆
输出规划明显不同
```

---

## 第 5 阶段：RAG 基础

目标：补攻略知识和历史复盘检索。

学习内容：

1. embedding。
2. vector store。
3. chunking。
4. metadata。
5. retriever。
6. rerank 概念。
7. RAG eval。

完成标准：

```text
用户问“这个景点有什么冷知识”
→ 检索知识库
→ 生成回答
→ 不乱编
```

---

## 第 6 阶段：LangSmith 调试评估

目标：能看懂 Agent 为什么失败。

学习内容：

1. tracing。
2. dataset。
3. evaluator。
4. prompt version。
5. token/cost/latency。
6. bad case 归档。
7. 回归测试。

完成标准：

```text
每次 Agent 调用都能看到完整执行路径
每次 Prompt 修改后能跑固定测试集
```

---

## 第 7 阶段：多模态和语音

目标：把旅拍和语音接入 Agent。

学习内容：

1. 图片上传。
2. 图片压缩。
3. 视觉模型调用。
4. 图片标签结构化输出。
5. 文案生成。
6. ASR。
7. TTS。
8. 系统 TTS 兜底。

完成标准：

```text
用户选择照片
→ Agent 分析标签
→ 生成朋友圈/小红书文案
→ 可加入复盘
```

---

# 15. 最终你应该掌握到什么程度

你不需要成为 LangChain 专家。你需要达到的是：

| 能力                | 达标标准                                                 |
| ------------------- | -------------------------------------------------------- |
| LangGraph           | 能设计、实现、调试 TravelMateGraph                       |
| LangChain           | 能用模型、Prompt、工具、结构化输出、检索组件             |
| RAG                 | 能做小型知识库和历史复盘检索                             |
| LangSmith           | 能 trace、评估、回归测试                                 |
| Tool Calling        | 能封装天气、POI、路线、语音、图片工具                    |
| Memory              | 能做结构化记忆、摘要、用户确认、隐私控制                 |
| Context Engineering | 能控制不同任务喂给模型的上下文                           |
| 工程化              | 能让 Agent 稳定跑在 FastAPI 后端，有降级、有日志、有测试 |

最贴合你当前项目的学习主线是：

**LangGraph 编排 → 记忆胶囊 human-in-the-loop → 工具调用 → 结构化输出 → Context Engineering → 轻量 RAG → LangSmith 调试评估 → 多模态/语音接入。**

你现在不要追求“把所有教程都学完”。你要围绕蓝心同行的 6 个核心页面和 3 分钟 Demo 闭环去学：你的原型已经明确了首页、记忆胶囊、规划、主动提醒、旅拍候选、旅行复盘这 6 个页面，正好对应你接下来要实现的 6 条 Agent 能力链路。fileciteturn0file2