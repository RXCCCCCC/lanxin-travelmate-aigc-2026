# AI 共享开发状态

> 用途：给 Claude Code、Codex 和人工成员提供同一份短上下文。新会话优先读本文件，再按需读 `docs/todo.md`、`CLAUDE.md` 和具体代码。  
> 维护口径：只写当前结论和下一步，不复述完整对话，不堆历史细节。  
> 最近更新：2026-07-04 by Codex

## 当前阶段

项目主链路代码和交接文档已经基本成型，当前重点已经从模拟器切到真实设备与真实 API：先完成 vivo 文本模型、高德 Web 服务和 Android/vivo 真机联调，再继续交接、Demo 和平台提交。

## 当前结论

- 仓库协作上下文以 `CLAUDE.md` 为总规则，`AGENTS.md` 继续引用 `CLAUDE.md`。
- 后续 Claude Code 和 Codex 不同步完整聊天窗口，而是共同维护本文件作为项目级共享状态。
- `docs/todo.md` 只保留需要人工、真实设备、真实密钥、授权、提交确认等事项；AI 不应把 Mock 或固定样例标记为真实完成。
- 项目仍保持 Android/vivo 优先，不主动恢复 iOS、macOS、Windows、Linux、Web 平台工程。
- 移动端调试优先使用已连接的 Android/vivo 真机；没有真机、真机不可用或需要复现模拟器专属问题时，再使用 Android 模拟器。
- vivo AIGC 在线文档已镜像到 `docs/reference/vivo-aigc/`，后续接入蓝心/文本生成/ASR/TTS/LBS/端侧能力时优先读取 `README.md`、具体 `id-标题.md` 或聚合版 `all-documents.md`。
- 当前真实文本模型优先按 vivo AIGC `1745-大模型` 口径接入：`POST https://api-ai.vivo.com.cn/v1/chat/completions`，`Authorization: Bearer <AppKey>`，建议补 `requestId` query 参数；当前项目代码只消费 `LANXIN_LANXIN_BASE_URL`、`LANXIN_LANXIN_API_KEY`、`LANXIN_LANXIN_MODEL`。
- 当前 `services/api/.env` 若仍是 `LANXIN_MODEL_PROVIDER=mock`，代表真实模型链路尚未切换完成；用户本地会自行填写 Key，`.env` 不能提交。
- 当前用户本机 `.env` 已切到真实 provider，`uv run python scripts/real_provider_smoke.py` 最新结果为：高德天气/步行路线 `provider=amap fallback=False`，vivo 文本模型 `provider=lanxin ok=True`。
- 真机联调时 Flutter 需改用 `--dart-define=API_BASE_URL=http://<电脑局域网IP>:8000`，不能继续沿用模拟器 `10.0.2.2`。
- 这一轮先不把图片生成、视频生成、TTS、声音复刻、Function Calling 当主链路阻塞项。
- Android 当前包名已确认：`com.lanxin.lanxin_travelmate`；release 签名仍未配置，暂时继续用 debug signing，不作为当前真机联调阻塞项。
- 代码变更前要遵守现有 GitNexus/验证要求；文档类轻量变更可做 `git diff --check` 作为基本检查。

## 下一步

1. 每个新 AI 会话先读本文件，确认当前阶段、约束和下一步。
2. 用户本机真实 `.env` 已经打通，回来后直接进入真机联调，不需要重新排查高德/蓝心 key 类型。
3. 真机联调前先启动后端：`cd services/api && uv run uvicorn app.main:app --host 0.0.0.0 --port 8000`，再用局域网 IP 运行 Flutter。
4. 如果继续做代码开发，优先补 vivo 文本 provider 的 `requestId` 和兼容性处理，再按 `CLAUDE.md` 中的 GitNexus、测试和 Android-only 约束执行。
5. 如果继续做提交准备，优先推进 `docs/todo.md` 中真实模型、高德 Key、真机、APK、Docker、PPT、Demo 和上传确认。
6. 每次阶段性工作结束后，用 3 到 8 条短 bullet 更新本文件，保证下一位 AI 能直接接手。

## 当前配置与测试记忆

- 关键配置文件：`services/api/.env`；模板：`services/api/.env.example`。
- 当前第一优先真实配置只有两类：vivo 文本模型 AppKey、高德 Web 服务 Key。
- 推荐本地最小真实 `.env` 组合：
  - `LANXIN_MODEL_PROVIDER=lanxin`
  - `LANXIN_LANXIN_BASE_URL=https://api-ai.vivo.com.cn/v1`
  - `LANXIN_LANXIN_API_KEY=<本机本地填写>`
  - `LANXIN_LANXIN_MODEL=Doubao-Seed-2.0-mini`
  - `LANXIN_AMAP_API_KEY=<本机本地填写>`
