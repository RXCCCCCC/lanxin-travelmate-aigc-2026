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
- 优先推进核心功能实现。精简测试代码，仅编写验证核心逻辑与接口契约的必要用例，避免过度消耗时间和 Token 于测试细节。
- 当上下文窗口超过70%时必须先压缩上下文再继续推进

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
- `docs/todo.md` 是全项目剩余人工介入清单。更新时删除已由 AI 完成并验证的事项，只保留需要真实密钥、真实设备、正式签名、素材授权、远端推送、部署环境、比赛提交或负责人确认的事项；主链路不得把 Mock、固定演示数据或手动模拟标为完成。

## 当前代码工程状态

截至 2026-06-14，仓库已包含可运行工程：

- `apps/mobile/`：Flutter App，已接入 `dio`、Drift SQLite、蓝小心状态枚举和 Agent 聊天联调。
- `services/api/`：FastAPI + LangGraph 后端，使用 `uv` 管理依赖；模型默认 Mock Provider，天气/POI/步行/驾车/公交/混合路线已接高德 Provider，无 Key 时显式 `provider=unconfigured` 降级。
- `docs/`：统一文档目录，按 `product/`、`engineering/`、`handoff/` 分层维护。
- infra/docker-compose.yml：api + postgres 本地编排，nginx 为占位服务。
- 后端已新增 Alembic 初始迁移：services/api/alembic.ini、services/api/migrations/；API 容器通过 LANXIN_DATABASE_URL=postgresql+psycopg://... 连接 Postgres，并在启动前执行 uv run alembic upgrade head。

高德工具 Provider 已支持成功结果进程内缓存、SQLite 持久缓存、一次 HTTP 重试、连续失败熔断和本地限流，并在工具结果和 Agent `toolTrace` 中输出 `retryCount/cacheHit/circuitOpen/errorType/rateLimited/retryAfterSeconds/fallbackReason/sourceTime`，前端可直接展示工具降级原因。
照片候选和上传元数据接口兼容接收历史 `localUri/localPath` 字段，但云端不保存也不返回设备本地 URI/路径，只保留远程 URL、文件名、内容类型和显式隐私标记；Flutter `PhotoExperienceService` 不再把端侧 `localPath` 发送到后端。
后端模型调用日志 `ModelCallLogger` 已对 `requestSummary` 做最小化脱敏：密钥、Authorization、Token、密码统一记录为 `[REDACTED]`，用户原文类字段只保留字符数，普通超长文本截断；`services/api/tests/test_mobile_privacy_boundaries.py` 静态防回归检查移动端运行时代码不得使用 `print/debugPrint/developer.log/console.log` 输出私密媒体或音频值，并禁止旅拍上传请求发送 `localPath`。剩余隐私任务集中在真机照片/音频权限链路审计。

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
- 当前仓库只维护 Android/vivo 原生平台壳：保留 `apps/mobile/android/`、Flutter Dart 业务代码和通用资源；不要主动新增或维护 iOS、macOS、Windows、Linux、Web 平台工程；推送到远端 `dev` 后也应只保留 Android 侧相关平台文件。
- Android 模拟器联调本机 FastAPI 时需要执行 `adb reverse tcp:8000 tcp:8000`，移动端真实 Agent/Provider 路径可能需要约 30 秒返回；不要把 API `receiveTimeout` 改回只适合 Mock 的短超时。
- 固定底部导航、输入栏、底部 CTA 和列表页必须显式处理 SafeArea；主要触控目标按 Android 48dp 设计。
- 首页这类沉浸式页面不得只依赖 `Stack + Positioned + 屏幕比例`，短屏或横屏需要折叠次要浮动元素或允许滚动兜底。
- Flutter widget test 在本机若设置了 `HTTP_PROXY`，必须临时设置 `$env:NO_PROXY='localhost,127.0.0.1,::1'` 后再运行，否则 `flutter_tester` 可能出现 WebSocket 握手失败。

本机执行 `flutter build apk --debug` 前先运行 `python scripts/android_release_preflight.py --json`；本机需要 Android SDK `platforms;android-35`。CI 的 Android APK job 会安装 Android SDK 35 和 `build-tools;35.0.0`，并运行 `python scripts/android_release_preflight.py --strict`。

当前演示闭环：聊天页发送重庆周末游需求后，后端返回记忆候选、规划卡、提醒卡和复盘卡；Flutter 将响应同步到规划、主动提醒和旅行复盘页面；确认记忆后写入本地 Drift SQLite，并可在记忆页编辑/删除。

