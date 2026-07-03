# 蓝心同行 Todo：剩余人工介入清单

> 更新时间：2026-07-03
> 口径：本文件只保留当前无法由 AI 在仓库内独立完成的事项。已完成的 FastAPI/LangGraph/Flutter Android 主链路、真实数据接口、结构化 Provider 接口、审计、端侧设备通道、CI/预检脚本、交接文档不再重复列为待办。

## 总原则

- 主链路验收必须使用真实模型、真实用户数据、真实设备能力或真实第三方 API；Mock/固定样例只允许作为异常降级，不计入完成验收。
- 仓库和远端 `dev` 只保留 Android/vivo 原生平台壳；不要恢复 iOS、macOS、Windows、Linux、Web 平台工程。
- 涉及账号密钥、真机权限、正式签名、素材授权、推送远程、删除素材、比赛上传等事项必须由负责人确认。
- 真实 API、发布、部署和提交配置按 `docs/handoff/config-implementation-checklist.md` 逐项执行。
- AI 后续如继续开发，必须同步更新 `CLAUDE.md`、本文件和相关交接文档，并在提交前运行 GitNexus `detect_changes`。

## 1. 真实模型验收

- [x] 已配置 OpenAI 兼容真实模型，并运行 `cd services/api && uv run python scripts/real_provider_smoke.py`；结果为 `provider=openai_compatible ok=True`。
- [x] 已验证真实旅拍文案接口：`/api/photo/copywriting` 返回 `provider=openai_compatible fallback=false`，朋友圈/小红书/日记/Vlog/复盘建议字段齐全。
- [x] 已修复真实 Agent 输出兼容问题，并通过 Docker API 验证记忆抽取、规划推理、旅行复盘、角色化对话均为真实 Provider `fallback=false`。
- [ ] 人工验收五类真实模型效果质量：记忆抽取、规划推理、角色化对话、旅拍文案、旅行复盘是否符合比赛演示口径。
- [x] 已补齐 Agent、行程规划/复盘、旅拍文案等模型调用审计落库，并通过 `GET /api/audit/model-calls` 定向测试验证请求摘要不泄露敏感原文。
- [ ] 最终演示数据库中人工确认五类真实场景 `fallback=false`，并再次检查日志不含密钥、Token、密码或完整敏感原文。

## 2. 地图、天气、POI 与路线真实化

- [x] 已提供并配置高德 API Key。
- [ ] 确认计费额度、可展示的数据来源和比赛演示是否允许展示第三方地图/天气数据。
- [x] 已使用真实 Key 验证天气、POI、步行、驾车、公交、混合路线；工具结果均为 `provider=amap fallback=false`。
- [ ] 在 Android 规划页真机确认 `toolTrace` 展示真实 provider 且 `fallback=false`；无 Key 或异常时必须明确显示 `fallback/unconfigured`。

## 3. 多设备与云同步验收

- [ ] 决定正式账号体系是否只保留游客升级密码账号，还是接入手机号/短信/OAuth。
- [ ] 确认旧游客 token 失效策略、设备 ID 绑定策略和多设备冲突合并规则。
- [ ] 使用至少两台设备或两个独立会话验证：注册/登录、游客升级、记忆同步、选择性同步、撤销云端同步和冲突处理。
- [ ] 验证同一 Bearer 用户下 profile/memory/trip/photo/review/reminder 数据不会串到其他用户。

## 4. Android/vivo 真机能力验收

- [x] 稳定 Android 模拟器验收环境已准备；最新 debug APK 已安装启动，首页和聊天页真实后端联调通过，审计日志可见 `openai_compatible`/`amap` 调用记录。
- [ ] 准备 vivo/Android 真机做最终设备能力验收。
- [ ] 验证相册选择、相机拍摄、定位、麦克风、系统语音识别、中文 TTS、Android 13+ 通知权限和通知展示。
- [ ] 验证拒绝权限时页面展示明确中文提示，不白屏、不卡死、不写入伪造数据。
- [ ] 准备真实可展示照片素材，确认素材授权和隐私边界。
- [ ] 如需地图选点或更高定位精度，确认使用哪种地图 SDK/服务并提供对应 Key。

## 5. Android APK 与发布配置