- 真实模型验收命令：`cd services/api && uv run python scripts/real_provider_smoke.py`
- 最新真实 smoke 结论：高德原先误用了 Android 平台 key，换成 Web 服务 key 后已恢复正常。
- 后端定向回归：`uv run pytest tests/test_model_providers.py -q`
- 真机联调命令：`cd apps/mobile && flutter run --dart-define=API_BASE_URL=http://<电脑局域网IP>:8000`
- 真机首轮检查项：聊天真实回复、POI/天气/路线真实数据、相机/相册/定位/麦克风权限、首页稳定启动。
- 用户回来后联调优先排查的 bug 范围：手机无法访问后端、局域网 IP 配错、Android 权限弹窗异常、真实模型超时回退、页面仍出现 mock/fallback 固定样例。

## 最近日报

### 2026-07-05

- 继续排查真机反馈：纯净模式点击“规划路线”红底报错、首页蓝小心把“规划广州行程”错误生成北京行程。
- 后端确认根因之一：`trip_context_builder` 能从“规划广州行程”提取 `广州`，但 `trip_planner` 之前会直接信任模型结构化输出的 `destination/title/summary`；若真实模型漂移为“北京”，错误会穿透到回复和卡片。
- 已新增后端防线：`services/api/app/agents/travelmate/nodes/real_nodes.py` 中 `_enforce_requested_destination()` 会把明确请求目的地写回 `trip_plan.destination`，并在模型目的地不一致时替换 `title/summary` 中的错误目的地，同时校正 `planningInputs.destination`。
- 已新增回归测试：`services/api/tests/test_travelmate_graph.py::test_trip_planner_keeps_requested_destination_when_model_drifts`，模拟模型返回北京，断言最终计划仍为广州且标题/摘要不含北京。
- 验证通过：`cd services/api && .\.venv\Scripts\python.exe -m pytest tests/test_travelmate_graph.py::test_trip_planner_keeps_requested_destination_when_model_drifts tests/test_travelmate_graph.py::test_trip_context_builder_extracts_destination_from_plan_phrase tests/test_agent_api.py -q`，结果 `5 passed`。
- 移动端针对性验证通过：`cd apps/mobile && G:\develop\flutter\bin\flutter.bat test test/chat_page_integration_test.dart test/home_dashboard_test.dart`，结果 `7 passed`。
- 未解决风险：移动端测试仍打印 Drift “multiple AppDatabase” 警告，栈指向 `ChatPage.initState` 新建 `AppDatabase()`；这可能导致真机多页面/多会话状态竞争，后续应优先把 ChatPage 历史数据库依赖收敛为可注入/单例策略。
- 未完全证明的点：纯净模式“规划路线”红底 Navigator 报错尚未在自动测试中复现；现有测试覆盖了 `/chat` 内点击“规划路线”到 `/trip` 的基本跳转，但需要补更接近真实 `appRouter` 和 root overlay 的回归用例。
- 进一步补了纯净模式导航回归：`ChatPage route chip switches to trip tab after opening from shell home` 覆盖从 Shell 首页 `push('/chat')` 后点击“规划路线”，当前测试通过，说明红屏还未被这条自动路径复现。
- 修复设置页数据控制语义：`DELETE /api/trip/current` 之前会删除当前用户全部行程，已改为只删除与 `GET /api/trip/current` 一致的最新行程；新增 `test_clear_current_trip_deletes_only_latest_trip`。
- 修复设置页离线误导：`ProfilePayload.fallback()` 新增 `isFallback=true`，设置页加载 fallback 画像时显示“当前使用本机默认设置”，不再显示“已连接个人设置”；新增 `SettingsPage labels fallback profile as offline default settings`。
- 最新验证通过：`cd apps/mobile && G:\develop\flutter\bin\flutter.bat test test/chat_page_integration_test.dart test/settings_profile_service_test.dart`，结果 `8 passed`；`cd services/api && .\.venv\Scripts\python.exe -m pytest tests/test_travelmate_graph.py::test_trip_planner_keeps_requested_destination_when_model_drifts tests/test_travelmate_graph.py::test_trip_context_builder_extracts_destination_from_plan_phrase tests/test_agent_api.py tests/test_sync_and_clear_routes.py::test_clear_memory_and_current_trip_endpoints tests/test_sync_and_clear_routes.py::test_clear_current_trip_deletes_only_latest_trip -q`，结果 `7 passed`。
- 已处理 Drift 多数据库警告的核心生产路径：`ChatPage`、`SettingsPage`、`HomePage` 和 `LanXinApp._defaultRetryPendingSync()` 统一使用 `AppDatabase.shared()`；测试里需要隔离时注入 in-memory `MemoryRepository`。后续若继续重构，可再做应用级 DI，但当前真机稳定性风险已先收敛。
- 拉取远端最新 `origin/dev` 到 `03f2d71` 后，本轮本地修复已恢复到最新代码上且无冲突；补齐 `LanXinApp._defaultRetryPendingSync()` 使用 `AppDatabase.shared()`，并让 Settings profile 测试注入内存库，避免测试触碰共享真实库。
- 合并后验证通过：`cd apps/mobile && G:\develop\flutter\bin\flutter.bat test test/chat_page_integration_test.dart test/settings_profile_service_test.dart`，结果 `8 passed`；`G:\develop\flutter\bin\flutter.bat analyze`，结果 `No issues found`；`cd services/api && .\.venv\Scripts\python.exe -m pytest tests/test_travelmate_graph.py::test_trip_planner_keeps_requested_destination_when_model_drifts tests/test_travelmate_graph.py::test_trip_context_builder_extracts_destination_from_plan_phrase tests/test_agent_api.py tests/test_sync_and_clear_routes.py::test_clear_memory_and_current_trip_endpoints tests/test_sync_and_clear_routes.py::test_clear_current_trip_deletes_only_latest_trip -q`，结果 `7 passed`。
- 设置页集成测试陈旧断言已修复：`自定义 Prompt` 改为 `自定义提示词`，同步历史断言改为当前中文状态语义；验证通过 `cd apps/mobile && G:\develop\flutter\bin\flutter.bat test test/settings_page_integration_test.dart`，结果 `4 passed`。
- 最新 USB 真机 APK 已打包并安装：`flutter build apk --debug --dart-define=API_BASE_URL=http://127.0.0.1:8000` 成功，APK 位于 `apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`；首次 `adb install -r` 卡住，改用 `adb install -r -d --no-streaming ...` 安装成功。
- 真机状态：设备 `NBGYVG8T6TCAJNGY / PDYM20`，包 `com.lanxin.lanxin_travelmate` 已安装，`versionName=1.0.0`，安装时间 `2026-07-05 09:28:12`；`adb reverse tcp:8000 tcp:8000` 已配置，launcher activity 为 `.MainActivity`。位置权限已授权，相机/麦克风仍待用户在真机触发授权弹窗。

