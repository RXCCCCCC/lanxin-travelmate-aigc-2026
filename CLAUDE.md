# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目定位

本仓库用于第三届（2026）AIGC创新赛应用赛道，目前处于PRD修改与优化阶段。当前核心产物是面向初赛的产品策划、技术方案、原型说明和后续MVP规划，而不是已成型的软件工程代码库。

产品方向是“蓝心同行：懂你的全旅程AI旅游搭子”，一个面向移动终端出行场景的个性化AI Agent。核心差异点是长期记忆、可控隐私、主动陪伴、2D形象化表达和完整旅程闭环。

## 当前仓库结构

- `docs/todo.md`：全项目未完成待办总表，不仅是功能清单。
- `docs/product/PRD.md`：核心产品需求文档，包含产品定位、用户痛点、功能需求、技术架构、Demo剧本和里程碑。
- `docs/product/开发路线(ai看).md`：面向 AI 开发执行的工程骨架与验收要求。
- `docs/product/材料中有用的信息.md`：比赛资源、开发环境、蓝心大模型能力、快应用方案、提交清单和评分要点摘要。
- `docs/engineering/`：技术设计、开发路线、API 契约、Agent 图、素材索引和贡献说明。
- `docs/handoff/`：面向队友交接和人工阅读的说明材料。
- `材料/`：大赛宣讲PDF材料，包括AIGC创新赛介绍、蓝心大模型、蓝心九问平台、快应用平台。
- `prototype/mobile.html`：竖屏手机端静态原型，单文件HTML/CSS，使用 `project/img/` 下的蓝小心素材。
- `project/img/`：蓝小心角色图、表情状态图和后续原型素材。

## 常用命令

当前仓库根目录没有统一的 `package.json`、构建脚本、测试框架或lint配置；当前仓库也没有前端Demo工程。

当前可用的检查方式主要是文档与Git状态检查：

```bash
# 查看当前改动
git status --short

# 查看文档差异
git diff -- docs/product/PRD.md README.md .gitignore

# 查看仓库已跟踪文件
git ls-files
```

当前已有单文件手机端静态原型，可用本地静态服务预览：

```bash
python -m http.server 8765 --bind 127.0.0.1 --directory "e:/contest/C4/2026/AIGC"
# 浏览器打开 http://127.0.0.1:8765/prototype/mobile.html
```

素材维护约定：原始角色图和新增图片统一放在 `project/img/`。

当前没有单独测试框架；功能检查以浏览器移动端预览和演示链路点击为主。后续若恢复前端Demo工程，再补充对应的 lint/test/build 命令。

## 产品架构大图

PRD中的产品不是单点问答助手，而是“全旅程AI旅游搭子”。理解需求时优先按以下模块拆解：

1. 记忆胶囊与用户旅行画像
   - Agent识别可能影响旅行体验的信息；
   - 用户确认保存范围：长期记忆、本次旅行、当前会话、不记忆；
   - 保存后的画像影响规划、推荐、互动和文案生成。

2. 个性化出行规划引擎
   - 综合用户画像、本次旅行上下文、天气、时间、地点、同行人和外部工具；
   - 输出路线、推荐理由、画像匹配点、备选方案和风险提示；
   - 支持出行前规划和出行中动态调整。

3. 全旅程陪伴流
   - 出行前：规划、偏好确认、准备清单、搭子人格设定；
   - 出行中：主动提醒、路线调整、景点讲解、旅拍候选、盲盒任务；
   - 出行后：旅行复盘、照片整理、文案生成、记忆沉淀。

4. 主动情境对话
   - 触发来源包括时间、位置、行为、搭子状态、外部事件和旅行节点；
   - 必须可控，支持安静/标准/活跃/自定义主动程度；
   - 避免高频打扰用户。

5. 2D形象化搭子与自定义人格
   - MVP不强绑定Live2D；
   - 可从静态立绘、表情切换、预设动画逐步升级；
   - 人格影响对话语气、主动频率、盲盒任务、文案风格和状态表达。

6. 旅拍候选集与内容生成
   - 不承诺无确认自动发布；
   - 用户通过应用内拍照、系统照片选择器或授权最近照片加入候选集；
   - 生成朋友圈、小红书、日记、Vlog旁白等内容，发布前必须由用户确认。