P1 增强状态：规划页已展示备选方案和高德外部导航入口，并新增真实规划表单与 `TripPlanService` 调用 `/api/trip/plan`，可提交目的地、日期、预算、同行人、偏好和交通方式后展示返回计划；规划页还会读取 `/api/profile/me`，把预算、交通偏好、兴趣、饮食忌口和节奏画像合并进规划请求；本页生成计划后会展示“天气变化重规划”入口，点击后复用当前输入并传 `replanReason=weather_risk`；后端工具注册器已支持高德天气、POI、步行/驾车/公交/混合路线 HTTP 解析，路线可输出换乘、费用、拥堵段、红绿灯和备选方案，并具备进程内成功缓存和一次 HTTP 重试；后端规划卡已将 `toolTrace` 汇总为 `externalContext`，并把天气提示、营业时间和路线耗时写入规划解释；`POST /api/trip/plan` 已支持 destination/startDate/endDate/budget/companions/preferences/transportMode/tripStyle/replanReason，保存到当前旅程并在计划中返回 `planningInputs`，需配置 `LANXIN_AMAP_API_KEY` 才算真实数据联调完成；聊天页展示记忆冲突提示；后端已为饮食偏好、身体状态、位置和同行人记忆候选输出隐私分级与显式确认字段；提醒页支持拍照行为、低精力状态、天气/排队外部事件的手动模拟触发，并会读取 `/api/profile/me`，将主动程度、节奏、兴趣、饮食和交通偏好带入 `/api/trip/reminders/evaluate` 后展示画像上下文与自动评估提醒；后端已支持主动提醒自动评估、主动程度过滤、冷却和历史落库；画像页已通过 `ProfileService` 读取和编辑 `/api/profile/me` 的饮食、节奏、交通、预算和兴趣画像；设置页已通过 `ProfileService` 读取和写回人格、主动程度、同步策略、通知、语音/文字偏好和自定义 Prompt，并通过 `SettingsDataService` 接入 `/api/privacy/summary`、`/api/memory/export`、`DELETE /api/memory/capsules`、`DELETE /api/trip/current` 和 `/api/sync/revoke`，危险操作均有确认弹窗；旅拍页支持候选集、旅行盲盒任务、上传元数据登记、照片候选创建和朋友圈/小红书/日记/Vlog 文案生成；候选登记会调用真实后端并提示设备本地路径不会上传保存，真实系统选图/相机权限仍需真机接入与验收；复盘页可独立调用 `/api/trip/review`，会读取 `/api/profile/me` 并把节奏、兴趣、饮食、交通和预算画像作为 `profileContext` 传入后端，页面展示复盘引用画像；后端响应已包含可聚合的 `route/highlightPhotos/completedTasks/reminderHighlights/avatarStatusChanges/newMemories/nextTripSuggestions/temporaryMemoryPromotions/profileContext`，且没有最新复盘时可将 dashboard `avatarStateEvents` 渲染为“蓝小心状态变化”。
## GitNexus 使用记录

- 当前仓库已由 GitNexus 索引为 `lanxin-travelmate-aigc-2026`。
- 2026-06-19 已执行 `npx gitnexus analyze` 刷新本地索引，CLI 输出约 `3909 nodes / 6220 edges / 55 flows`。
- 后续阶段完成后继续刷新索引，并优先使用 GitNexus 资源理解模块、流程和影响；若当前工具面板未暴露 `query/impact/detect_changes`，则用本地 `git diff`、`rg` 和测试结果补充核对。

