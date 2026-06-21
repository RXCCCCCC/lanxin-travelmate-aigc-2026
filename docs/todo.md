# 蓝心同行 Todo：真实产品完善计划

> 更新时间：2026-06-20
> 依据：`docs/product/PRD.md`、`docs/product/开发路线(ai看).md`、当前仓库实现状态。
> 口径：本文件只保留未完成事项；现有 Flutter/FastAPI/LangGraph 骨架、演示闭环、移动端适配和基础文档不再重复记录。

## 总原则

- 主链路必须使用真实模型、真实用户数据、真实设备能力或真实第三方 API；Mock/固定样例只允许作为异常降级，不计入完成验收。
- AI 可完成的部分默认连续推进；涉及账号密钥、真机权限、素材审美、证书、推送远程、删除文件、比赛提交等事项必须人工确认。
- 每完成一个阶段后同步更新本文件、README/API 文档、必要测试，并刷新 GitNexus 索引做影响分析。

## 阶段 1：真实模型与 Agent 主链路

目标：把当前 Mock Agent 升级为真实模型驱动的结构化 Agent。

- 🚧 接入真实 `LanxinModelProvider`，并保留 OpenAI 兼容 Provider 作为可选后备；代码接口已接入，待真实密钥联调。
- 🚧 为聊天、记忆抽取、规划、旅拍文案、复盘生成建立中文 Prompt 与 JSON Schema 校验；已新增通用 Prompt/模型输出 schema，规划节点已校验 `TripPlanningOutput` 并在 schema 无效时降级记录 `schema_validation`，待扩展到聊天、记忆抽取、旅拍文案和复盘节点。
- 🚧 将 `mock_nodes.py` 拆为真实节点、降级节点和共享 schema，节点输出必须可验证；已先接入 Provider 工厂、规划节点 schema 校验和降级日志。
- ✅ 增加模型调用日志：provider、耗时、错误码、降级原因、脱敏请求摘要。
- ⬜ 完成真实蓝心模型效果验证记录：记忆抽取、规划推理、角色化对话、文案生成、多模态理解。

人工介入：蓝心 API 地址、鉴权方式、密钥、模型名、额度；如使用 OpenAI 兼容服务，也需提供 base URL、模型名和密钥。

## 阶段 2：真实后端数据与同步

目标：后端从 placeholder 路由升级为可持久化、可同步的数据服务。

- 🚧 用 PostgreSQL/SQLModel 落地用户、记忆、画像、旅程、提醒、照片、复盘、模型日志、工具日志、同步记录；已完成核心表扩展与记忆/画像/当前旅程持久化，复盘生成、提醒触发历史、工具调用日志基础写库已补；照片候选、上传元数据、文案结果、盲盒任务状态、真实路线轨迹点和蓝小心状态事件已写库，复盘已可聚合已完成盲盒、可复盘照片、提醒历史、真实轨迹、状态变化、本次旅程记忆沉淀和基于这些上下文生成的下次旅行建议；端侧读取提醒/复盘/盲盒状态/蓝小心状态事件/真实轨迹摘要已接入。
- 🚧 增加数据库迁移方案，保证 Docker/Postgres 与本地开发库结构一致；已补 Alembic 初始迁移、提醒事件、多人协调、盲盒任务状态、路线轨迹和蓝小心状态事件迁移、Postgres 驱动、Docker 启动前迁移和健康检查；真实 Postgres 容器启动验收、生产迁移回滚策略待继续。
- ✅ 替换 `/api/memory`、`/api/profile`、`/api/trip/current` 等 placeholder 路由为真实数据接口。
- 🚧 实现游客用户、设备 ID、会话 ID、最小鉴权和同一用户数据关联；已完成游客、注册、登录、Bearer token、`users/me`、端侧稳定设备 ID、自动游客会话创建和 Dio Bearer 注入；正式 JWT、账号迁移策略和真实多设备验收待继续。
- 🚧 实现端侧 Drift 与后端云端数据同步：全量同步、选择性同步、冲突检测、合并记录；后端 `push/pull/selected-memory/revoke` 已完成，`push` 支持 `updatedAt` 冲突检测与 `serverWins/clientWins` 策略，`revoke` 支持撤销云端记忆/画像/旅程副本；设置页已接入画像、指定记忆和指定旅程撤销入口，并补齐基础冲突检测与本机覆盖云端入口；端侧已新增 Drift 本地同步队列，记忆新增/编辑/删除会入队，设置页会优先消费 `memory/upsert` 队列和 `memory/delete` 撤销队列，按成功/失败更新状态，并展示最近同步历史；记忆页已支持选择本地记忆后只同步已选条目；App 启动和回到前台时会自动重试 pending 队列。剩余工作集中在正式账号/设备 ID 接入和真实环境同步验收。
- ✅ 增加清空本次旅行数据、清空全部记忆、导出个人数据接口。