7. 搭子状态、好感度与旅行盲盒
   - 搭子拥有精力、心情、好奇心、默契值、好感度等状态；
   - 状态随互动、行程、任务和照片变化；
   - 复盘中展示状态变化和共同经历。

## 技术方案边界

PRD当前采用端云协同Agent思路：

- 端侧/本地：隐私记忆、轻量规则、基础意图识别、用户画像读取、本地存储；
- 云端大模型：复杂规划、多模态理解、长文案生成、复杂推理；
- 外部工具：地图、天气、地点POI、照片选择、语音、分享能力；
- 表达层：2D搭子、语音、卡片和移动端UI。

当前阶段不要把PRD过早锁定到单一实现，例如Live2D、后台无感照片监听、自动社交发布或某一个具体模型。除非已经完成技术验证，否则应保持“候选方案 + 风险 + MVP降级路径”的表达。

## Vibe coding 实现约束

用户计划后续主要通过 vibe coding 完成项目，因此所有方案、PRD补充、原型设计和技术拆分都应方便直接转成代码实现：

- 优先输出可拆分、可迭代的小闭环，不设计过度复杂的一次性大系统。
- 原型优先面向竖屏手机端，适合截图进PPT和录制3分钟Demo视频。
- 前端原型优先采用低依赖、易修改的结构；早期可用单文件HTML/CSS/JS快速验证。
- 页面设计需明确素材路径、组件区域、按钮文案、状态字段和交互流，避免只有抽象概念。
- 功能优先级按P0/P1/P2落地，P0必须能形成“记忆胶囊 → 个性化规划 → 主动提醒 → 蓝小心状态 → 旅行复盘”的演示闭环。
- 任何涉及真实API、Live2D、地图、照片权限、模型调用的能力，都应先提供模拟数据或降级实现，确保Demo可控。
- 生成代码时优先保证移动端竖屏展示效果，默认宽度按390px左右手机视口设计。

## 比赛与交付重点

初赛更关注策划完整度和创新表达，重点产物包括：

- 作品策划文档或PPT；
- 团队介绍；
- 作品设计理念；
- 产品原型设计；
- 创新点说明；
- 前景评估；
- 技术可行性说明；
- 3分钟Demo故事线。

评分侧重点来自现有材料：创新性、应用价值、完成度和大模型应用说明。修改PRD或后续PPT时，应优先强化这些维度。

## 文档维护原则

- 默认使用中文维护仓库文档。
- 修改PRD时优先保持产品叙事一致：长期记忆、主动陪伴、全旅程闭环、隐私可控。
- 不要把“后台无感监控照片”“无确认自动发布社交平台”等高风险能力写成MVP承诺。
- 对未验证能力使用“候选实现”“技术验证项”“MVP降级方案”的表述。
- 如果新增真实代码项目，必须同步补充本文件中的开发命令、目录说明和测试方式。
- 评估用户提供的角色图、原型图或视觉素材时，应优先采用用户给出的素材定位；若姿势、用途或生成阶段不确定，先标注为“待确认”或询问，不要自行断定为自拍图、标准立绘或其他类型。
- 当用户通过 `@文件名`、模板名或模糊文件名引用项目资料时，应先用 Glob 主动搜索根目录和相关目录，确认真实文件名与格式后再读取，不要只依赖用户给出的路径或扩展名。
- 开发过程中若沉淀出新的工程事实、运行命令、验收方式、约束规则或用户纠正点，必须同步更新本文件；`AGENTS.md` 通过引用本文件继承最新项目上下文，不单独维护重复规则。
- `docs/todo.md` 是全项目未完成待办总表，不仅是功能清单。更新时删除已完成项，只保留未完成、未真实化、待验证或人工介入事项；主链路不得把 Mock、固定演示数据或手动模拟标为完成，人工介入项必须单独标注。

## 当前代码工程状态

截至 2026-06-14，仓库已包含可运行工程：

