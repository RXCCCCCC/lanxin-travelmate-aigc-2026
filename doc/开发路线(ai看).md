请根据以下要求为“蓝心同行”项目搭建完整开发工程骨架。项目是第三届 2026 AIGC 创新赛应用赛道作品，产品定位是“懂你的全旅程 AI 旅游搭子”，最终形态是 Android / vivo 手机上运行的 Flutter App + FastAPI + LangGraph Agent 后端。

一、总体要求

1. 使用 monorepo 结构。
2. 创建 Flutter 移动端工程。
3. 创建 FastAPI 后端工程。
4. 后端使用 uv 管理 Python 环境。
5. 后端预留 LangGraph Agent 架构。
6. 前端预留蓝小心数字人状态机。
7. 不要一次性实现全部业务，先搭可扩展骨架。
8. 所有真实 API 都必须有 Mock 降级。
9. 项目必须适合三人协作和后续 vibe coding。
10. 修改完成后补充 README、开发命令和验收步骤。

二、目标仓库结构

lanxin-travelmate/
apps/
mobile/
services/
api/
assets/
avatar/
docs/
mock/
infra/
.github/
workflows/

三、Flutter App 要求

技术栈：

* Flutter + Dart
* go_router
* Riverpod
* dio
* drift + SQLite
* shared_preferences
* flutter_secure_storage
* freezed + json_serializable
* image_picker
* camera
* record
* just_audio
* flutter_local_notifications
* geolocator
* permission_handler
* lottie

请创建以下目录：

apps/mobile/lib/
main.dart
app.dart
core/
router/
theme/
constants/
network/
storage/
features/
auth/
home/
chat/
avatar/
memory/
profile/
trip/
reminder/
photo/
review/
settings/
data/
local/
remote/
repositories/
shared/
widgets/
models/

第一阶段只需要实现：

1. App 可启动。
2. 首页有上半屏蓝小心区域，下半屏聊天区域。
3. 支持 AvatarState 枚举：idle、hello、thinking、planning、warning、excited、tired、happy、speaking。
4. 支持根据状态切换本地素材。
5. 支持静态聊天消息展示。
6. 支持基础卡片组件：MemoryCapsuleCard、TripPlanCard、ReminderCard、PhotoCandidateCard、TripReviewCard。
7. 支持游客模式入口和登录入口占位页。
8. 支持基础路由跳转。

四、FastAPI 后端要求

技术栈：

* FastAPI
* uv
* Pydantic
* SQLModel 或 SQLAlchemy
* LangGraph
* httpx
* loguru
* pytest
* pydantic-settings

请创建以下目录：

services/api/app/
main.py
core/
config.py
logging.py
security.py
api/
routes/
auth.py
agent.py
memory.py
profile.py
trip.py
tools.py
audio.py
photo.py
db/
session.py
models.py
schemas/
services/
model_providers/
tools/
sync/
agents/
travelmate/
graph.py
state.py
nodes/
prompts/
tests/

第一阶段只需要实现：

1. FastAPI 可启动。
2. Swagger 可打开。
3. `/api/health` 返回状态。
4. `/api/agent/chat` 返回统一 Mock 响应。
5. 创建 TravelMateState。
6. 创建 TravelMateGraph 骨架。
7. 创建节点占位：

   * input_normalizer
   * context_loader
   * intent_router
   * memory_extractor
   * memory_confirm_interrupt
   * memory_writer
   * profile_updater
   * trip_context_builder
   * tool_planner
   * tool_executor
   * trip_planner
   * trip_adjuster
   * reminder_checker
   * photo_analyzer
   * copywriter
   * review_generator
   * avatar_state_mapper
   * response_composer
   * error_fallback
8. 创建模型适配器接口：

   * MockModelProvider
   * OpenAICompatibleProvider
   * LanxinModelProvider
9. 创建工具注册器：

   * weather_tool
   * poi_tool
   * route_tool
   * navigation_link_tool
   * asr_tool
   * tts_tool
   * photo_analyze_tool
10. 工具第一阶段都可以返回 mock 数据。

五、统一 Agent 响应结构

后端 `/api/agent/chat` 必须返回类似结构：

{
"replyText": "...",
"voiceText": "...",
"avatarState": "thinking",
"emotion": "curious",
"cards": [],
"memoryCandidates": [],
"toolTrace": [],
"nextActions": [],
"syncSuggestions": [],
"errors": []
}

六、数据库要求

先建立模型文件和迁移预留，不要求全部业务写完。

端侧需要预留：

* local_users
* memory_capsules
* user_profiles
* trip_contexts
* chat_messages
* chat_summaries
* avatar_states
* reminders
* photo_candidates
* trip_reviews

后端需要预留：

* users
* auth_credentials
* cloud_memories
* cloud_user_profiles
* cloud_trips
* cloud_trip_reviews
* sync_records
* model_call_logs
* tool_call_logs
* uploaded_files

七、CI/CD 要求

先创建 GitHub Actions：

1. Flutter analyze。
2. Flutter test。
3. Python pytest。
4. 后端 Docker build。
5. Android APK 构建工作流可以先写占位或手动触发。

八、Docker 要求

在 infra/ 或根目录创建 Docker Compose：

* api
* postgres
* nginx 占位

第一阶段可以只保证 api + postgres 能启动。

九、开发文档要求

请创建或更新：

* README.md
* docs/tech-design.md
* docs/dev-roadmap.md
* docs/api-contract.md
* docs/agent-graph.md
* docs/contribution.md

文档中必须说明：

1. 如何启动 Flutter。
2. 如何启动 FastAPI。
3. 如何运行测试。
4. 如何添加一个新的 LangGraph 节点。
5. 如何添加一个新的工具。
6. 如何添加一个新的蓝小心状态。
7. 如何进行分支开发。
8. 如何验收第一阶段成果。

十、第一阶段验收标准

完成后必须满足：

1. `flutter run` 可以启动 App。
2. App 能看到蓝小心区域和聊天区域。
3. 点击测试按钮可以切换蓝小心状态。
4. FastAPI 可以启动。
5. Swagger 可以访问。
6. `/api/agent/chat` 可以返回 Mock Agent 响应。
7. Flutter 可以请求后端并展示回复。
8. GitHub Actions 至少能执行基础检查。
9. README 里有完整运行步骤。
10. 不引入不必要的大型 UI 框架，不实现 Live2D，不实现后台相册监听，不实现自动社交发布。
