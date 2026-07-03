# AI 共享开发状态

> 用途：给 Claude Code、Codex 和人工成员提供同一份短上下文。新会话优先读本文件，再按需读 `docs/todo.md`、`CLAUDE.md` 和具体代码。  
> 维护口径：只写当前结论和下一步，不复述完整对话，不堆历史细节。  
> 最近更新：2026-07-04 by Codex

## 当前阶段

项目主链路代码和交接文档已经基本成型，当前重点是比赛提交前的真实能力验收、Android/vivo 真机验证、APK/部署验证、Demo/PPT/素材与平台提交。

## 当前结论

- 仓库协作上下文以 `CLAUDE.md` 为总规则，`AGENTS.md` 继续引用 `CLAUDE.md`。
- 后续 Claude Code 和 Codex 不同步完整聊天窗口，而是共同维护本文件作为项目级共享状态。
- `docs/todo.md` 只保留需要人工、真实设备、真实密钥、授权、提交确认等事项；AI 不应把 Mock 或固定样例标记为真实完成。
- 项目仍保持 Android/vivo 优先，不主动恢复 iOS、macOS、Windows、Linux、Web 平台工程。
- vivo AIGC 在线文档已镜像到 `docs/reference/vivo-aigc/`，后续接入蓝心/文本生成/ASR/TTS/LBS/端侧能力时优先读取 `README.md`、具体 `id-标题.md` 或聚合版 `all-documents.md`。
- 代码变更前要遵守现有 GitNexus/验证要求；文档类轻量变更可做 `git diff --check` 作为基本检查。

## 下一步

1. 每个新 AI 会话先读本文件，确认当前阶段、约束和下一步。
2. 如果继续做代码开发，按 `CLAUDE.md` 中的 GitNexus、测试和 Android-only 约束执行。
3. 如果继续做提交准备，优先推进 `docs/todo.md` 中真实模型、高德 Key、真机、APK、Docker、PPT、Demo 和上传确认。
4. 每次阶段性工作结束后，用 3 到 8 条短 bullet 更新本文件，保证下一位 AI 能直接接手。

## 最近日报

### 2026-07-04

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
- Added `pillow>=12.0.0` to `services/api` dependencies because submission readiness and avatar asset tests inspect PNG transparency through Pillow.
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

- 已完成首页蓝小心白底矩形的仓库内可执行修复：`apps/mobile/assets/avatars/lanxiaoxin_*.png` 运行时头像资产已批量转为带 alpha 的透明 PNG，`project/img/lanxiaoxin/` 仍保留源素材对照。
- 新增 `services/api/tests/test_mobile_avatar_assets.py`，静态检查 `AvatarState` 引用的运行时头像 PNG 必须包含真实透明像素，避免重新接入不透明白底素材。
- `scripts/submission_readiness_report.py` 已新增 `avatar_assets_transparent` 检查，把蓝小心运行时头像透明度纳入最终提交就绪总览。
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