人工介入：如果要接入正式账号体系，需要确认登录方式、隐私策略和是否允许游客数据迁移到云端。

## 阶段 3：地图、天气、POI、路线真实化

目标：规划和提醒引用真实外部环境，不再固定重庆样例。

- 🚧 使用真实高德 Key 完成天气、POI、步行路线联调；代码已接入高德 Provider 和无 Key 明确降级，待人工提供 Key 后验收真实数据。
- 🚧 扩展路线能力到公交、驾车或混合路线；后端高德 Provider 已支持 `mode=driving/transit/mixed`，可输出换乘、费用、拥堵段、红绿灯和备选方案；真实 Key 联调、端侧选择出行方式和生产数据验收待继续。
- 🚧 前端传入真实定位坐标、目的地坐标和用户选择的出行方式，避免后端只能按城市/关键词粗查；规划页已支持手动输入当前位置/目的地坐标并随 `/api/trip/plan` 传入 `originCoordinate`、`destinationCoordinate`，后端已写入 `planningInputs`，Agent 工具规划会将坐标转换为 `route_tool.originLocation/destinationLocation` 并带入所选 `transportMode`。剩余为接入真实定位/地图选点和真机权限验收。
- 🚧 增加工具熔断、限流、持久缓存和 toolTrace 错误可视化；高德 Provider 已有进程内缓存、SQLite 持久缓存、一次 HTTP 重试、连续失败熔断、本地限流和 `retryCount/cacheHit/circuitOpen/errorType/rateLimited/retryAfterSeconds` 元数据，Agent `toolTrace` 已展开错误可视化字段；真实 Key 联调与生产级分布式限流待继续。
- 🚧 将天气预警、营业时间、POI 坐标和路线耗时真正写入规划解释、主动提醒和复盘；后端规划卡已汇总 `toolTrace` 中的天气、POI 和路线结果到 `externalContext`，并把天气提示、营业时间和路线耗时写入画像匹配/风险提示；提醒页已调用 `/api/trip/reminders/evaluate` 并带入画像主动程度/偏好，复盘生成已可接收并展示画像上下文；真实 Key 数据验收待继续。

人工介入：提供高德 API Key，确认计费/额度和可展示的数据来源；若改用百度/腾讯，需要确认服务商并替换 Provider。

## 阶段 4：Flutter 去 Mock 与真实设备能力

目标：移动端页面由真实 API、本地数据库和设备能力驱动。

