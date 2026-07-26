# 公网 API 健康检查报告

> 检查时间：2026-07-26。结论：公网 API 全链路健康，此前初版报告中的“编码乱码”与“路由差异”均为误报，已更正。

## 检查结果概要

**API 服务全链路正常，无阻塞问题。**

| 检查项 | 结果 |
| --- | --- |
| 域名可达 | `https://api.rxcccccc.icu` 正常 |
| Swagger | `/docs` 200 OK |
| OpenAPI | `/openapi.json` 200 OK，42 个端点 |
| Guest 认证 | `POST /api/auth/guest` 200，返回 `accessToken` |
| Agent 聊天 | `POST /api/agent/chat` 200，全链路 8.3s |
| 中文编码 | 正常（UTF-8），此前乱码为本地控制台 GBK 显示问题 |
| 路由一致性 | 本地与公网一致，均为 `/api/agent/chat`（`api_prefix=/api`） |

## 真实链路验证（输入：“周末想去重庆两天，不想太累，喜欢夜景，我不吃香菜”）

- 记忆抽取：3 条候选，`mem-cilantro`（不吃香菜，longTerm）、`mem-night-view`（喜欢夜景，longTerm）、`mem-slow-pace`（本次轻松，currentTrip），id 与隐私元数据正确。
- 规划：`provider=openai fallback=false`，回复正确引用画像（避开香菜、夜景主线、轻松节奏），`avatarState=planning`。
- 高德天气：`provider=amap fallback=false`，重庆实时天气正常。
- 高德 POI：`provider=amap fallback=false`，返回洪崖洞、解放碑等 10 个真实夜景 POI。
- 路线工具：`fallback=true`（`missing_coordinates`），属预期降级——聊天入口未携带起终点坐标时走导航链接兜底，非缺陷。

## 遗留观察项（非阻塞）

1. 全链路耗时约 8.3s（含天气 + POI + 模型规划），纯闲聊约 2.5s；如需优化可考虑工具并行化或流式输出。
2. `route_tool` 在聊天场景固定缺坐标降级，可评估是否在有定位上报时补传坐标。
