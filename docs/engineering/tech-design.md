# 技术设计

## 架构概览

蓝心同行采用 Flutter App + FastAPI + LangGraph Agent 的端云协同结构。当前版本默认使用 Mock 模型 Provider，不依赖真实蓝心或 OpenAI 密钥；外部工具已接入高德 Provider 骨架，无 Key 时返回明确降级，确保比赛演示链路稳定可控。

## 前端

- Flutter 工程位于 `apps/mobile/`。
- `dio` 负责调用后端。
- Drift SQLite 负责端侧记忆胶囊持久化。
- `latestAgentResponse` 作为演示态，把聊天页返回的 Agent 卡片同步给规划、提醒、复盘页。
- 蓝小心状态由 `AvatarState` 枚举驱动，并映射到本地素材。

## 后端

- FastAPI 工程位于 `services/api/`。
- `uv` 管理 Python 环境。
- `/api/health` 提供健康检查。
- `/api/agent/chat` 运行 TravelMateGraph，并返回统一 camelCase 响应。
- SQLModel 模型文件预留云端用户、记忆、画像、行程、复盘、同步、模型调用、工具调用和上传文件表。
- 地图、天气、POI、步行路线已通过 `AmapToolProvider` 接入高德 HTTP 接口；无 `LANXIN_AMAP_API_KEY` 时返回 `provider=unconfigured`、`fallback=true` 和原因说明，不伪装真实数据。Provider 已具备进程内成功结果缓存与一次 HTTP 重试，规划卡仍保留高德外部导航 URI 供演示。

## Agent

TravelMateGraph 当前按固定顺序串联 19 个节点，覆盖输入归一化、上下文加载、意图识别、记忆提取、画像更新、工具调用、规划、提醒、旅拍、复盘、状态映射和响应组装。

真实模型接入前，模型规划仍可降级到 Mock；天气、POI、路线工具优先走真实注册器，未配置 Key 时返回显式 unconfigured fallback。

P1 阶段已补充记忆冲突处理：当长期偏好与本次行程约束冲突时，Agent 通过 `syncSuggestions` 提醒用户确认，不直接覆盖长期画像。

## 不做的能力

- 不实现 Live2D。
- 不实现后台无感相册监听。
- 不实现自动社交发布。
- 不在缺少 Key 时伪造真实地图、天气或大模型 API 结果。


## 真实数据与降级边界

系统现在区分三类结果：

1. 真实 Provider 结果：模型或高德工具已配置真实密钥，返回结构化结果且 schema/解析通过，`fallback=false`。
2. 明确降级结果：Provider 未配置、HTTP 失败、schema 无效或能力暂未接入，返回 `fallback=true`、`provider=unconfigured/mock` 或对应错误类型。
3. 本地持久化聚合结果：复盘、dashboard、记忆、画像、路线点、提醒历史、盲盒任务状态等来自 SQLModel/Drift 的真实用户数据，不依赖 Mock 样例。

模型侧已覆盖 `memory_extraction`、`trip_planning`、`photo_copywriting`、`trip_review`、`companion_chat` 五类结构化输出。工具侧高德天气、POI、路线支持真实 Provider 与无 Key 降级。比赛演示中只有第 1 类和第 3 类可以声明为真实链路；第 2 类只能作为可控降级能力展示。