- `apps/mobile/`：Flutter App，已接入 `dio`、Drift SQLite、蓝小心状态枚举和 Agent 聊天联调。
- `services/api/`：FastAPI + LangGraph 后端，使用 `uv` 管理依赖；模型默认 Mock Provider，天气/POI/步行/驾车/公交/混合路线已接高德 Provider，无 Key 时显式 `provider=unconfigured` 降级。
- `docs/`：统一文档目录，按 `product/`、`engineering/`、`handoff/` 分层维护。
- infra/docker-compose.yml：api + postgres 本地编排，nginx 为占位服务。
- 后端已新增 Alembic 初始迁移：services/api/alembic.ini、services/api/migrations/；API 容器通过 LANXIN_DATABASE_URL=postgresql+psycopg://... 连接 Postgres，并在启动前执行 uv run alembic upgrade head。

高德工具 Provider 已支持成功结果进程内缓存、SQLite 持久缓存、一次 HTTP 重试、连续失败熔断和本地限流，并在工具结果和 Agent `toolTrace` 中输出 `retryCount/cacheHit/circuitOpen/errorType/rateLimited/retryAfterSeconds/fallbackReason/sourceTime`，前端可直接展示工具降级原因。
照片候选和上传元数据接口兼容接收 `localUri/localPath`，但云端不保存也不返回设备本地 URI/路径，只保留远程 URL、文件名、内容类型和显式隐私标记。
后端模型调用日志 `ModelCallLogger` 已对 `requestSummary` 做最小化脱敏：密钥、Authorization、Token、密码统一记录为 `[REDACTED]`，用户原文类字段只保留字符数，普通超长文本截断；剩余隐私任务集中在端侧日志和照片/音频敏感内容审计。

后端已新增多人出游协调接口：`POST /api/trip/group/coordinate` 接收至少 2 名成员真实偏好，输出冲突、折中方案和隐私汇总并写入 `group_coordination_records`；`GET /api/trip/group/coordination?tripId=...` 可读回最近协调结果，敏感偏好原文不会出现在对外响应中。
后端已新增复盘生成持久化、提醒触发历史持久化、盲盒任务状态持久化和统一工具调用日志接口：`POST /api/trip/review` 会返回并保存 `reviewId`，未显式传 `completedTasks` 时会自动读取已完成盲盒任务，并聚合真实路线轨迹、可复盘照片地点、提醒历史、蓝小心状态事件、本次旅程记忆沉淀与基于这些上下文派生的下次旅行建议；`GET /api/trip/review?tripId=...` 可读回最近复盘；`POST /api/trip/reminders/trigger` 会返回并保存 `historyId`，`POST /api/trip/reminders/evaluate` 可根据时间/位置/状态/外部事件自动评估提醒、按主动程度过滤并执行冷却，`GET /api/trip/reminders/history` 可读回提醒历史；`GET /api/trip/blind-box/tasks?userId=...&tripId=...` 可读任务状态，`POST /api/trip/blind-box/tasks/{taskId}/status` 可写入 accepted/skipped/completed；`POST/GET /api/trip/route-points` 可写入/读取真实路线轨迹点；`POST/GET /api/trip/avatar-state/events` 可写入/读取蓝小心状态事件，盲盒完成会自动写入 `blind_box_completed`；`POST /api/tools/{tool_name}/call` 会返回 `toolTraceId`；`GET /api/audit/tool-calls` 和 `GET /api/audit/model-calls` 可按工具、Provider、场景、fallback 状态读取审计日志，模型请求摘要已脱敏。
后端真实联调配置从 `services/api/.env.example` 复制到 `.env`；真实模型需要 `LANXIN_MODEL_PROVIDER`、对应 base URL/API Key/model，真实高德工具需要 `LANXIN_AMAP_API_KEY`。不要提交真实 `.env`。隐私说明接口为 `GET /api/privacy/summary`，配套文档在 `docs/engineering/privacy-and-compliance.md`。
后端云同步接口 `POST /api/sync/push` 已支持记忆 `updatedAt` 冲突检测，默认 `serverWins` 不覆盖较新的服务端记忆，端侧明确传 `conflictStrategy=clientWins` 时才覆盖，并在响应 `conflicts` 中返回冲突详情；`POST /api/sync/revoke` 可撤销云端记忆、画像和旅程副本并写入同步审计记录；设置页已接入基础冲突检测、本机覆盖云端和按 ID 撤销指定记忆/旅程；端侧 Drift 已新增 `local_sync_operations` 同步队列，记忆新增/编辑/删除会入队，设置页会优先消费 `memory/upsert` 队列和 `memory/delete` 撤销队列，按成功/失败更新状态，并展示最近同步历史；记忆页已支持选择本地记忆后只同步已选条目；`SyncRetryService` 已抽出 pending 队列重试逻辑，App 启动和回到前台时会自动重试 `memory/upsert` 与 `memory/delete` pending 操作。
常用命令：

