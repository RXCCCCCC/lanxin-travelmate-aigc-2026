# 蓝心同心 Todo：剩余事项总览

> 更新时间：2026-07-04
> 口径：未完成事项排在前面，按建议执行顺序排列；已完成事项收拢到后面作为状态记录。主链路验收必须使用真实模型、真实用户数据、真实设备能力或真实第三方 API，Mock/固定样例只允许作为异常降级，不计入通过。

## 下一步按顺序处理

### 1. 双人真机最终验收

- [ ] 按 `docs/handoff/final-acceptance.md`，你和队友使用两台 Android/vivo 真机分别执行 A 线、B 线验收，记录页面、步骤、输入、实际结果、期望结果、证据和严重程度。
- [ ] 人工验收五类真实模型效果质量：记忆抽取、规划推理、角色化对话、旅拍文案、旅行复盘是否符合比赛演示口径。
- [ ] 最终演示数据库中人工确认五类真实场景均为真实 Provider `fallback=false`，并再次检查日志不含密钥、Token、密码或完整敏感原文。
- [ ] 在 Android 规划页真机确认 `toolTrace` 展示真实 provider 且 `fallback=false`；无 Key 或异常时必须明确显示 `fallback/unconfigured`。
- [ ] 使用真实用户路径验证 App 流程顺滑度、真实数据可信度、视觉观感和蓝小心角色感，形成 S1/S2/S3/S4 问题清单。

### 2. Android/vivo 设备能力验收

- [ ] 在 vivo/Android 真机验证相册选择、麦克风、系统语音识别、中文 TTS、Android 13+ 通知权限和通知展示。
- [ ] 权限拒绝路径作为专项测试处理；常规真实用户验收不主动点击拒绝，避免偏离用户使用路径。
- [ ] 准备真实可展示照片素材，确认素材授权和隐私边界。
- [ ] 如需地图选点或更高定位精度，确认使用哪种地图 SDK/服务并提供对应 Key。

### 3. 多设备、账号与云同步验收

- [ ] 决定正式账号体系是否只保留游客升级密码账号，还是接入手机号、短信或 OAuth。
- [ ] 确认旧游客 token 失效策略、设备 ID 绑定策略和多设备冲突合并规则。
- [ ] 使用至少两台设备或两个独立会话验证注册/登录、游客升级、记忆同步、选择性同步、撤销云端同步和冲突处理。
- [ ] 验证同一 Bearer 用户下 profile、memory、trip、photo、review、reminder 数据不会串到其他用户。

### 4. 发布配置与部署

- [ ] 确认最终 `applicationId`、`versionCode`、`versionName`。
- [ ] 将 Android release 构建从 debug signing 替换为正式签名证书。
- [ ] 如要公网演示，确认服务器、域名、HTTPS、环境变量和数据库备份策略。
- [ ] 生产或公开环境必须设置 `LANXIN_AUTH_TOKEN_SECRET`，不要使用示例默认值。
- [ ] 确认高德 API 计费额度、可展示的数据来源和比赛演示是否允许展示第三方地图/天气数据。

### 5. 隐私、合规与素材确认

- [ ] 最终确认公开隐私说明、权限用途说明、记忆保存规则和对外表述。
- [ ] 确认蓝小心最终视觉风格、白底矩形处理方案、素材授权、多表情/多动作素材；如使用透明 PNG/WebP/GIF/Lottie/Live2D，提供最终资产并替换运行时 PNG。
- [ ] 确认真实 Demo 数据：目的地、路线、照片、用户画像、同行人信息均可公开展示。
- [ ] 公开演示前检查日志、截图、视频中没有密钥、私人位置、身份证明、未经授权照片或队友隐私。

### 6. 比赛材料与最终提交

- [ ] 按 `docs/handoff/demo-script.md` 录制真实链路 Demo：记忆确认、真实规划、主动提醒、旅拍文案、复盘。
- [ ] 按 `docs/handoff/presentation-outline.md` 制作 PPT，并补充队伍信息、真实截图、视频链接和最终排版。
- [ ] 按 `docs/handoff/demo-evidence-pack.md` 截取 App、Swagger、接口、审计日志和 toolTrace 画面。
- [ ] 按 `docs/handoff/submission-checklist.md` 检查作品名称、团队介绍、代码仓库、PPT、视频、文档一致。
- [ ] 由负责人确认比赛平台账号、上传材料、预览结果和最终提交。

## 已完成记录

### 真实模型与真实工具

- [x] 已配置 OpenAI 兼容真实模型，并运行 `cd services/api && uv run python scripts/real_provider_smoke.py`；结果为 `provider=openai_compatible ok=True`。
- [x] 已验证真实旅拍文案接口：`/api/photo/copywriting` 返回 `provider=openai_compatible fallback=false`，朋友圈/小红书/日记/Vlog/复盘建议字段齐全。
- [x] 已修复真实 Agent 输出兼容问题，并通过 Docker API 验证记忆抽取、规划推理、旅行复盘、角色化对话均为真实 Provider `fallback=false`。
- [x] 已补齐 Agent、行程规划/复盘、旅拍文案等模型调用审计落库，并通过 `GET /api/audit/model-calls` 定向测试验证请求摘要不泄露敏感原文。
- [x] 已提供并配置高德 API Key。
- [x] 已使用真实 Key 验证天气、POI、步行、驾车、公交、混合路线；工具结果均为 `provider=amap fallback=false`。