## Recent Backend Facts
- 2026-06-29 real-provider acceptance follow-up: `uv run python scripts\real_provider_smoke.py` passes with Amap weather/walking route `provider=amap fallback=false` and OpenAI-compatible model connectivity `ok=True`; additional direct Amap POI/driving/transit/mixed route checks also return `provider=amap fallback=false`. `OpenAICompatibleProvider` and `LanxinModelProvider` now inject scenario-specific JSON contracts into the system prompt, and `/api/photo/copywriting` normalizes common real-model aliases (`wechat/xhs/travelDiary/vlog`) into the public schema. Real photo copywriting smoke returns `provider=openai_compatible fallback=false`. Agent, trip plan/review, and photo copywriting model calls now persist into `/api/audit/model-calls` with redacted request summaries. Remaining risk: companion chat/trip planning may still fallback when the external model times out, so final acceptance must verify five real scenarios with `fallback=false`.
- 2026-06-21 cleanup inventory follow-up: `docs/handoff/cleanup-inventory.md` records tracked repository size candidates without deleting files. Main candidates are `project/img/lanxiaoxin/lanxiaoxin_live2d_scaffold.psd` (~16 MB) and duplicated PNG source assets under `project/img/lanxiaoxin/`; runtime `apps/mobile/assets/avatars/`, `pubspec.lock`, `services/api/uv.lock`, Drift `app_database.g.dart`, and Flutter generated plugin registrants should be kept unless the build strategy changes. Deleting assets remains a human-confirmed action.
- 2026-06-21 guest upgrade follow-up: `POST /api/auth/upgrade-guest` requires a guest Bearer token, binds a password credential to the same guest `userId`, flips `auth_mode` to `password`, returns a non-guest JWT, and reports `migrationSummary` counts for memories, profiles, trips, photo candidates, reminders, group coordination, blind-box tasks, route points, avatar-state events, and sync records. This is an in-place strategy, so existing persisted data remains readable under the same `userId`; true multi-device acceptance and external account providers remain manual. Validation passed: `uv run pytest tests/test_auth_routes.py -q`.
- 2026-06-21 auth JWT follow-up: access tokens are now HMAC-SHA256 JWTs with `sub`, `isGuest`, `iat`, and `exp` claims, signed with `LANXIN_AUTH_TOKEN_SECRET` and controlled by `LANXIN_AUTH_TOKEN_TTL_SECONDS`. `parse_access_token` still accepts the previous local HMAC token format for existing guest sessions. `.env.example`, README, and `docs/engineering/api-contract.md` document the production secret requirement. Validation passed: `uv run python -m py_compile app\core\security.py app\core\config.py` and `uv run pytest tests/test_auth_routes.py -q`.
- 2026-06-21 migration rollback follow-up: `services/api/scripts/migration_plan.py` validates the Alembic revision chain, verifies every revision has an executable downgrade, and prints manual production upgrade/rollback commands with explicit backup and maintenance-mode reminders. `docs/engineering/database-migrations.md` documents the production migration, rollback, and human validation boundaries; README links the check/plan commands. Validation passed: `uv run python -m py_compile scripts\migration_plan.py`, `uv run python scripts\migration_plan.py check`, `uv run python scripts\migration_plan.py plan --target head --rollback-to 0005_add_trip_route_points --backup-path backups\before-avatar-events.dump`, and `uv run pytest tests/test_database_migrations.py -q`.
- 2026-06-21 node split follow-up: TravelMate graph runtime now imports node order/table from `app.agents.travelmate.nodes.registry`; real Agent nodes live in `real_nodes.py`, rule/default fallback helpers live in `fallback_nodes.py`, and former `mock_nodes.py` is only a compatibility export layer. Tests now monkeypatch `real_nodes` directly. Validation passed: `uv run python -m py_compile app\agents\travelmate\graph.py app\agents\travelmate\nodes\real_nodes.py app\agents\travelmate\nodes\fallback_nodes.py app\agents\travelmate\nodes\registry.py app\agents\travelmate\nodes\mock_nodes.py` and `uv run pytest tests/test_model_providers.py tests/test_plan_tool_context.py tests/test_travelmate_graph.py tests/test_agent_api.py -q`.
- 2026-06-21 documentation follow-up: README, `docs/engineering/api-contract.md`, `docs/engineering/agent-graph.md`, `docs/engineering/tech-design.md`, and `docs/handoff/e2e-acceptance.md` now document the structured model Provider chain, schema roots, fallback semantics, `toolTrace`/audit checks, and the boundary between real Provider data, explicit fallback, and persisted user data. `docs/todo.md` marks the documentation sync item complete.
- 2026-06-21 structured provider integration follow-up: `tests/test_model_providers.py` now includes a core Agent loop test where one structured provider drives memory extraction, trip planning, trip review, and companion chat with non-fallback `model_provider` toolTrace entries for all four scenarios. Validation passed: `uv run pytest tests/test_model_providers.py -q`.
- 2026-06-21 chat provider follow-up: `response_composer` now calls the configured model provider with `scenario=companion_chat`, requires a `chat` root payload, validates it through `ChatOutput`, preserves existing cards/memory candidates when model lists are empty, and falls back to the local response while appending `companion_chat` toolTrace metadata on provider or schema failure. Validation passed: `uv run pytest tests/test_model_providers.py tests/test_travelmate_graph.py tests/test_agent_api.py tests/test_model_outputs.py -q`.
- 2026-06-21 memory extraction provider follow-up: `memory_extractor` now calls the configured model provider with `scenario=memory_extraction`, requires a `memoryExtraction` root payload, validates it through `MemoryExtractionOutput`, normalizes model candidates with memory ids/scope options/privacy confirmation fields, and falls back to the existing local privacy rules when the provider is unconfigured, lacks JSON generation, omits `memoryExtraction`, or fails schema validation. Validation passed: `uv run pytest tests/test_model_providers.py tests/test_travelmate_graph.py tests/test_agent_api.py tests/test_model_outputs.py -q`.
- 2026-06-21 trip review provider follow-up: `review_generator` now calls the configured model provider with `scenario=trip_review`, requires a `tripReview` root payload, validates it through `TripReviewOutput`, and falls back to the existing persisted-context aggregation when the provider is unconfigured, lacks JSON generation, omits `tripReview`, or fails schema validation. Schema fallback appends `toolTrace` with `errorType=schema_validation`. Validation passed: `uv run pytest tests/test_model_providers.py tests/test_p1_review_routes.py tests/test_travelmate_graph.py tests/test_trip_event_persistence.py tests/test_trip_review_aggregation.py tests/test_trip_review_memory_settlement.py tests/test_trip_review_next_suggestions.py -q`.
- 2026-06-21 photo copywriting provider follow-up: `/api/photo/copywriting` now calls the configured model provider with `scenario=photo_copywriting`, validates the result through `PhotoCopywritingOutput`, persists the validated copywriting, and returns explicit fallback metadata (`provider`, `fallback`, `errorType`, `fallbackReason`) when the provider is unconfigured or schema validation fails. Validation passed: `uv run pytest tests/test_p1_photo_content_tasks.py -q`.
- 2026-06-21 model output schema follow-up: `parse_model_output` now validates structured outputs for chat (`ChatOutput`), memory extraction, trip planning, photo copywriting, and trip review. Invalid structured payloads return `fallback=True` with the raw payload preserved for audit/fallback handling. Validation passed: `uv run pytest tests/test_model_outputs.py -q`. Remaining work is node-level integration for chat, memory extraction, photo copywriting, and review real-provider outputs.
- 2026-06-21 model schema follow-up: `trip_planner` now validates real-provider trip plans through `TripPlanningOutput`; invalid `tripPlanning` payloads fall back to `MockModelProvider` and append a `model_provider` toolTrace item with `errorType=schema_validation`. Validation passed: `uv run pytest tests/test_model_providers.py -q` and `uv run pytest tests/test_travelmate_graph.py tests/test_agent_api.py tests/test_p1_planning_tools.py tests/test_plan_tool_context.py tests/test_model_providers.py -q`.