```powershell
# 后端
cd services/api
uv sync
uv run pytest
uv run uvicorn app.main:app --host 127.0.0.1 --port 8000

# 前端
cd apps/mobile
flutter pub get
$env:NO_PROXY='localhost,127.0.0.1,::1'
flutter analyze
flutter test --concurrency=1
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000

# Android APK
flutter build apk --debug
```

## 移动端适配基线

- Flutter 前端需要优先覆盖 vivo/Android 主流手机尺寸：360x780、375x812、390x844、412x915、430x932，同时关注横屏、平板宽度和系统字体缩放 1.2/1.4。
- 固定底部导航、输入栏、底部 CTA 和列表页必须显式处理 SafeArea；主要触控目标按 Android 48dp 设计。
- 首页这类沉浸式页面不得只依赖 `Stack + Positioned + 屏幕比例`，短屏或横屏需要折叠次要浮动元素或允许滚动兜底。
- Flutter widget test 在本机若设置了 `HTTP_PROXY`，必须临时设置 `$env:NO_PROXY='localhost,127.0.0.1,::1'` 后再运行，否则 `flutter_tester` 可能出现 WebSocket 握手失败。
- Windows 桌面构建使用 `sqlite3` hook 的 `source: system` + `name_windows: winsqlite3`，避免 native assets 构建阶段从 GitHub 下载 `sqlite3.x64.windows.dll` 失败。

本机执行 `flutter build apk --debug` 需要 Android SDK `platforms;android-35`；CI 已配置自动安装 Android SDK 35 和 `build-tools;35.0.0`。

当前演示闭环：聊天页发送重庆周末游需求后，后端返回记忆候选、规划卡、提醒卡和复盘卡；Flutter 将响应同步到规划、主动提醒和旅行复盘页面；确认记忆后写入本地 Drift SQLite，并可在记忆页编辑/删除。

P1 增强状态：规划页已展示备选方案和高德外部导航入口，并新增真实规划表单与 `TripPlanService` 调用 `/api/trip/plan`，可提交目的地、日期、预算、同行人、偏好和交通方式后展示返回计划；规划页还会读取 `/api/profile/me`，把预算、交通偏好、兴趣、饮食忌口和节奏画像合并进规划请求；本页生成计划后会展示“天气变化重规划”入口，点击后复用当前输入并传 `replanReason=weather_risk`；后端工具注册器已支持高德天气、POI、步行/驾车/公交/混合路线 HTTP 解析，路线可输出换乘、费用、拥堵段、红绿灯和备选方案，并具备进程内成功缓存和一次 HTTP 重试；后端规划卡已将 `toolTrace` 汇总为 `externalContext`，并把天气提示、营业时间和路线耗时写入规划解释；`POST /api/trip/plan` 已支持 destination/startDate/endDate/budget/companions/preferences/transportMode/tripStyle/replanReason，保存到当前旅程并在计划中返回 `planningInputs`，需配置 `LANXIN_AMAP_API_KEY` 才算真实数据联调完成；聊天页展示记忆冲突提示；后端已为饮食偏好、身体状态、位置和同行人记忆候选输出隐私分级与显式确认字段；提醒页支持拍照行为、低精力状态、天气/排队外部事件的手动模拟触发，并会读取 `/api/profile/me`，将主动程度、节奏、兴趣、饮食和交通偏好带入 `/api/trip/reminders/evaluate` 后展示画像上下文与自动评估提醒；后端已支持主动提醒自动评估、主动程度过滤、冷却和历史落库；画像页已通过 `ProfileService` 读取和编辑 `/api/profile/me` 的饮食、节奏、交通、预算和兴趣画像；设置页已通过 `ProfileService` 读取和写回人格、主动程度、同步策略、通知、语音/文字偏好和自定义 Prompt，并通过 `SettingsDataService` 接入 `/api/privacy/summary`、`/api/memory/export`、`DELETE /api/memory/capsules`、`DELETE /api/trip/current` 和 `/api/sync/revoke`，危险操作均有确认弹窗；旅拍页支持候选集、旅行盲盒任务、上传元数据登记、照片候选创建和朋友圈/小红书/日记/Vlog 文案生成；候选登记会调用真实后端并提示设备本地路径不会上传保存，真实系统选图/相机权限仍需真机接入与验收；复盘页可独立调用 `/api/trip/review`，会读取 `/api/profile/me` 并把节奏、兴趣、饮食、交通和预算画像作为 `profileContext` 传入后端，页面展示复盘引用画像；后端响应已包含可聚合的 `route/highlightPhotos/completedTasks/reminderHighlights/avatarStatusChanges/newMemories/nextTripSuggestions/temporaryMemoryPromotions/profileContext`，且没有最新复盘时可将 dashboard `avatarStateEvents` 渲染为“蓝小心状态变化”。
## GitNexus 使用记录