### Android/vivo 与前端验收

- [x] 稳定 Android 模拟器验收环境已准备；最新 debug APK 已安装启动，首页和聊天页真实后端联调通过，审计日志可见 `openai_compatible`/`amap` 调用记录。
- [x] 已在 vivo/Android 真机安装最新 APK，并验收“首页蓝小心同屏直聊、人物图先下移到底部陪伴区域、底部 Tab：首页/行程/复盘/我的、旅拍入口归入复盘记录、键盘不遮挡输入框、基础消息发送与真实后端回复”。
- [x] 已新增只读真机就绪脚本 `python scripts/android_device_readiness_report.py --json`，可读取 adb、设备、安装包、权限、Manifest 对齐和相机/相册/语音识别/TTS 系统能力；脚本不安装 APK、不启动 App、不修改权限。
- [x] 已按用户要求将运行时 `lanxiaoxin_*.png` 头像资产恢复为 `project/img/lanxiaoxin/` 原始素材，并新增静态测试防止运行时头像与原始素材不一致。
- [x] 已在 Android 真机允许授权路径验证定位填充真实坐标；已修复相机运行时权限申请，并确认允许后可拉起系统相机拍照界面。
- [x] 已切回 Android 模拟器继续调试，最新 APK 安装后首页同屏聊天真实后端回复通过；模拟器启动期曾出现 System UI ANR，选择等待后恢复。
- [x] 已在 Android 模拟器验证行程页表单 UX：字段间距不再依赖浮动标签，目的地改为地点名称输入，出发地通过定位动作补充，日期通过中文日期选择器回填。

### APK、Docker 与工程化

- [x] 当前本地 `dev` 已同步到 `origin/dev`，`git status --short --branch` 显示 `## dev...origin/dev`。
- [x] 队友基于远端 `dev` 继续开发前需要阅读 `CLAUDE.md`、`docs/handoff/ai-shared-state.md`、`docs/handoff/final-acceptance.md` 和本文件；协作规则已写入文档。
- [x] 后续协作继续遵守 Android/vivo-only 规则，不恢复 iOS、macOS、Windows、Linux、Web 平台工程。
- [x] 本机已在 `E:\localAndroid` 安装 Android SDK `platforms;android-35` 与 `build-tools;35.0.0`。
- [x] 已运行 `python scripts/android_release_preflight.py --json`，确认 Android-only、包名、版本号、SDK、build-tools、CI APK job 和签名状态；release 仍需正式签名。
- [x] 本机完成 Android debug APK 构建；最新产物为 `apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`。
- [x] 已在 Android 模拟器完成最新 debug APK 安装启动验收，并通过 `adb reverse tcp:8000 tcp:8000` 连到本机 FastAPI/Docker API。
- [x] 已在 vivo/Android 真机完成最新 debug APK 安装启动验收；release 包仍需正式签名。
- [x] 本机已安装 Docker，并已运行 `python scripts/docker_compose_preflight.py --json`。
- [x] 已通过 `docker compose -f infra/docker-compose.yml config` 配置验证。
- [x] 已运行 `docker compose -f infra/docker-compose.yml up --build -d`，确认 Postgres 初始化、API 启动前 `alembic upgrade head`、容器内与宿主机 `/api/health` 正常。
- [x] Docker API 已读取 `services/api/.env` 的真实模型/高德配置，数据库连接仍由 compose 覆盖到 Postgres；宿主机 `127.0.0.1:8000` 真实 Agent smoke 返回 `openai_compatible`/`openai`/`amap` 且 `fallback=false`。
- [x] 已新增 `docs/handoff/final-acceptance.md`，用于你和队友按两台 Android/vivo 真机分工验收最终产品。

## AI 已提供的辅助入口

| 事项 | 文件/命令 |
| --- | --- |
| Android 发布预检 | `python scripts/android_release_preflight.py --json` |
| Android/vivo 真机只读预检 | `python scripts/android_device_readiness_report.py --json` |
| Docker Compose 预检 | `python scripts/docker_compose_preflight.py --json` |
| 真实 Provider smoke | `cd services/api && uv run python scripts/real_provider_smoke.py` |
| 迁移链检查 | `cd services/api && uv run python scripts/migration_plan.py check` |
| 提交就绪总览 | `python scripts/submission_readiness_report.py --json` |
| 配置实施清单 | `docs/handoff/config-implementation-checklist.md` |
| 最终验收分工 | `docs/handoff/final-acceptance.md` |
| 端到端验收 | `docs/handoff/e2e-acceptance.md` |
| Demo 脚本 | `docs/handoff/demo-script.md` |
| 证据包 | `docs/handoff/demo-evidence-pack.md` |
| PPT 大纲 | `docs/handoff/presentation-outline.md` |
| 提交清单 | `docs/handoff/submission-checklist.md` |