- `GET /api/trip/dashboard` aggregates one user's current trip, route points, reminder history, blind-box task states, avatar-state events, latest review, photo candidates, and trip-scoped memories for Flutter real-data screens. When `tripId` is provided, the endpoint only returns the trip if it belongs to the same `userId`; otherwise `currentTrip.status=empty` avoids cross-user data exposure. Flutter has `TripDashboardService` with offline fallback; `HomePage` shows dashboard trip/memory/reminder summary, `TripPage` loads `currentTrip.plan` when no live Agent plan exists, renders dashboard `routePoints` as a real trajectory summary, and can submit `/api/trip/plan` with user input plus profile-derived budget/transport/preference context; `ReminderPage` displays dashboard `reminderHistory.items`, evaluates reminders with `/api/profile/me` context, and shows a real empty/retry state instead of sample reminders; `PhotoPage` reads `photoCandidates/blindBoxTasks` and can register upload metadata/photo candidates through the backend; `ReviewPage` prefers dashboard `latestReview` before generating a new review, passes `/api/profile/me` context into `/api/trip/review`, can render dashboard `avatarStateEvents` as status changes, and shows loading/error states instead of sample reviews; `MemoryPage` merges local Drift memories with dashboard `memories`, shows a real empty/retry state when no memory exists, and can sync only selected local memories. `ProfileService` reads/writes `/api/profile/me`; `ProfilePage` displays and edits persisted profile fields, while `SettingsPage` updates persisted personality/proactivity/sync/notification/voice/text/customPrompt fields. `SettingsDataService` backs the Settings data-control section for privacy summary, memory export, clearing all memories, clearing the current trip, revoking cloud profile sync, revoking selected memory/trip cloud copies by ID, basic conflict detection/client-wins resolution, Drift `memory/upsert` pending queue consumption, Drift `memory/delete` revoke queue consumption, and local sync history display; App lifecycle now calls `SyncRetryService` on launch/resume for pending queue retry. Remaining frontend work is device permissions, true photo picker/camera integration, true scheduled/location/notification reminder triggers, real-provider validation, and scattered offline/mock fallbacks.



- 2026-06-21 CI real-provider smoke follow-up: `.github/workflows/ci.yml` includes an optional `Real provider smoke` job. It maps only GitHub Secrets into env, runs `uv run python scripts/real_provider_smoke.py` only when Amap or real model secrets are configured, and the script logs provider/scenario/fallback/errorType with `[REDACTED]` instead of raw secrets. Local no-secret validation command: `cd services/api; uv run python scripts/real_provider_smoke.py`. Targeted regression: `uv run pytest tests/test_ci_real_smoke_workflow.py -q`. Remaining work is manual GitHub Secrets configuration and CI-side real-provider acceptance.
## Recent Frontend Facts
- 2026-06-21 mobile permission manifest follow-up: Android release `AndroidManifest.xml` now declares `INTERNET`, coarse/fine location, camera, microphone, Android 13 notifications, `READ_MEDIA_IMAGES`, and legacy `READ_EXTERNAL_STORAGE` with `maxSdkVersion=32`; non-Android platform shells are no longer maintained in this repo. Added `services/api/tests/test_mobile_permission_manifests.py` as a static guard. Validation passed: `uv run pytest tests/test_mobile_permission_manifests.py -q` and `flutter analyze`. Runtime permission prompts, denial branches, real picker/camera/mic/location behavior, and vivo/Android validation remain manual/product work.
- 2026-06-21 group privacy UI follow-up: TripPage group coordination result card now consumes `privacySummary.sensitiveMemberDetailsHidden`, `sensitiveMemberCount`, and `publicRule`, displaying that member sensitive preferences were hidden while only aggregate coordination evidence is shown. Added `services/api/tests/test_mobile_group_privacy_boundaries.py` to guard that `_GroupCoordinationResultCard` does not render `sensitivePreferences`. Validation passed: `uv run pytest tests/test_mobile_group_privacy_boundaries.py -q` and `flutter analyze`.
- 2026-06-21 memory privacy UI follow-up: Flutter `MemoryCandidate` now preserves `category`, `sensitivity`, and `requiresExplicitConsent` from `/api/agent/chat`; ChatPage memory candidate panel shows an explicit confirmation hint when candidates include `sensitive` or `personal` items, while keeping the main “发现 N 条记忆候选” title for existing tests. Static guard added in `services/api/tests/test_mobile_memory_privacy_boundaries.py`. Validation passed: `uv run pytest tests/test_mobile_memory_privacy_boundaries.py tests/test_mobile_privacy_boundaries.py -q` and `flutter analyze`.
- 2026-06-21 mobile privacy boundary follow-up: `PhotoExperienceService.createUploadMetadata()` still accepts a local path for UI flow compatibility but no longer sends `localPath` to `/api/photo/upload-metadata`; backend photo endpoints continue to return `localUri/localPath=null`. Added `services/api/tests/test_mobile_privacy_boundaries.py` to guard no runtime `print/debugPrint/developer.log/console.log` logging in `apps/mobile/lib` and no local path in upload metadata requests. Validation passed: `uv run pytest tests/test_mobile_privacy_boundaries.py tests/test_p1_photo_content_tasks.py -q` and `flutter analyze`. `flutter test test\photo_experience_service_test.dart` was attempted but the local runner timed out with the known `flutter_tester` WebSocket issue, so it is not passing evidence.
- 2026-06-21 mobile mock-boundary follow-up: ReviewPage no longer sends the fixed `demo-chongqing-weekend` trip id. It resolves trip id from the latest Agent `tripPlan` card, dashboard current trip metadata, or a generated `review-trip-*` id. `services/api/tests/test_mobile_mock_boundaries.py` now guards that Flutter runtime sources do not import `mock_data.dart` or contain the fixed demo trip id, and confirms `demo_agent_state.dart` is only a cross-page Agent response cache. Validation passed: `flutter analyze` and `uv run pytest tests/test_mobile_mock_boundaries.py -q`.
- 2026-06-21 avatar expression follow-up: `AvatarState` now maps backend API aliases and persisted event types (for example `trip_planning`, `weather_risk`, `blind_box_completed`, `memory_confirmed`) to concrete Lanxiaoxin visual states, exposes motion parameters, and `AvatarDisplay` applies state-specific float/pulse animation plus semantic labels. Current assets remain PNG under `apps/mobile/assets/avatars/`; final GIF/WebP/Lottie replacement still needs approved visual assets. Validation passed: `flutter analyze`. `flutter test test\avatar_states_test.dart` did not complete in this local runner because `flutter_tester` timed out after the known WebSocket/proxy issue, so it was not used as passing evidence.
- 2026-06-21 chat id follow-up: ChatPage no longer sends fixed `demo-session` / `demo-chongqing-weekend`; each page instance creates local `chat-session-*` and `chat-trip-*` ids before calling `/api/agent/chat`, while the explicit `userId=guest` compatibility path remains until full auth/user-id propagation is completed. Validation passed: `flutter analyze`.
- 2026-06-21 auth follow-up: Flutter now has `AuthSessionService` under `features/auth/data/` to create a stable local device id, call `POST /api/auth/guest`, cache the returned guest session, and inject `Authorization: Bearer <token>` through `buildApiClient()`. Existing service methods still pass explicit `userId` for compatibility; remaining auth work is real multi-device validation and any external account-provider policy. Validation passed: `flutter analyze`. `flutter test test\auth_session_service_test.dart` timed out in this local runner and was not repeated.
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