- 当前仓库已由 GitNexus 索引为 `lanxin-travelmate-aigc-2026`。
- 2026-06-19 已执行 `npx gitnexus analyze` 刷新本地索引，CLI 输出约 `3909 nodes / 6220 edges / 55 flows`。
- 后续阶段完成后继续刷新索引，并优先使用 GitNexus 资源理解模块、流程和影响；若当前工具面板未暴露 `query/impact/detect_changes`，则用本地 `git diff`、`rg` 和测试结果补充核对。

## Recent Backend Facts
- 2026-06-21 model schema follow-up: `trip_planner` now validates real-provider trip plans through `TripPlanningOutput`; invalid `tripPlanning` payloads fall back to `MockModelProvider` and append a `model_provider` toolTrace item with `errorType=schema_validation`. Validation passed: `uv run pytest tests/test_model_providers.py -q` and `uv run pytest tests/test_travelmate_graph.py tests/test_agent_api.py tests/test_p1_planning_tools.py tests/test_plan_tool_context.py tests/test_model_providers.py -q`.

- `GET /api/trip/dashboard` aggregates one user's current trip, route points, reminder history, blind-box task states, avatar-state events, latest review, photo candidates, and trip-scoped memories for Flutter real-data screens. When `tripId` is provided, the endpoint only returns the trip if it belongs to the same `userId`; otherwise `currentTrip.status=empty` avoids cross-user data exposure. Flutter has `TripDashboardService` with offline fallback; `HomePage` shows dashboard trip/memory/reminder summary, `TripPage` loads `currentTrip.plan` when no live Agent plan exists, renders dashboard `routePoints` as a real trajectory summary, and can submit `/api/trip/plan` with user input plus profile-derived budget/transport/preference context; `ReminderPage` displays dashboard `reminderHistory.items`, evaluates reminders with `/api/profile/me` context, and shows a real empty/retry state instead of sample reminders; `PhotoPage` reads `photoCandidates/blindBoxTasks` and can register upload metadata/photo candidates through the backend; `ReviewPage` prefers dashboard `latestReview` before generating a new review, passes `/api/profile/me` context into `/api/trip/review`, can render dashboard `avatarStateEvents` as status changes, and shows loading/error states instead of sample reviews; `MemoryPage` merges local Drift memories with dashboard `memories`, shows a real empty/retry state when no memory exists, and can sync only selected local memories. `ProfileService` reads/writes `/api/profile/me`; `ProfilePage` displays and edits persisted profile fields, while `SettingsPage` updates persisted personality/proactivity/sync/notification/voice/text/customPrompt fields. `SettingsDataService` backs the Settings data-control section for privacy summary, memory export, clearing all memories, clearing the current trip, revoking cloud profile sync, revoking selected memory/trip cloud copies by ID, basic conflict detection/client-wins resolution, Drift `memory/upsert` pending queue consumption, Drift `memory/delete` revoke queue consumption, and local sync history display; App lifecycle now calls `SyncRetryService` on launch/resume for pending queue retry. Remaining frontend work is device permissions, true photo picker/camera integration, true scheduled/location/notification reminder triggers, real-provider validation, and scattered offline/mock fallbacks.



