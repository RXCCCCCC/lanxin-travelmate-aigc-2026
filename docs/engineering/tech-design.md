# 技术设计

## 架构概览

蓝心同行采用 Flutter App + FastAPI + LangGraph Agent 的端云协同结构。当前版本默认使用 Mock Provider，不依赖真实蓝心或 OpenAI 密钥，确保比赛演示链路稳定可控。

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
- 地图、天气、POI 第一版采用可降级工具输出：返回 `provider` 和 `fallback` 元数据；无真实密钥时使用 Mock，规划卡仍提供高德外部导航 URI 供演示。

## Agent

TravelMateGraph 当前按固定顺序串联 19 个节点，覆盖输入归一化、上下文加载、意图识别、记忆提取、画像更新、工具调用、规划、提醒、旅拍、复盘、状态映射和响应组装。

真实模型接入前，所有模型和工具都走 Mock 降级。

P1 阶段已补充记忆冲突处理：当长期偏好与本次行程约束冲突时，Agent 通过 `syncSuggestions` 提醒用户确认，不直接覆盖长期画像。

## 不做的能力

- 不实现 Live2D。
- 不实现后台无感相册监听。
- 不实现自动社交发布。
- 不默认调用真实地图、天气或大模型 API。