- 2026-06-21 auth-scope follow-up: backend profile, memory list/create/export/clear, and Agent chat routes now use `resolve_effective_user_id()` so authenticated Bearer-token users are used when `userId` is omitted or still sent as `guest`. Explicit non-guest `userId` remains compatible. Validation passed: `uv run python -m py_compile app\core\security.py app\api\routes\profile.py app\api\routes\memory.py app\api\routes\agent.py`; `uv run pytest tests/test_authenticated_user_scope.py tests/test_auth_routes.py tests/test_profile_settings_context.py tests/test_persistence_routes.py tests/test_agent_api.py -q`. GitNexus `impact` for `get_current_user`, `read_profile`, and `chat` timed out at about 34s, so fallback review used `rg`, `git diff`, py_compile, and targeted pytest. Remaining auth ownership work is real multi-device validation.

- 2026-06-21 data-route auth-scope follow-up: backend photo candidate/upload/copywriting, sync push/pull/selected/revoke, and tool-call routes now resolve default `guest` requests to the Bearer-token user while preserving explicit non-guest userId compatibility. Validation passed: `uv run python -m py_compile app\api\routes\photo.py app\api\routes\sync.py app\api\routes\tools.py`; `uv run pytest tests/test_authenticated_data_routes_scope.py tests/test_authenticated_user_scope.py tests/test_p1_photo_content_tasks.py tests/test_sync_and_clear_routes.py tests/test_sync_conflicts.py tests/test_sync_revoke.py tests/test_tools.py -q`. Remaining user-scope work: real multi-device validation.

- 2026-06-21 trip auth-scope follow-up: trip plan/current/dashboard/review/reminder/history/group/route/avatar/blind-box endpoints now use Bearer-token-first ownership via `resolve_effective_user_id()`. The review fallback route string also uses `\u2192` to preserve the existing P1 review contract. Validation passed: `uv run pytest tests/test_authenticated_trip_scope.py tests/test_trip_dashboard.py tests/test_trip_plan_inputs.py tests/test_trip_event_persistence.py tests/test_trip_route_points.py tests/test_blind_box_task_state.py tests/test_avatar_state_events.py tests/test_reminder_evaluate.py tests/test_p1_review_routes.py -q` and auth-scope aggregate `uv run pytest tests/test_authenticated_user_scope.py tests/test_authenticated_data_routes_scope.py tests/test_authenticated_trip_scope.py tests/test_auth_routes.py tests/test_profile_settings_context.py tests/test_persistence_routes.py tests/test_p1_photo_content_tasks.py tests/test_sync_and_clear_routes.py tests/test_sync_conflicts.py tests/test_sync_revoke.py tests/test_tools.py -q`. Remaining ownership item: real multi-device validation.