### 2026-07-04

- Android 真机 `8507100b / 23113RKC6C / Android 16` 已安装验证最新版 debug APK：首页右上“聊天历史”打开按行程归类的会话列表，顶部中间“纯净模式”进入独立聊天页，系统返回可回首页。
- 首页“展开”已替换为聊天面板顶部横向拖拽条，真机 `adb input swipe` 验证可上下调整聊天面板占比；面板内保留“规划路线 / 记忆胶囊 / 调整行程 / 生成复盘”四个快捷入口。
- 聊天历史服务会过滤旧空会话，只展示已有消息会话和当前空会话，避免多次启动或调试后在历史列表中堆积“新的对话”。
- 独立纯净模式保留为完整聊天页，标题为“蓝小心纯净模式”，头像改为蓝小心大头头像；后续人工验收可继续从首页和纯净模式两个入口分别验证会话体验。
- 新增 `docs/handoff/final-acceptance.md`，用于用户和队友按两台 Android/vivo 真机分工验收：A 线覆盖首页角色感、记忆抽取、规划推理、动态调整、旅行复盘主 Demo；B 线覆盖旅拍文案、盲盒任务、语音/TTS、通知权限、设置隐私、多设备同步和组队协同。
- 真实 provider smoke 重新通过：高德天气/步行路线 `provider=amap fallback=false`，OpenAI 兼容模型 `scenario=ci_real_provider_smoke ok=True`。
- 已修复 `/api/trip/review` 的路线边界：复盘 `route` 只使用已保存的真实路线点；没有路线点时返回空字符串，避免模型根据用户消息补出城市/行程标题并被误认为真实路线。
- 真实输出边界验证通过：`flutter analyze --no-pub`、`uv run pytest tests/test_p1_review_routes.py -q`、`tests/test_agent_api.py -q`、`tests/test_trip_plan_inputs.py -q`、`tests/test_p1_photo_content_tasks.py -q`、`tests/test_mobile_mock_boundaries.py -q`。
- Android 模拟器继续按用户反馈优化行程页表单：移除手填出发/目的地坐标，改为“定位”动作 + 目的地名称；开始/结束日期改为中文日期选择器；输入框取消浮动标签并预留固定字段名宽度和垂直间距，降低小屏输入后的重叠风险。验证通过：`flutter analyze --no-pub`、`flutter build apk --debug --no-pub --dart-define=API_BASE_URL=http://127.0.0.1:8000`，模拟器截图确认日期弹窗中文、日期回填和表单间距正常。
- Android 真机验收发现旅拍“拍摄照片”没有先申请运行时相机权限，已在 `MainActivity.kt` 增加 `CAMERA` 权限申请和授权后继续拉起系统相机的流程，并在 Manifest package visibility 中补充图片文档选择和相机 intent 查询。
- 真机允许授权路径已验证：定位可填入真实坐标；点击“拍摄照片”后出现系统相机权限弹窗，选择允许后可进入系统相机拍照界面。用户确认照片流程可以继续。
- 用户拿回真机后已切换到 Android 模拟器 `emulator-5554` 调试；最新 debug APK 安装成功，`adb reverse tcp:8000 tcp:8000` 已配置，首页同屏聊天真实后端回复通过。
- 模拟器启动期出现一次 `System UI isn't responding`，选择 `Wait` 后恢复首页；当前未见 App 崩溃。后续常规验收按用户要求模拟真实用户允许路径，不主动点击“拒绝授权”。