- 🚧 移除主页面对 `apps/mobile/lib/data/mock_data.dart` 的主链路依赖；聊天、记忆、规划、提醒、复盘和画像页已不再用固定样例支撑空状态，共享 UI 类型已迁到 `shared/models/travelmate_models.dart`，`mock_data.dart` 仅保留离线样例/测试 fixture；首页已移除“演示模式”与固定重庆聊天片段，聊天页已改用本地生成的真实会话/旅程 ID，旅拍候选/盲盒列表读取失败不再返回固定样例；剩余为个别共享卡片和测试 fixture 边界复查。
- 🚧 少量离线降级继续清理；首页改为真实联调入口态，聊天页改为真实 Agent 欢迎态，记忆/规划/提醒/复盘页在无真实数据时展示加载、空状态、错误或重试入口，不再渲染固定杭州/样例复盘/样例提醒；画像页真实读取和编辑 `/api/profile/me`，设置页的人格、主动程度、同步策略、通知、语音/文字偏好、自定义 Prompt、隐私摘要、记忆导出、清空记忆、清空当前旅行和撤销云端画像同步已接入真实后端接口。
- 🚧 画像变更后影响规划、提醒和复盘的端到端展示已完成基础链路：规划页会把预算、交通偏好、兴趣、饮食忌口和节奏画像带入 `/api/trip/plan`；提醒页会把主动程度、节奏、兴趣和饮食偏好带入 `/api/trip/reminders/evaluate` 并展示画像上下文；复盘页会把画像上下文带入 `/api/trip/review` 并展示引用画像。剩余为真实模型/真实 Key/真机环境下的端到端验收。
- 🚧 规划页支持任意目的地、日期、预算、同行人和偏好，不再固定演示路线；后端 `/api/trip/plan` 已接收并持久化 `destination/startDate/endDate/budget/companions/preferences/transportMode/tripStyle/replanReason`，计划响应包含 `planningInputs`；端侧已新增真实规划表单和 `TripPlanService`，可提交目的地、日期、预算、同行人、偏好、交通方式和画像偏好并展示返回计划；天气变化重规划入口已接入并传 `replanReason=weather_risk`。规划页已支持坐标字段传入，后端路线工具计划已消费坐标，剩余为真实定位/地图选点、真实 Key 环境验收。
- 🚧 接入定位、照片选择、相机、通知、麦克风、语音播放、权限拒绝处理；后端 ASR/TTS 任务接口和日志已完成；旅拍页已可通过真实后端登记上传元数据和照片候选，且明确不保存设备本地路径；端侧系统选择器/相机/通知/定位/语音权限与真实语音能力待继续。
- 🚧 补齐加载、空状态、权限拒绝、网络失败、降级说明和重试入口；规划/记忆/提醒/复盘已补真实空状态、加载/错误提示和重试入口，旅拍已有空状态/重试，剩余为设备权限拒绝、通知/定位/相机/麦克风真实失败分支。

人工介入：Android/vivo 真机或稳定模拟器权限测试；提供真实照片素材；确认通知、定位、相册、相机、麦克风权限文案。

## 阶段 5：完整产品能力闭环

目标：达到 PRD 中“完整作品功能标准”的可体验闭环。