- 2026-06-21 trip auth-scope GitNexus note: `node .gitnexus\\run.cjs detect_changes --repo lanxin-travelmate-aigc-2026` reported high risk for the trip route ownership change across 9 flows. Extra targeted verification passed: `uv run pytest tests/test_group_coordination.py tests/test_p1_planning_tools.py tests/test_p1_reminders.py tests/test_plan_tool_context.py tests/test_trip_review_aggregation.py tests/test_trip_review_memory_settlement.py tests/test_trip_review_next_suggestions.py -q`.
- 2026-06-21 audio auth-scope follow-up: backend `/api/audio/asr` and `/api/audio/tts` now use Bearer-token-first ownership via `resolve_effective_user_id()`, return the effective `userId`, and persist `ToolCallLog.user_id` for ASR/TTS/tools audit records. SQLite lightweight migration and Alembic `0007_add_tool_call_log_user_id` keep local and Postgres schemas aligned. Validation passed: `uv run python -m py_compile app\api\routes\audio.py app\api\routes\tools.py app\api\routes\audit.py app\db\models.py app\db\session.py migrations\versions\0007_add_tool_call_log_user_id.py`; `uv run pytest tests/test_authenticated_audio_scope.py tests/test_audio_routes.py tests/test_audit_routes.py tests/test_authenticated_data_routes_scope.py tests/test_tools.py -q`. GitNexus `detect_changes --repo lanxin-travelmate-aigc-2026` reported medium risk across app migration, tools call, ASR, and TTS flows.
- 2026-06-21 mobile review/reminder mock-boundary follow-up: Flutter runtime review fallback no longer returns fixed Chongqing/Hongyadong photos, tasks, memories, or next-trip suggestions; ReviewPage no longer sends sample completed tasks/temporary memories into `/api/trip/review`, and ReminderPage no longer hardcodes Hongyadong as the evaluate/trigger location. `services/api/tests/test_mobile_mock_boundaries.py` now guards against fixed review fixture markers in runtime Dart sources. Validation passed: `uv run pytest tests/test_mobile_mock_boundaries.py -q`; `flutter analyze`. GitNexus `detect_changes --repo lanxin-travelmate-aigc-2026` reported low risk.
- 2026-06-21 mobile photo mock-boundary follow-up: PhotoPage manual candidate registration no longer sends or constructs the fake `device://selected-photo/...` URI and no longer uses the fixed `manual-night-photo.jpg` filename. The generated upload filename and candidate id now share a runtime timestamp, while `PhotoExperienceService` still omits local paths from backend requests. `services/api/tests/test_mobile_mock_boundaries.py` guards against fake device photo URI markers in runtime Dart sources. Validation passed: `uv run pytest tests/test_mobile_mock_boundaries.py tests/test_mobile_privacy_boundaries.py -q`; `flutter analyze`. GitNexus `detect_changes --repo lanxin-travelmate-aigc-2026` reported low risk.
- 2026-06-21 mobile blind-box trip ownership follow-up: `PhotoExperienceService.updateBlindBoxTaskStatus()` now requires an explicit `tripId`; PhotoPage resolves the current trip id from `GET /api/trip/dashboard` and blocks blind-box status updates with a clear UI notice when no real trip id is available instead of writing to the previous fixed `current-guest-trip`. `services/api/tests/test_mobile_mock_boundaries.py` guards runtime Dart sources against that fixed guest trip id. Validation passed: `uv run pytest tests/test_mobile_mock_boundaries.py tests/test_mobile_privacy_boundaries.py -q`; `flutter analyze`. GitNexus `detect_changes --repo lanxin-travelmate-aigc-2026` reported low risk.
- 2026-06-21 backend demo-id boundary follow-up: `create_initial_state()` no longer fills missing `trip_id` with `demo-chongqing-weekend`; trip plan/review/reminder routes now derive Agent `session_id` from user, scenario, and trip/trigger context instead of `demo-session`. `services/api/tests/test_mobile_mock_boundaries.py` now guards backend runtime app sources against those fixed demo ids. Validation passed: `uv run python -m py_compile app\agents\travelmate\state.py app\api\routes\trip.py`; `uv run pytest tests/test_mobile_mock_boundaries.py tests/test_trip_plan_inputs.py tests/test_p1_review_routes.py tests/test_p1_reminders.py tests/test_travelmate_graph.py tests/test_agent_api.py -q`. GitNexus `detect_changes --repo lanxin-travelmate-aigc-2026` reported medium risk; diff review confirmed only session/trip default boundaries changed.
- 2026-06-21 backend review fallback boundary follow-up: `/api/trip/review` fallback no longer injects fixed Chongqing route/photo/task/temporary-memory/next-trip fixtures when no persisted or request context exists. Empty real context now returns empty review fields, while persisted route points, photo candidates, completed blind-box tasks, reminders, avatar events, trip-scoped memories, and explicit request context still aggregate into the review. Validation passed: `uv run pytest tests/test_p1_review_routes.py tests/test_model_providers.py tests/test_trip_review_aggregation.py tests/test_trip_review_memory_settlement.py tests/test_trip_review_next_suggestions.py tests/test_trip_route_points.py tests/test_blind_box_task_state.py tests/test_avatar_state_events.py -q`; `uv run python -m py_compile app\agents\travelmate\nodes\fallback_nodes.py app\agents\travelmate\nodes\real_nodes.py`. GitNexus `detect_changes --repo lanxin-travelmate-aigc-2026` reported low risk.
- 2026-06-21 trip tool context UI follow-up: TripPage now renders plan `externalContext` and `toolTrace` in an external data status card, including weather/POI/route summaries plus provider fallback reason, `errorType`, cache hit, circuit-open, rate-limit, and retry metadata. Added `services/api/tests/test_mobile_trip_tool_context.py` as a static guard. Validation passed: `uv run pytest tests/test_mobile_trip_tool_context.py tests/test_plan_tool_context.py tests/test_real_tool_providers.py -q`; `flutter analyze`.
- 2026-06-21 blind-box reward animation follow-up: PhotoPage now wraps completed blind-box `rewardDeltas` in an `AnimatedSwitcher` and `_RewardPulseCard` using `TweenAnimationBuilder`/`Transform.scale`, so backend rewards have visible feedback without new dependencies. Added `services/api/tests/test_mobile_blind_box_reward_animation.py` as a static guard. Validation passed: `uv run pytest tests/test_mobile_blind_box_reward_animation.py tests/test_blind_box_task_state.py -q`; `flutter analyze`.
- 2026-06-21 review detail cards follow-up: ReviewPage now renders completed tasks, reminder highlights, and temporary-memory promotions as detail cards instead of title-only review rows. Task cards surface status/reward/impact/note/completedAt, reminder cards surface trigger/location/time/history id, and promotion cards surface suggested scope/content/category/confidence. Added `services/api/tests/test_mobile_review_detail_cards.py` as a static guard. Validation passed: `uv run pytest tests/test_mobile_review_detail_cards.py tests/test_trip_review_aggregation.py tests/test_trip_review_memory_settlement.py -q`; `flutter analyze`.
- 2026-06-21 trip edit-plan follow-up: TripPage now supports editing an already generated plan. The plan result view exposes `trip-edit-current-plan`; selecting it switches back to the real planning form, prefilling destination, coordinates, dates, companions, preferences, budget, and transport mode from `planningInputs`/plan metadata where available. Successful resubmission exits edit mode and shows the updated plan. Added `services/api/tests/test_mobile_trip_edit_plan.py` as a static guard. Validation passed: `uv run pytest tests/test_mobile_trip_edit_plan.py tests/test_mobile_trip_tool_context.py tests/test_trip_plan_inputs.py -q`; `flutter analyze`.
- 2026-06-21 fallback tool fixture boundary follow-up: backend fallback tools in `app/tools/mock_tools.py` no longer inject fixed Chongqing/Hongyadong/route/photo-tag defaults for empty payloads. Weather/POI/route/navigation/ASR/TTS/photo-analysis fallbacks are now input-driven or return empty neutral structures, while explicit origin/destination inputs still produce navigation links. Added `services/api/tests/test_mock_tool_boundaries.py`. Validation passed: `uv run python -m py_compile app\tools\mock_tools.py app\tools\registry.py`; `uv run pytest tests/test_mock_tool_boundaries.py tests/test_tools.py tests/test_p1_planning_tools.py tests/test_real_tool_providers.py -q`.
- 2026-06-21 mobile runtime naming follow-up: Flutter runtime pages and related tests now import `data/agent_response_cache.dart` instead of the legacy `demo_agent_state.dart` name; the legacy file remains only as a compatibility export because file deletion still requires explicit confirmation. `AuthSessionService` default guest display name is now `蓝心同行游客` instead of `vivo demo`. Static guards in `services/api/tests/test_mobile_mock_boundaries.py` prevent runtime imports of the legacy demo cache and prevent the `vivo demo` default from returning. Validation passed: `flutter analyze`; `uv run pytest tests/test_mobile_mock_boundaries.py -q`.
- 2026-06-21 Android photo picker follow-up: Flutter now has `PhotoSelectionService` backed by `MethodChannel('lanxin_travelmate/photo_picker')`; Android `MainActivity` handles `pickFromGallery` with `Intent.ACTION_OPEN_DOCUMENT` and `takePhoto` with `MediaStore.ACTION_IMAGE_CAPTURE` plus a pre-created `content://` output. `PhotoPage` exposes both camera and gallery entry points before registering a candidate and still sends only filename/MIME/remote metadata to the backend, not the local URI. Added `services/api/tests/test_mobile_photo_picker_channel.py`. Validation passed: RED first (`3 failed` before implementation), then `uv run pytest tests/test_mobile_photo_picker_channel.py -q`; `flutter analyze`. Runtime vivo/gallery/camera permission behavior remains manual validation.
- 2026-06-21 Android location channel follow-up: Flutter now has `LocationSelectionService` backed by `MethodChannel('lanxin_travelmate/location')`; Android `MainActivity` handles `getCurrentLocation`, requests `ACCESS_FINE_LOCATION`/`ACCESS_COARSE_LOCATION`, and returns the latest GPS/network location as latitude/longitude/accuracy/provider. `TripPage` exposes a `trip-use-current-location` icon button that fills `originCoordinateController.text` with the real coordinate string and shows a non-blocking status notice. Added `services/api/tests/test_mobile_location_channel.py`. Validation passed: RED first (`3 failed` before implementation), then `uv run pytest tests/test_mobile_location_channel.py tests/test_mobile_permission_manifests.py tests/test_mobile_photo_picker_channel.py -q`; `flutter analyze`. Runtime vivo permission prompts and live GPS accuracy remain manual validation.
- 2026-06-21 Android voice channel follow-up: Flutter now has `VoiceInteractionService` backed by `MethodChannel('lanxin_travelmate/voice')`; ChatPage exposes a microphone entry that requests Android speech recognition, fills the recognized text into the input for user confirmation, and attempts system TTS playback from Agent `voiceText`/`replyText` after replies. Android `MainActivity` handles `startVoiceInput` through `RecognizerIntent.ACTION_RECOGNIZE_SPEECH`, requests `RECORD_AUDIO`, and handles `speakText` through `TextToSpeech`. Validation passed: `flutter analyze`; `uv run pytest tests/test_mobile_voice_channel.py tests/test_mobile_location_channel.py tests/test_mobile_permission_manifests.py tests/test_mobile_privacy_boundaries.py -q`. GitNexus `detect_changes --repo lanxin-travelmate-aigc-2026` reported medium risk across ChatPage build/send-message flows and documentation symbols. Runtime vivo microphone permission prompts, installed speech recognizer availability, and Chinese TTS quality remain manual validation.
- 2026-06-21 Android notification channel follow-up: Flutter now has `NotificationDeliveryService` backed by `MethodChannel('lanxin_travelmate/notifications')`; ReminderPage attempts to deliver a system notification when backend reminder trigger/evaluate returns an item, and displays a non-blocking in-app status when notification delivery is unavailable. Android `MainActivity` handles `showReminderNotification`, creates a `NotificationChannel`, requests `POST_NOTIFICATIONS` on Android 13+, and posts via `NotificationCompat.Builder`. Validation passed: RED first (`3 failed` before implementation), then `uv run pytest tests/test_mobile_notification_channel.py -q`; `flutter analyze`. GitNexus `detect_changes --repo lanxin-travelmate-aigc-2026` reported low risk with no affected execution flows. Android APK/Kotlin compilation and vivo notification permission/display behavior were not run in this session and remain manual/CI validation.
- 2026-06-21 Android-only platform policy follow-up: per user direction, the repo now keeps only the Android/vivo native platform shell under `apps/mobile/android/`; iOS, macOS, Windows, Linux, and Web Flutter platform shells are removed and must not be reintroduced unless the project scope changes explicitly. Flutter Dart business code, shared assets, backend, docs, and Android-specific channel tests remain in scope. Validation should focus on Android analyze/tests/APK/real device behavior. Validation passed: `uv run pytest tests/test_mobile_permission_manifests.py tests/test_mobile_notification_channel.py tests/test_mobile_voice_channel.py tests/test_mobile_location_channel.py tests/test_mobile_photo_picker_channel.py -q`; `flutter analyze --no-pub`; `git diff --check`. A full `flutter analyze` attempt timed out after 124s, while the earlier network-enabled analyze had passed before the final doc-only cleanup. GitNexus `detect_changes --repo lanxin-travelmate-aigc-2026` reported low risk with no affected execution flows.
- 2026-06-21 Android APK build follow-up: local `flutter build apk --debug --no-pub` did not finish within the local timeout, and direct Gradle `assembleDebug --stacktrace` failed because `E:\localAndroid` is missing Android SDK `platforms;android-35`. CI already installs `platforms;android-35` and `build-tools;35.0.0`; local APK validation requires installing SDK 35 or validating in CI. Do not switch to Windows/iOS/Web builds as a workaround; this project remains Android-only.
- 2026-06-21 Android permission UX follow-up: Flutter device services now preserve `lastFailureMessage` for Android photo picker/camera, location, voice recognition/TTS, and notification channels. `MainActivity` returns explicit platform error codes for denied location, microphone, and notification permissions plus unavailable voice/TTS services; PhotoPage, TripPage, ChatPage, and ReminderPage surface those messages instead of generic null/false fallbacks. Validation passed: `uv run pytest services/api/tests/test_mobile_photo_picker_channel.py services/api/tests/test_mobile_location_channel.py services/api/tests/test_mobile_voice_channel.py services/api/tests/test_mobile_notification_channel.py -q`; `flutter analyze --no-pub`; `git diff --check`. Runtime vivo permission dialogs and device service behavior still require manual validation.
- 2026-06-21 demo evidence follow-up: `docs/handoff/demo-evidence-pack.md` now provides a PPT-ready evidence package with required screenshot list, Mermaid system architecture, Agent flow diagram, real and fallback `toolTrace` examples, risk table, and suggested PPT page order. Real screenshots, screen recording, team information, and final submission upload remain manual.
- 2026-06-21 Android release preflight follow-up: added `scripts/android_release_preflight.py` to check Android-only platform scope, applicationId/namespace, version fields, local/CI SDK 35, build-tools 35.0.0, CI APK job setup, and release signing status. CI `android-apk` now installs Android SDK 35/build-tools 35.0.0 and runs strict preflight before `flutter build apk --debug`. Local validation command `python scripts/android_release_preflight.py --json` currently reports `E:\localAndroid\platforms\android-35` missing while build-tools 35.0.0 exists; final APK build/sign/install remains manual or CI validation.
- 2026-06-21 presentation/submission follow-up: `docs/handoff/presentation-outline.md` provides a 12-page PPT structure, and `docs/handoff/submission-checklist.md` provides the final repository/CI/real-provider/Android/Demo/PPT/platform submission checklist. Team info, true screenshots, video link, final PPT design, and upload confirmation remain manual.
- 2026-06-21 Docker compose preflight follow-up: added `scripts/docker_compose_preflight.py` to validate `infra/docker-compose.yml`, API-to-Postgres wiring, Postgres healthcheck, named volume, Dockerfile migration-before-server command, and optionally `docker compose config` without starting containers. Updated migration test head to `0007_add_tool_call_log_user_id`. Real `docker compose up --build` container initialization remains environment/manual validation.
- 2026-06-21 todo scope follow-up: `docs/todo.md` has been reduced to a concise remaining-human-work checklist. It now excludes completed implementation detail and only tracks external/manual requirements such as real model keys, Amap key, multi-device validation, Android/vivo device validation, SDK/signing/APK, Docker deployment validation, privacy/material approval, Demo/PPT/upload, and push authorization.