- Reverted runtime Lanxiaoxin avatar assets per user feedback: `apps/mobile/assets/avatars/lanxiaoxin_*.png` now match `project/img/lanxiaoxin/lanxiaoxin_*.png` byte-for-byte instead of using processed transparent variants.
- Updated avatar guardrails from transparency checks to original-material consistency checks in `services/api/tests/test_mobile_avatar_assets.py` and `scripts/submission_readiness_report.py`; removed the no-longer-needed direct `pillow` dependency from `services/api`.
- Validation passed: `uv run pytest tests/test_mobile_avatar_assets.py tests/test_submission_readiness_report.py -q`; `python -m py_compile scripts/submission_readiness_report.py`; `python scripts/submission_readiness_report.py --json --skip-git`.

- Updated `scripts/android_device_readiness_report.py` to treat Android 13+ filtering of legacy `READ_EXTERNAL_STORAGE` as an explicit platform compatibility detail instead of a package/manifest mismatch or missing runtime grant.
- Current Android readiness JSON now reports `ignoredByPlatform` and `ignoredReasons` for the legacy storage permission while keeping real missing grants for location, camera, microphone, notification, and media image access as manual pending checks.
- Validation passed: `uv run pytest tests/test_android_device_readiness_report.py tests/test_submission_readiness_report.py -q`; `python -m py_compile scripts/android_device_readiness_report.py scripts/submission_readiness_report.py`; `python scripts/android_device_readiness_report.py --json`; `python scripts/submission_readiness_report.py --json`.

- Added `competition_scoring_narrative` to `scripts/submission_package_manifest.py`, checking PPT/checklist/evidence/PRD text for judging-story coverage: innovation, application value, completion, large-model usage, technical feasibility, and demo storyline.
- The check remains manual-aware because final PPT export, team info, screenshots/video, review, and platform upload still require human confirmation; missing scoring-story coverage will now be visible in readiness JSON instead of being implicit.
- Validation passed: `uv run pytest tests/test_submission_package_manifest.py -q`; `python scripts/submission_package_manifest.py --json`; `python scripts/submission_readiness_report.py --json`.

- Added `manualPendingChecks` and `readyForUpload=false` to `scripts/submission_readiness_report.py`, separating automated preflight health from final upload readiness while manual blockers remain.
- Current readiness JSON now surfaces nested manual pending checks for Android device permissions/package mismatch and Docker config availability instead of hiding them behind aggregate `ok=true`.
- Validation passed: `uv run pytest tests/test_submission_readiness_report.py tests/test_public_submission_hygiene.py tests/test_demo_evidence_readiness.py -q`; `python -m py_compile scripts/submission_readiness_report.py`; `python scripts/submission_readiness_report.py --json --skip-git`.

- Added read-only `scripts/public_submission_hygiene.py` to check final public submission hygiene: tracked env files, local secret ignore patterns, placeholder-only `.env.example` sensitive values, public handoff text secret markers, and privacy/demo review coverage.
- `scripts/submission_readiness_report.py` now aggregates `public_submission_hygiene` as a manual-aware final submission check, keeping secret/privacy review visible beside APK, PPT, video, screenshots, and platform upload readiness.
- Validation passed: `uv run pytest tests/test_public_submission_hygiene.py tests/test_submission_readiness_report.py tests/test_mobile_privacy_boundaries.py tests/test_privacy_routes.py -q`; `python -m py_compile scripts/public_submission_hygiene.py scripts/submission_readiness_report.py`; `python scripts/public_submission_hygiene.py --json`; `python scripts/submission_readiness_report.py --json --skip-git`.

- Added read-only `scripts/submission_package_manifest.py` to track final competition package slots: code repository, Android APK, presentation deck, demo video, screenshots, API evidence, privacy/material review, and platform upload.
- `scripts/submission_readiness_report.py` now aggregates `submission_package_manifest` as a manual-aware final submission check, keeping human-only artifacts visible without marking them as automated.
- `Pillow` is no longer required for avatar readiness checks after reverting runtime avatars to byte-for-byte original materials.
- Validation passed: `uv run pytest tests/test_submission_package_manifest.py tests/test_submission_readiness_report.py tests/test_mobile_avatar_assets.py -q`; `python -m py_compile scripts/submission_package_manifest.py scripts/submission_readiness_report.py`; `python scripts/submission_package_manifest.py --json`; `python scripts/submission_readiness_report.py --json --skip-git`.