- 2026-06-21 CI real-provider smoke follow-up: `.github/workflows/ci.yml` includes an optional `Real provider smoke` job. It maps only GitHub Secrets into env, runs `uv run python scripts/real_provider_smoke.py` only when Amap or real model secrets are configured, and the script logs provider/scenario/fallback/errorType with `[REDACTED]` instead of raw secrets. Local no-secret validation command: `cd services/api; uv run python scripts/real_provider_smoke.py`. Targeted regression: `uv run pytest tests/test_ci_real_smoke_workflow.py -q`. Remaining work is manual GitHub Secrets configuration and CI-side real-provider acceptance.
## Recent Frontend Facts
- 2026-06-21 chat id follow-up: ChatPage no longer sends fixed `demo-session` / `demo-chongqing-weekend`; each page instance creates local `chat-session-*` and `chat-trip-*` ids before calling `/api/agent/chat`, while the explicit `userId=guest` compatibility path remains until full auth/user-id propagation is completed. Validation passed: `flutter analyze`.
- 2026-06-21 auth follow-up: Flutter now has `AuthSessionService` under `features/auth/data/` to create a stable local device id, call `POST /api/auth/guest`, cache the returned guest session, and inject `Authorization: Bearer <token>` through `buildApiClient()`. Existing service methods still pass explicit `userId` for compatibility; remaining auth work is formal JWT, account migration, and real multi-device validation. Validation passed: `flutter analyze`. `flutter test test\auth_session_service_test.dart` timed out in this local runner and was not repeated.
- 2026-06-21 coordinate planning follow-up: `TripPlanRequestDraft` and backend `/api/trip/plan` now support `originCoordinate` and `destinationCoordinate` maps. `TripPage` exposes optional coordinate inputs and sends parsed `{latitude, longitude}` values together with the selected transport mode; backend tests verify the values remain in `planningInputs`, and `tool_planner` now converts them into `route_tool.originLocation/destinationLocation` with the selected mode. Validation passed: `flutter analyze`; `uv run pytest tests/test_trip_plan_inputs.py -q`.
- 2026-06-20 blind-box follow-up: `PhotoExperienceService.updateBlindBoxTaskStatus()` posts to `/api/trip/blind-box/tasks/{taskId}/status`; `PhotoPage` now renders accept/complete/skip controls for blind-box tasks, updates local task state from the backend response, and displays returned affection/rapport reward deltas after completion. Validation passed: `flutter analyze`; backend blind-box/avatar event tests passed with `uv run pytest tests/test_blind_box_task_state.py tests/test_avatar_state_events.py -q`; reward delta response passed with `uv run pytest tests/test_blind_box_task_state.py -q`. Flutter widget tests were not rerun because the local Flutter test runner timed out repeatedly in this session.