## AI 会话同步约定

- Claude Code、Codex 和其他 AI 助手新会话开始时，必须先阅读 `docs/handoff/ai-shared-state.md` 和 `docs/todo.md`，再决定是否需要读取本文件其他章节或具体源码。
- 阶段性工作结束时，必须更新 `docs/handoff/ai-shared-state.md`，只记录当前结论、下一步和必要验证状态，不同步完整聊天记录。
- 共享状态面向人工和 AI 双重阅读，保持简短中文 bullet；不要写入密钥、Token、私人位置、未授权素材或用户敏感原文。
- 详细规则见 `docs/handoff/ai-sync-protocol.md`。

## vivo AIGC 本地参考文档

- vivo AIGC 在线文档已镜像到 `docs/reference/vivo-aigc/`。
- 文档索引见 `docs/reference/vivo-aigc/README.md`。
- 全量聚合检索见 `docs/reference/vivo-aigc/all-documents.md`。
- 原始接口响应见 `docs/reference/vivo-aigc/raw-documents.json`，仅在需要核对上游字段时读取。
- 镜像来源为 `https://aigc.vivo.com.cn/#/document/index`，内容覆盖大模型、Function calling、图片/视频生成、OCR、NLP、ASR、TTS、LBS、端侧 3B 模型和端侧审核等能力。