- Added read-only `scripts/demo_evidence_readiness.py` to check Demo/PPT evidence readiness without starting services, reading secrets, or inspecting media content.
- `scripts/submission_readiness_report.py` now aggregates `demo_evidence_readiness` as a manual-aware final submission check, so Demo screenshots, video, PPT, privacy, fallback, and platform upload evidence stay visible in one report.
- `docs/handoff/demo-evidence-pack.md` now explicitly labels no-key tool evidence as `fallback/unconfigured` and states social/publishing content must be confirmed by the user before publishing.
- Validation passed: `uv run pytest services/api/tests/test_demo_evidence_readiness.py services/api/tests/test_submission_readiness_report.py -q`; `python -m py_compile scripts/demo_evidence_readiness.py scripts/submission_readiness_report.py`; `python scripts/demo_evidence_readiness.py --json`; `python scripts/submission_readiness_report.py --json --skip-git`; `git diff --check` only reported LF-to-CRLF working-copy warnings.
- GitNexus `detect_changes(scope=staged)` reported low risk across 6 changed files and no affected indexed processes.
- Added `readme_runnable_handoff` to `scripts/submission_readiness_report.py`, covering root/mobile README run, validation, APK build, and Android device-channel handoff markers.
- Replaced `apps/mobile/README.md` Flutter template with Android/vivo runbook: backend URL variants, emulator/physical-device `adb reverse`, validation commands, and `photo_picker`/`location`/`voice`/`notifications` MethodChannel notes.
- Validation passed: `uv run pytest services/api/tests/test_submission_readiness_report.py -q`; `python -m py_compile scripts/submission_readiness_report.py`; `python scripts/submission_readiness_report.py --json --skip-git`; `git diff --check` only reported LF-to-CRLF working-copy warnings.
- GitNexus `detect_changes(scope=all)` reported low risk, 3 changed files, and no affected indexed processes.

- 已按用户要求撤销透明 PNG 处理：`apps/mobile/assets/avatars/lanxiaoxin_*.png` 运行时头像资产已恢复为 `project/img/lanxiaoxin/` 原始素材的逐字节副本。
- `services/api/tests/test_mobile_avatar_assets.py` 现在静态检查 `AvatarState` 引用的运行时头像 PNG 必须与原始素材一致，避免再次引入处理后的变体。
- `scripts/submission_readiness_report.py` 已将头像检查改为 `avatar_assets_match_original_materials`，把运行时头像与原始素材一致性纳入最终提交就绪总览。
- 验证通过：`uv run pytest services/api/tests/test_submission_readiness_report.py services/api/tests/test_mobile_avatar_assets.py -q`；`python scripts/submission_readiness_report.py --json --skip-git`；`python -m py_compile scripts/submission_readiness_report.py`；`cd apps/mobile && flutter test --no-pub test/avatar_states_test.dart`。
- `docs/todo.md` 已把蓝小心白底矩形从未完成项更新为已完成；最终视觉风格、素材授权、真机权限、正式签名、Demo/PPT 和比赛上传仍按人工事项保留。

### 2026-07-03

- 本轮新增只读 Android/vivo 真机就绪脚本 `scripts/android_device_readiness_report.py`，读取 adb、在线设备、SDK、设备品牌/型号、安装包路径、`adb reverse`、`dumpsys package`、Manifest/设备 requested permissions 一致性、运行时权限授权状态、launcher activity，以及相机/相册/语音识别/TTS 系统能力；脚本不安装 APK、不启动 App、不授予或撤销权限。
- `scripts/submission_readiness_report.py` 已聚合 Android/vivo 真机只读预检，并将该项保留为 manual 口径，避免把无 adb、无真机、未授权权限或交互质量问题伪装为完成。
- 新增 `services/api/tests/test_android_device_readiness_report.py`，并更新 `services/api/tests/test_submission_readiness_report.py`；验证通过：`cd services/api && uv run pytest tests/test_android_device_readiness_report.py tests/test_submission_readiness_report.py -q`，`python -m py_compile scripts/android_device_readiness_report.py scripts/submission_readiness_report.py`。
- 本机 `python scripts/android_device_readiness_report.py --json` 当前识别到 `emulator-5554`，App 已安装且系统相机/相册/语音/TTS 能力可解析；运行时权限仍未授权，且 `READ_EXTERNAL_STORAGE` 因 Android 13+ 权限映射显示为设备端差异，均按人工验收项保留。
- `docs/handoff/e2e-acceptance.md` 与 `docs/handoff/submission-checklist.md` 已补充真机只读预检命令；`docs/todo.md` 仍保留真实 vivo 交互权限验收、正式签名、素材授权、Demo/PPT 和平台上传等人工事项。