- 🚧 记忆胶囊闭环：后端已支持记忆 CRUD/同步，并可按 `sourceText=tripId` 将本次旅程确认记忆写入复盘 `newMemories`、将临时记忆生成长期沉淀建议；真实模型抽取质量、端侧确认范围/画像更新/规划引用展示待继续。
- 🚧 个性化规划闭环：创建旅行、生成方案、解释画像匹配、用户修改后重新规划、保存旅程；后端已支持同一 `tripId` 重规划、保存日期/预算/同行人/风格并把预算/交通方式/偏好/重规划原因写入 `profileMatches/risks`，端侧修改入口和真实模型增强待继续。
- 🚧 主动情境提醒：由时间、位置、天气、行程节点或状态触发，具备冷却和主动程度控制；后端已支持 `/api/trip/reminders/evaluate` 自动评估时间/位置/状态/外部事件、按主动程度过滤、45 分钟冷却和历史落库；提醒页已读取画像主动程度/偏好并调用 evaluate，且可展示 dashboard 提醒历史；定时/真实定位/系统通知调用和真机验收待继续。
- 🚧 旅拍候选集：后端候选/上传元数据/文案持久化已完成，旅拍页已接入候选读取、上传元数据登记、候选创建和文案生成，并提示本地路径不会上传保存；真实系统选图/拍照、多模态分析、标签评分增强和复制/分享前确认待继续。
- 🚧 旅行盲盒任务：后端已支持接受、跳过、完成、状态奖励落库、蓝小心状态事件写入和已完成任务进入复盘；旅拍页已新增端侧真实入口，可对任务执行接受/完成/跳过并同步 `/api/trip/blind-box/tasks/{taskId}/status`。旅拍页已展示完成任务后的好感/默契奖励数值。剩余为奖励动画和复盘页更深入展示。
- 🚧 旅行复盘：后端已持久化生成结果，并可聚合真实路线轨迹、可复盘照片、已完成盲盒任务、提醒历史、蓝小心状态事件、本次旅程记忆沉淀、画像上下文和下次旅行建议；端侧已读取 dashboard/latest review、状态事件和画像上下文。剩余为真实模型增强文案、更多真实状态触发和真机/真实数据验收。
- 🚧 多人出游协调：后端已支持至少 2 名成员真实偏好输入、冲突识别、折中方案、隐私汇总和按 `tripId` 读回；规划页已新增端侧协调入口，可提交成员偏好并展示折中方案/冲突/隐私汇总，生成规划时会把 `groupCoordination` 写入 `/api/trip/plan` 并进入 `planningInputs/profileMatches`。剩余为真实模型增强解释和真实多人数据验收。
- ⬜ 蓝小心表达：导入多表情/动作素材，完成状态到 Lottie/GIF/WebP 动作映射。

人工介入：确认蓝小心最终视觉风格和可用素材；决定是否进入 Live2D；确认 Demo 使用的真实目的地、照片、路线和用户画像。

## 阶段 6：安全、隐私与合规

目标：让真实数据可放心演示和提交。

- 🚧 增加隐私说明、权限用途说明、记忆保存规则说明；后端 `/api/privacy/summary`、工程文档和设置页端侧展示入口已完成，最终公开文案待人工确认。
- 🚧 敏感记忆识别策略：身体状态、位置、同行人信息已标记 `sensitive`，饮食忌口已标记 `personal`，均要求显式确认；端侧分级展示和最终隐私文案待继续。
- 🚧 云端请求参数最小化和脱敏；后端模型调用日志已脱敏密钥、Token、密码、用户原文和超长文本，照片候选/上传元数据已避免保存和返回设备本地 URI/路径；端侧日志、真实照片/音频内容审计待继续。
- 🚧 多人模式默认隐藏个人敏感偏好，仅展示汇总后的协调依据；后端多人协调接口已隐藏敏感偏好原文，端侧展示规则和公开隐私文案待继续。
- 🚧 增加清空数据、撤销同步、导出数据等用户可控入口；后端已支持清空本次旅行、清空全部记忆、导出记忆和撤销云端同步，设置页已接入记忆导出、清空记忆、清空当前旅行和撤销云端画像同步；设置页已补齐按 ID 撤销指定记忆或旅程的细粒度 UI、基础冲突检测/本机覆盖入口、Drift `memory/upsert` 同步队列消费、`memory/delete` 撤销队列消费和最近同步历史展示；记忆页已支持选择性同步本地记忆；App 启动和回到前台时会自动重试 pending 队列。

人工介入：比赛提交或公开演示前最终确认隐私策略、权限说明、素材授权和对外表述。

## 阶段 7：工程质量、部署与交付

目标：可构建、可测试、可部署、可交接。

- ⬜ 为真实 Provider、工具服务、数据库同步、端侧权限和核心闭环补单元/集成测试。
- 🚧 Docker Compose 已配置 API 指向 Postgres、Postgres healthcheck、API 启动前 `alembic upgrade head`；待人工/CI 环境执行 `docker compose up` 验证真实容器初始化。
- 🚧 GitHub Actions 已接入真实 Provider 可选 smoke job 与密钥泄露静态检查；待人工配置 GitHub secrets 后在 CI 环境验收真实模型/高德连通性。
- ⬜ Android APK 构建通过，确认 SDK、包名、签名、版本号和安装测试。
- ⬜ 更新 README、API 契约、技术设计、Agent 图和交接文档，反映真实数据链路。
- ⬜ 清理过时文件、生成缓存和无用样例，控制仓库体积。