- 2026-06-20: Flutter 主页面固定样例依赖继续收敛。`shared/models/travelmate_models.dart` 承载聊天、记忆、规划、提醒、旅拍和复盘 UI 类型；`data/mock_data.dart` 只保留离线样例/测试 fixture。聊天页只保留真实 Agent 欢迎态；记忆、规划、提醒和复盘页在无真实数据时展示空状态、加载、错误或重试入口，不再渲染固定杭州行程、样例记忆、样例提醒或样例复盘。画像页空值显示“未设置”，不再套用固定样例用户画像。
- 本次验证：`flutter analyze` 通过；短测试通过：`$env:NO_PROXY='localhost,127.0.0.1,::1'; flutter test test\memory_page_dashboard_test.dart test\profile_page_service_test.dart test\reminder_page_integration_test.dart test\trip_page_integration_test.dart`。不要运行此前耗时的 `test\review_page_integration_test.dart`，除非用户明确要求。
- 2026-06-20 follow-up: HomePage no longer labels the first screen as demo mode or shows the fixed Chongqing prompt; it now presents a real-integration entry state, dashboard-derived trip/memory/reminder summary, and shortened weather/tool placeholder copy to avoid small-screen overflow. `PhotoExperienceService.fetchCandidates()` and `fetchBlindBoxTasks()` now return empty lists on unavailable/invalid backend responses instead of fixed Chongqing candidates/tasks; only explicit user candidate registration keeps an offline local result marked `offline=true`.
- Additional validation: `flutter analyze` passed; short tests passed with NO_PROXY: `flutter test test\photo_experience_service_test.dart test\photo_page_integration_test.dart test\home_dashboard_test.dart`.
- 2026-06-20 group coordination follow-up: `TripGroupService` calls `/api/trip/group/coordinate`; `TripPage` now exposes a two-member group preference coordination entry before planning, displays compromise pace/budget, conflicts, and privacy summary, and keeps sensitive raw preference handling delegated to the backend response contract. Validation passed: `flutter analyze`; `$env:NO_PROXY='localhost,127.0.0.1,::1'; flutter test test\trip_group_service_test.dart test\trip_page_integration_test.dart`. Follow-up: planned trips now carry the latest coordination payload as `groupCoordination`; the backend `/api/trip/plan` stores it in `planningInputs` and adds a summarized group coordination line to `profileMatches` without exposing sensitive raw member text.
<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **lanxin-travelmate-aigc-2026** (4424 symbols, 7176 relationships, 81 execution flows). Use the GitNexus MCP tools to understand code, assess impact, and navigate safely.

> Index stale? Run `node .gitnexus/run.cjs analyze` from the project root — it auto-selects an available runner. No `.gitnexus/run.cjs` yet? `npx gitnexus analyze` (npm 11 crash → `npm i -g gitnexus`; #1939).

## Always Do

- **MUST run impact analysis before editing any symbol.** Before modifying a function, class, or method, run `impact({target: "symbolName", direction: "upstream"})` and report the blast radius (direct callers, affected processes, risk level) to the user.
- **MUST run `detect_changes()` before committing** to verify your changes only affect expected symbols and execution flows. For regression review, compare against the default branch: `detect_changes({scope: "compare", base_ref: "main"})`.
- **MUST warn the user** if impact analysis returns HIGH or CRITICAL risk before proceeding with edits.
- When exploring unfamiliar code, use `query({query: "concept"})` to find execution flows instead of grepping. It returns process-grouped results ranked by relevance.
- When you need full context on a specific symbol — callers, callees, which execution flows it participates in — use `context({name: "symbolName"})`.

## Never Do

- NEVER edit a function, class, or method without first running `impact` on it.
- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis.
- NEVER rename symbols with find-and-replace — use `rename` which understands the call graph.
- NEVER commit changes without running `detect_changes()` to check affected scope.

## Resources

| Resource | Use for |
|----------|---------|
| `gitnexus://repo/lanxin-travelmate-aigc-2026/context` | Codebase overview, check index freshness |
| `gitnexus://repo/lanxin-travelmate-aigc-2026/clusters` | All functional areas |
| `gitnexus://repo/lanxin-travelmate-aigc-2026/processes` | All execution flows |
| `gitnexus://repo/lanxin-travelmate-aigc-2026/process/{name}` | Step-by-step execution trace |

## CLI

| Task | Read this skill file |
|------|---------------------|
| Understand architecture / "How does X work?" | `.claude/skills/gitnexus/gitnexus-exploring/SKILL.md` |
| Blast radius / "What breaks if I change X?" | `.claude/skills/gitnexus/gitnexus-impact-analysis/SKILL.md` |
| Trace bugs / "Why is X failing?" | `.claude/skills/gitnexus/gitnexus-debugging/SKILL.md` |
| Rename / extract / split / refactor | `.claude/skills/gitnexus/gitnexus-refactoring/SKILL.md` |
| Tools, resources, schema reference | `.claude/skills/gitnexus/gitnexus-guide/SKILL.md` |
| Index, status, clean, wiki CLI commands | `.claude/skills/gitnexus/gitnexus-cli/SKILL.md` |

<!-- gitnexus:end -->