- 已按用户真机验收反馈调整 Android 前端信息架构：底部 Tab 改为“首页/行程/复盘/我的”，`/photo` 不再作为底部 Tab，而是保留为复盘记录里的旅拍入口。
- 首页已从“点击跳转聊天页”改为蓝小心同屏直聊：底部玻璃面板支持直接输入、发送到真实 Agent 服务、展示最近对话、更新蓝小心状态，并保留“展开”进入独立聊天历史页。
- 首页蓝小心人物图已先下移到底部陪伴区域，品牌和设置页已收口为中文文案；当前白底矩形来自素材本身，最终仍需透明 PNG/WebP 或抠图资产替换。
- 已补小屏/键盘适配：首页直聊输入时面板随键盘上移并压缩高度；聊天气泡增加最大宽度约束和轻量出现动画，降低重叠、过宽和留白问题。
- 真机 `8507100b` 已识别并安装最新 debug APK；`adb reverse tcp:8000 tcp:8000` 后首页直聊已验证可聚焦、键盘不遮挡、消息发送到真实后端并返回回复。
- 当前明显视觉遗留：蓝小心人物素材在首页仍有白底矩形，后续需要替换透明 PNG/WebP、抠图资产或调整素材渲染方式。
- 本地 `dev` 已 fast-forward 到 `origin/dev` 最新提交 `155c2f0`，工作区同步后保持干净。
- 已运行 `python scripts/android_release_preflight.py --json`，Android-only、包名、版本、SDK 35、build-tools 35.0.0、CI APK job 和预检链路均通过；release 仍需人工配置正式签名。
- 已运行 `python scripts/docker_compose_preflight.py --json`，Docker Compose 文件、API/Postgres 连接、健康检查、命名卷、迁移启动命令和 `docker compose config` 均通过。
- 已修复全新 Postgres 初始化时 Alembic revision id 超过默认 `alembic_version.version_num varchar(32)` 的问题；当前 head 为 `0007_tool_call_user_id`，并新增测试约束 revision id 长度不超过 32。
- 已运行 `docker compose -f infra/docker-compose.yml up --build -d`，Postgres healthy，API 容器 Up，迁移从 `0001_initial_schema` 升级到 `0007_tool_call_user_id`，容器内和宿主机 `/api/health` 均返回 ok。
- 已重新运行 `flutter build apk --debug --no-pub --dart-define=API_BASE_URL=http://127.0.0.1:8000`，Android debug APK 构建通过，产物为 `apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`。
- 已在 Android 模拟器 `emulator-5554` 安装最新 debug APK，执行 `adb reverse tcp:8000 tcp:8000` 后完成首页启动、聊天页打开、键盘不遮挡输入栏和 `/api/agent/chat` 真实联调验收；截图保存在 `E:\tmp\lanxin_home_latest_2.png`、`E:\tmp\lanxin_chat_open_latest.png`、`E:\tmp\lanxin_current_after_input_timeout.png`。
- 已修复真实模型输出兼容问题：`TripPlanningOutput.alternatives` 支持真实模型返回字符串列表，`recommendedScope` 支持 `shortTerm` 等别名，最终聊天响应会合并 companion chat、模型记忆抽取和规则候选，不再覆盖前序记忆。
- 已调整 `infra/docker-compose.yml` 读取 `services/api/.env` 的真实模型/高德配置，并保留 Postgres 数据库连接覆盖；宿主机 `127.0.0.1:8000` Docker API smoke 验证记忆抽取、规划推理、旅行复盘、角色化对话均为真实 Provider `fallback=false`，工具 provider 包含 `amap`。
- `docs/todo.md` 已更新：删除已完成的预检、Docker 实际启动和模拟器最新 APK 启动待办，只保留真机权限验收、最终 APK/签名、公网部署、隐私素材确认、Demo/PPT 和比赛上传等人工事项。
- 下一步 AI 可继续完善真机验收辅助脚本、Demo 证据包和前端展示细节；Android 真机、正式签名、素材授权、公网部署和比赛提交仍需负责人介入。

### 2026-06-29