人工介入：Android SDK/签名证书/应用包名；GitHub secrets；删除文件前确认；是否部署域名、HTTPS 和服务器。

## 阶段 8：比赛材料与最终演示

目标：形成可提交、可答辩、可复现的作品包。

- ⬜ 录制真实链路 Demo：记忆确认、真实规划、主动提醒、旅拍文案、复盘。
- ⬜ 完成 PPT/答辩材料，突出创新性、应用价值、完成度和大模型应用说明。
- ⬜ 生成 App 截图、接口截图、架构图、toolTrace 示例和风险说明页。
- ⬜ 检查提交包：作品名称、团队介绍、代码仓库、PPT、视频、文档一致。

人工介入：团队信息、提交模板、录屏环境、最终审稿、比赛平台账号和上传确认。

## 人工配置总表

| 类别 | 必须提供/确认 |
| --- | --- |
| 模型 | 蓝心 API 地址、密钥、模型名、额度；可选 OpenAI 兼容服务配置。 |
| 地图天气 | 服务商选择、API Key、计费/额度、允许展示的数据来源。 |
| 真机权限 | vivo/Android 测试设备，定位、相册、相机、麦克风、通知权限验证。 |
| 视觉素材 | 蓝小心最终立绘、多表情、多动作素材；是否做 Live2D。 |
| 发布构建 | Android 包名、签名证书、版本号、APK 安装验证环境。 |
| 远程配置 | GitHub Secrets、服务器/域名/HTTPS，如需部署。 |
| 合规提交 | 隐私说明、素材授权、Demo 数据、PPT/视频/提交包最终确认。 |

## 推荐执行顺序

1. 先接真实模型与后端持久化，打掉最大 Mock 风险。
2. 再接地图天气 POI 路线，让规划和提醒变成真实产品能力。
3. 接着移动端去 Mock、补设备权限和真实照片/通知/语音能力。
4. 最后做多人协调、蓝小心动作、工程验收、APK 和比赛材料。

## Backend aggregation follow-up

- Flutter already has `TripDashboardService` for `GET /api/trip/dashboard` with offline fallback. HomePage shows dashboard trip/memory/reminder summary; TripPage loads `currentTrip.plan` when no live Agent plan exists, displays dashboard `routePoints` as real trajectory summary, and can submit `/api/trip/plan` with user-entered fields plus profile-derived budget/transport/preference context; ReminderPage displays `reminderHistory.items` and evaluates `/api/trip/reminders/evaluate` with profile context; PhotoPage reads `photoCandidates` and `blindBoxTasks`; ReviewPage prefers dashboard `latestReview` before generating a new review and can render dashboard `avatarStateEvents` as status changes; MemoryPage merges local Drift memories with dashboard `memories`, shows a real empty state when no memory exists, and can sync only selected local memories; ProfilePage reads and edits `/api/profile/me` through `ProfileService`, and SettingsPage reads/writes persisted profile settings plus privacy/data-control endpoints through `SettingsDataService`, including selected memory/trip revoke by ID, basic conflict detection/client-wins resolution, Drift `memory/upsert` pending queue consumption, Drift `memory/delete` revoke queue consumption, local sync history display, and app lifecycle pending-queue retry. TripPage also has a group-coordination entry backed by `/api/trip/group/coordinate`, with tests for request mapping and UI result rendering. Remaining frontend work focuses on real-model group coordination explanation, device permissions, true photo picker/camera integration, true scheduled/location/notification reminder triggers, remaining fixture/shared-card boundary checks, and real-provider validation. Real-provider keys remain separate manual integration work.