- [x] 本机已在 `E:\localAndroid` 安装 Android SDK `platforms;android-35` 与 `build-tools;35.0.0`。
- [x] 已运行 `python scripts/android_release_preflight.py --json`，确认 Android-only、包名、版本号、SDK、build-tools、CI APK job 和签名状态；release 仍需正式签名。
- [ ] 确认最终 `applicationId`、`versionCode`、`versionName`。
- [ ] 将 release 构建从 debug signing 替换为正式签名证书。
- [x] 本机完成 Android debug APK 构建；最新产物为 `apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`。
- [x] 已在 Android 模拟器完成最新 debug APK 安装启动验收，并通过 `adb reverse tcp:8000 tcp:8000` 连到本机 FastAPI/Docker API。
- [ ] 在 CI 或 vivo/Android 真机完成最新 APK 安装启动验收；release 包仍需正式签名。

## 6. Docker/Postgres 与部署验收

- [x] 本机已安装 Docker，并已运行 `python scripts/docker_compose_preflight.py --json`。
- [x] 已通过 `docker compose -f infra/docker-compose.yml config` 配置验证。
- [x] 已运行 `docker compose -f infra/docker-compose.yml up --build -d`，确认 Postgres 初始化、API 启动前 `alembic upgrade head`、容器内与宿主机 `/api/health` 正常。
- [x] Docker API 已读取 `services/api/.env` 的真实模型/高德配置，数据库连接仍由 compose 覆盖到 Postgres；宿主机 `127.0.0.1:8000` 真实 Agent smoke 返回 `openai_compatible`/`openai`/`amap` 且 `fallback=false`。
- [ ] 如要公网演示，确认服务器、域名、HTTPS、环境变量和数据库备份策略。
- [ ] 生产或公开环境必须设置 `LANXIN_AUTH_TOKEN_SECRET`，不要使用示例默认值。

## 7. 隐私、合规与素材确认

- [ ] 最终确认公开隐私说明、权限用途说明、记忆保存规则和对外表述。
- [ ] 确认蓝小心最终视觉风格、素材授权、多表情/多动作素材；如使用 GIF/WebP/Lottie/Live2D，提供最终资产并替换运行时 PNG。
- [ ] 确认真实 Demo 数据：目的地、路线、照片、用户画像、同行人信息均可公开展示。
- [ ] 公开演示前检查日志、截图、视频中没有密钥、私人位置、身份证明、未经授权照片或队友隐私。

## 8. 比赛材料与最终提交

- [ ] 按 `docs/handoff/demo-script.md` 录制真实链路 Demo：记忆确认、真实规划、主动提醒、旅拍文案、复盘。
- [ ] 按 `docs/handoff/presentation-outline.md` 制作 PPT，并补充队伍信息、真实截图、视频链接和最终排版。
- [ ] 按 `docs/handoff/demo-evidence-pack.md` 截取 App、Swagger、接口、审计日志和 toolTrace 画面。
- [ ] 按 `docs/handoff/submission-checklist.md` 检查作品名称、团队介绍、代码仓库、PPT、视频、文档一致。
- [ ] 由负责人确认比赛平台账号、上传材料、预览结果和最终提交。

## 9. 推送与协作

- [x] 当前本地 `dev` 已推送到 `origin/dev`；最新提交以 `git log --oneline -1` 为准。
- [ ] 后续推送前再次确认 `git status --short` 为空，并运行必要的轻量验证与 GitNexus `detect_changes`。
- [ ] 队友基于远端 `dev` 继续开发时，必须遵守 Android-only 规则和 `CLAUDE.md`。

## AI 已提供的辅助入口

| 事项 | 文件/命令 |
| --- | --- |
| Android 发布预检 | `python scripts/android_release_preflight.py --json` |
| Docker Compose 预检 | `python scripts/docker_compose_preflight.py --json` |
| 真实 Provider smoke | `cd services/api && uv run python scripts/real_provider_smoke.py` |
| 迁移链检查 | `cd services/api && uv run python scripts/migration_plan.py check` |
| 配置实施清单 | `docs/handoff/config-implementation-checklist.md` |
| 端到端验收 | `docs/handoff/e2e-acceptance.md` |
| Demo 脚本 | `docs/handoff/demo-script.md` |
| 证据包 | `docs/handoff/demo-evidence-pack.md` |
| PPT 大纲 | `docs/handoff/presentation-outline.md` |
| 提交清单 | `docs/handoff/submission-checklist.md` |