- Android 模拟器验收已完成一轮：debug APK 构建、安装、`adb reverse tcp:8000 tcp:8000`、首页启动、聊天页真实后端回复均通过；截图保存在 `E:\tmp\lanxin_after_timeout_fix_home.png` 和 `E:\tmp\lanxin_chat_real_reply.png`。
- 本轮定位到聊天离线降级根因：真实 `/api/agent/chat` 在 OpenAI 兼容 Provider 路径下约 28 秒返回，而移动端 `receiveTimeout` 只有 8 秒；已将 API client 超时调整为 connect/send 10 秒、receive 45 秒。
- Android 模拟器仍有 debug 冷启动偏慢现象，首页最终可渲染；后续录制 Demo 建议使用真机或 profile/release APK 验证启动体验。
- `flutter test --no-pub test\auth_session_service_test.dart` 未完成，原因是本机 native assets 钩子下载 Windows `sqlite3.x64.windows.dll` 超时；不要为此恢复会破坏 Android 的 `sqlite3` system hook。
- 已推送 `dev` 到远端；最新提交以 `git log --oneline -1` 为准，避免状态文档提交后哈希反复过期。
- 真实 Provider smoke 已通过：高德天气/步行路线 `provider=amap fallback=false`，OpenAI 兼容模型连通 `ok=True`。
- 真实高德工具已补验 POI、驾车、公交、混合路线，结果均为 `provider=amap fallback=false`；计费额度、可展示授权和 Android 真机展示仍需人工确认。
- 已增强 OpenAI 兼容/蓝心模型 JSON schema prompt，并归一化旅拍文案真实输出别名；`/api/photo/copywriting` 真实验证为 `provider=openai_compatible fallback=false`。
- 已补齐 Agent、行程规划/复盘、旅拍文案等模型调用审计落库；定向测试验证 `/api/audit/model-calls` 可读到直连路由记录且请求摘要不泄露敏感原文。
- 真实模型剩余风险：角色化对话/规划在外部模型慢响应时仍可能 timeout fallback；最终演示数据库仍需人工确认五类真实场景 `fallback=false`。
- 后端真实 provider 兜底链路已清理：`real_nodes.py` 去掉重复解析 helper，运行时回复、提醒、照片候选和行程调整不再固定写死重庆/洪崖洞。
- 已补回归测试验证“周末想去杭州两天，不想太累，喜欢夜景”能提取杭州、轻松节奏和夜景偏好。
- 已做后端针对性验证：`py_compile` 通过，5 个 provider/graph 定向 pytest 通过；HTTP smoke 显示杭州聊天和行程规划不再落回重庆样例。
- 剩余真实模型风险：外部 provider 仍可能超时或失败，但离线 fallback 已保持输入目的地驱动，不伪装固定样例。
- 已从 `https://aigc.vivo.com.cn/#/document/index` 抓取 vivo AIGC 文档中心接口数据。
- 本地知识库位置：`docs/reference/vivo-aigc/`。
- 已保存 22 篇文档，包括大模型、Function calling、图片/视频生成、OCR、NLP、ASR、TTS、LBS、端侧 3B 模型和端侧审核。
- `raw-documents.json` 保留原始接口响应，`all-documents.md` 便于全文检索，`README.md` 提供索引。

### 2026-06-28

- 建立 Claude Code 与 Codex 共用的项目级状态同步方案。
- 采用低摩擦 Markdown 维护方式，不新增强制脚本或 MCP 服务。
- 共享状态放在 `docs/handoff/ai-shared-state.md`，同步规则放在 `docs/handoff/ai-sync-protocol.md`。
- 目标是让新会话先读短状态，再按需读代码，减少重复全仓库扫描。

## 未决人工事项

以 `docs/todo.md` 为准。本文件不重复维护完整待办清单。
## 2026-07-03 UI 验收补充

- 已按用户反馈继续微调 Android 首页与设置页：底部 Tab “我的”改为“设置”，设置页首屏隐藏接口路径和内部英文枚举；首页右侧状态气泡使用固定间距，左侧“当前旅程”和天气/工具气泡下移拉开，避免贴边重叠。
- 验证：`flutter analyze --no-pub` 通过，`flutter build apk --debug --no-pub --dart-define=API_BASE_URL=http://127.0.0.1:8000` 通过；模拟器 `emulator-5554` 可安装运行并确认首页气泡间距。模拟器期间出现 System UI ANR/网络时间服务异常，日志未见 App 崩溃；设置页中文化已由真机截图确认。
- 已新增只读提交就绪总览脚本 `scripts/submission_readiness_report.py`，聚合 Git 工作区、Android-only 平台壳、关键交接文档、todo 人工口径、Android 预检和 Docker Compose 预检；不会启动服务、构建 APK、读取密钥值或修改文件。
- 新增 `services/api/tests/test_submission_readiness_report.py`，验证总览脚本覆盖关键交付文档、预检入口和人工阻塞项。验证通过：`cd services/api && uv run pytest tests/test_submission_readiness_report.py -q`；`python scripts/submission_readiness_report.py --json --skip-git` 当前结构/文档/预检项通过。
- 提交就绪总览已补强为显式检查 PRD P0 演示闭环和比赛提交材料覆盖；README、端到端验收清单和最终提交清单已同步去掉“Mock 主线”旧口径，改为真实 Provider + 明确降级边界。
- 验证通过：`cd services/api && uv run pytest tests/test_submission_readiness_report.py -q`；`python scripts/submission_readiness_report.py --json --skip-git`；`python -m py_compile scripts/submission_readiness_report.py`；`git diff --check` 仅提示 Git 将 LF 转 CRLF 的换行警告。
- 对照 PRD 与比赛要求，仍未完成项保留在 `docs/todo.md`：真实模型效果人工验收、地图/天气展示授权、vivo/Android 设备权限验收、蓝小心最终透明/授权素材、release 正式签名、公网部署、真实 Demo/PPT/视频和比赛平台提交。

## 2026-07-04 真机调试补充

- 新真机 `8507100b / 23113RKC6C / Android 16` 已确认可被 Flutter 识别，可直接 `adb install` 安装 debug APK，`adb reverse tcp:8000 tcp:8000` 可用于连接本机后端。
- `flutter run -d 8507100b --dart-define=API_BASE_URL=http://127.0.0.1:8000` 已进入 resident 调试状态并提供热重载命令；此前失败根因是后台 PowerShell 启动命令未正确切换到 `apps/mobile`。
- 本轮真机截图确认首页已显示新版“蓝心同行”名称，首页直聊面板、天气卡片和四个快捷入口无明显溢出；后续验收优先使用该真机，旧 vivo 仅保留为兼容性抽检设备。
- 继续按用户反馈修复首页与提醒链路：首页“消息”入口进入“主动提醒”中心；提醒卡片、画像摘要、触发类型和系统通知正文已做中文归一化，避免真实模型/后端返回英文时污染用户界面。
- 首页天气卡已通过真机定位 + 高德天气验证，当前可展示真实区县、天气和温度；后端高德坐标入参已优先使用真实 longitude/latitude，并在缺少 lastKnownLocation 时由 Android 请求一次实时定位。
- 首页直聊改为共享 `HomeChatController` 状态：Agent 思考中继续输入会加入下一轮思考，停止生成会取消当前请求并用短暂状态提示反馈，切到其他页面后首页会话状态不再被局部 Widget 生命周期直接丢弃。
- 首页纯净模式已改为同页动画切换：左上模式气泡变大且文案为“切换到纯净模式/切换到陪伴模式”，当前旅程/天气/右侧状态组整体上移；进入纯净模式时保留模式、当前旅程、聊天历史和消息入口，天气与状态气泡左右滑出，聊天面板上沿贴近当前旅程下方，蓝小心立绘隐藏，不再直接跳到独立聊天页。
- 验证：`flutter analyze --no-pub` 通过，Android debug APK 构建通过；真机 `8507100b` 已安装并截图确认普通模式与纯净模式布局，截图位于 `E:\tmp\lanxin_home_switch_text.png`、`E:\tmp\lanxin_home_pure_panel_top_3.png`。
- 已继续按真机反馈修复首页验收问题：`当前旅程` 气泡可进入行程页，天气文案改为多行完整展示，右侧默契/心情/精力气泡上移到消息入口下方；首页直聊在 Agent 思考时追加蓝小心头像与“正在思考中......”循环状态，用户消息头像右对齐。
- 底部四个 Tab 已支持收起为图标栏并保留展开按钮，降低首页聊天面板被导航占用的高度；设置页新增“登录账户”入口和账户设置/升级登录操作，正式手机号/短信/OAuth 登录仍待账号体系人工确认后接入。
- 验证：真机 `8507100b` 已安装最新 debug APK，`adb reverse tcp:8000 tcp:8000` 连接本机 FastAPI；截图确认普通模式、纯净模式、思考态、设置页账户入口和底部导航收起状态，截图位于 `E:\tmp\lanxin_home_verify2.png`、`E:\tmp\lanxin_thinking_verify.png`、`E:\tmp\lanxin_settings_account.png`、`E:\tmp\lanxin_nav_collapsed_2.png`。

## 2026-07-05 UI 验收补充

- 按用户反馈继续压缩 Android 首页气泡占比：删除“等待真实行程”气泡，顶部改为左侧“切换到纯净/陪伴模式”与右侧消息、聊天历史两个 icon-only 入口，天气改为“区县 天气 温度”长条，右侧蓝小心属性改为可收起状态抽屉。
- 首页聊天面板进一步降低初始高度并去掉标题行，四个快捷入口改为等宽紧凑按钮，避免“生成复盘”被右边界裁切；蓝小心立绘露出面积比上一版更大。
- 底部导航默认展开，用户点击后完整收起为中间展开按钮，并通过 `path_provider` 写入应用支持目录持久保存；全局 Shell 支持左右滑动切换首页、行程、复盘、设置 Tab。
- 真机 `8507100b` 已验证首页收起态、状态抽屉展开态和左右滑动进入行程页；截图位于 `E:\tmp\lanxin_swipe_home.png`、`E:\tmp\lanxin_swipe_trip.png`、`E:\tmp\lanxin_status_drawer.png`。
- 用户拿走真机后已切回 Android 模拟器 `emulator-5554`，最新 debug APK 安装成功，`adb reverse tcp:8000 tcp:8000` 已配置；模拟器当前反复出现系统级 `Process system isn't responding` 弹窗，布局可从遮罩背后确认，但不作为 App 崩溃结论。
- 已按用户要求拉取并合并远端最新 `origin/dev`，保留当前首页 UI：纯净模式仍在首页内切换，不采用远端提交里的跳转独立聊天页行为；其他远端变更正常保留。
- 后续真机/模拟器验收语料尽量使用中文和中国境内出行场景；若 ADB 无法稳定输入中文，可临时用拼音或英文表达同一国内场景，最终人工验收仍以中文体验为准。
