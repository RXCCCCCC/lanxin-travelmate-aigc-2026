# CLAUDE.md

本文件是本仓库给 Claude Code / Codex / 其他 AI 助手的项目级硬规则入口。动态状态不要继续堆在这里：阶段性结论写入 `docs/handoff/ai-shared-state.md`，剩余人工事项写入 `docs/todo.md`。

## 新会话必读顺序

1. 先读 `docs/handoff/ai-shared-state.md`：当前阶段、最近结论、下一步、真实联调状态。
2. 再读 `docs/todo.md`：只看仍需人工、真机、真实密钥、授权、提交确认的事项。
3. 按任务需要再读具体源码、PRD、工程文档或交接文档。
4. 阶段性工作结束时，用 3 到 8 条短 bullet 更新 `docs/handoff/ai-shared-state.md`；不要写入密钥、Token、私人位置、未授权素材或用户敏感原文。

## 项目定位

- 项目名称：蓝心同行。
- 角色名：蓝小心。
- 赛道：第三届（2026）AIGC 创新赛应用赛道。
- 产品方向：面向移动端出行场景的“全旅程 AI 旅游搭子”。
- 核心差异点：长期记忆、隐私可控、主动陪伴、2D 形象化表达、完整旅程闭环。
- 当前重点：主链路工程与交接材料已基本成型，优先真实模型、真实高德工具、Android/vivo 真机、Demo/PPT/提交材料验收。

## 仓库地图

- `apps/mobile/`：Flutter Android/vivo App；当前只维护 Android 原生平台壳。
- `services/api/`：FastAPI + LangGraph 后端，使用 `uv` 管理依赖。
- `infra/docker-compose.yml`：本地 API + Postgres 编排，Docker API 可读取 `services/api/.env` 的真实模型/高德配置。
- `docs/product/PRD.md`：产品需求与比赛叙事主文档。
- `docs/engineering/`：API、Agent 图、技术设计、隐私合规、数据库迁移等工程文档。
- `docs/handoff/`：AI/人工交接、验收、Demo、PPT、提交清单。
- `docs/reference/vivo-aigc/`：vivo AIGC 在线文档本地镜像；接入蓝心/ASR/TTS/LBS/端侧能力时优先查这里。
- `project/img/`：蓝小心原始素材；新增原始角色图和图片统一放这里。
- `docs/todo.md`：剩余人工事项总表；不要把 Mock 或固定演示数据标为真实完成。

## 常用命令

```powershell
# 后端
cd services/api
uv sync
uv run pytest
uv run uvicorn app.main:app --host 127.0.0.1 --port 8000
uv run python scripts/real_provider_smoke.py

# Docker 本地演示
cd ../..
python scripts/docker_compose_preflight.py --json
docker compose -f infra/docker-compose.yml up --build -d

# 前端
cd apps/mobile
flutter pub get
$env:NO_PROXY='localhost,127.0.0.1,::1'
flutter analyze
flutter test --concurrency=1
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000

# Android APK
cd ../..
python scripts/android_release_preflight.py --json
cd apps/mobile
flutter build apk --debug
```

真机联调时：

```powershell
# 后端监听局域网
cd services/api
uv run uvicorn app.main:app --host 0.0.0.0 --port 8000

# Flutter 指向电脑局域网 IP
cd apps/mobile
flutter run --dart-define=API_BASE_URL=http://<电脑局域网IP>:8000
```

Android 模拟器联调本机 FastAPI 时需要先执行：

```powershell
adb reverse tcp:8000 tcp:8000
```

## 产品与技术边界

### 产品主线

PRD 不是单点问答助手，而是“全旅程 AI 旅游搭子”。理解需求时按以下闭环拆解：

1. 记忆胶囊与用户旅行画像。
2. 个性化出行规划。
3. 出行前 / 出行中 / 出行后全旅程陪伴。
4. 主动情境对话与可控打扰频率。
5. 蓝小心 2D 形象、状态、人格与默契感。
6. 旅拍候选集与发布前确认的内容生成。
7. 旅行盲盒、状态变化、复盘与记忆沉淀。

### 真实数据与降级边界

- 主链路验收必须优先使用真实模型、真实用户数据、真实设备能力和真实第三方 API。
- Mock、固定样例、手动模拟只允许作为异常降级或测试 fixture，不计入真实验收通过。
- 未配置真实模型或高德 Key 时，后端必须显式返回 `fallback/unconfigured`，前端需要让用户看见降级原因。
- 不要把“后台无感监控照片”“无确认自动发布社交平台”等高风险能力写成 MVP 承诺。
- 涉及真实 API、Live2D、地图、照片权限、模型调用的能力，必须保留候选实现、风险和 MVP 降级路径。

### 隐私与安全边界

- 不提交真实 `.env`、密钥、Token、私人位置、未授权照片或用户敏感原文。
- 照片候选和上传元数据不得把设备本地 `localPath/localUri` 发到云端保存；云端只保留远程 URL、文件名、内容类型和显式隐私标记。
- 模型调用日志只允许脱敏摘要：密钥、Authorization、Token、密码统一 `[REDACTED]`；用户原文类字段只保留字符数或截断摘要。
- 旅拍文案、朋友圈、小红书、日记、Vlog 等内容发布前必须由用户确认。
- 多人出游协调不得在对外响应中暴露成员敏感偏好原文，只展示聚合协调结果与隐私摘要。

## 移动端开发基线

- 只维护 Android/vivo：保留 `apps/mobile/android/`、Dart 业务代码和通用资源；不要主动恢复 iOS、macOS、Windows、Linux、Web 平台工程。
- 优先覆盖 vivo/Android 主流手机尺寸：360x780、375x812、390x844、412x915、430x932，同时关注横屏、平板宽度和系统字体缩放 1.2/1.4。
- 移动端调试优先使用已连接 Android/vivo 真机；无真机、真机不可用或需复现模拟器专属问题时再用模拟器。
- 固定底部导航、输入栏、底部 CTA 和列表页必须显式处理 SafeArea；主要触控目标按 Android 48dp 设计。
- 首页沉浸式页面不得只依赖 `Stack + Positioned + 屏幕比例`；短屏或横屏要折叠次要浮动元素或允许滚动兜底。
- 真实 Agent/Provider 路径可能约 30 秒返回；不要把 API `receiveTimeout` 改回只适合 Mock 的短超时。
- Flutter widget test 在本机若设置了 `HTTP_PROXY`，先临时设置 `$env:NO_PROXY='localhost,127.0.0.1,::1'`，否则 `flutter_tester` 可能 WebSocket 握手失败。
- 本机执行 `flutter build apk --debug` 前先运行 `python scripts/android_release_preflight.py --json`；本机 Android SDK 需要 `platforms;android-35`，CI 会安装 SDK 35 与 `build-tools;35.0.0`。

## 后端与 Provider 基线

- 后端：FastAPI + LangGraph，`uv` 管理依赖。
- 真实模型配置从 `services/api/.env.example` 复制到本地 `.env`；真实模型需要 `LANXIN_MODEL_PROVIDER`、对应 base URL/API Key/model。
- vivo 文本模型当前按 vivo AIGC `1745-大模型` 口径接入：`POST https://api-ai.vivo.com.cn/v1/chat/completions`，`Authorization: Bearer <AppKey>`，建议补 `requestId` query 参数。
- 真实高德工具需要 `LANXIN_AMAP_API_KEY`，并验证天气、POI、步行、驾车、公交、混合路线返回 `provider=amap fallback=false`。
- Alembic revision id 必须不超过 32 字符，以兼容默认 Postgres `alembic_version.version_num`。
- 生产或公开环境必须设置 `LANXIN_AUTH_TOKEN_SECRET`，不要使用示例默认值。

## 文档与交接规则

- 默认使用中文维护仓库文档。
- 修改 PRD 或比赛材料时，优先强化创新性、应用价值、完成度、大模型应用说明和 3 分钟 Demo 故事线。
- 方案、PRD 补充、原型设计和技术拆分都要方便 vibe coding：小闭环、低依赖、可端到端体验、可直接转代码。
- 当用户通过 `@文件名`、模板名或模糊文件名引用项目资料时，先用 Glob 搜索真实文件名和格式，再读取。
- 评估角色图、原型图或视觉素材时，优先采用用户给出的素材定位；姿势、用途或生成阶段不确定时标注“待确认”或询问。
- `AGENTS.md` 通过引用本文件继承上下文，不单独维护重复规则。
- 若新增真实代码项目或改变开发命令，必须同步更新本文件的命令和目录说明。
- `docs/todo.md` 只保留需要真实密钥、真实设备、正式签名、素材授权、远端推送、部署环境、比赛提交或负责人确认的事项。

## GitNexus 规则

当前仓库已由 GitNexus 索引为 `lanxin-travelmate-aigc-2026`。

- 修改函数、类、方法前，必须先对目标 symbol 做 GitNexus impact 分析；若结果为 HIGH/CRITICAL，先警告用户再继续。
- 提交前必须运行 GitNexus `detect_changes` 检查影响范围；回归审查可对比默认分支 `main`。
- 不要用普通全文替换重命名 symbol；需要重命名时使用 GitNexus rename。
- 文档-only 轻量修改无需 symbol impact，但仍应做 `git diff --check`；若准备提交，再跑 `detect_changes`。
- 若 MCP 工具不可用或超时，用本地 `git diff`、定向搜索和测试结果补充核对，并在汇报中说明。

## 验收与测试口径

- 功能验收、模型效果验收和截图录屏默认使用中文与中国境内真实出行场景，例如广州、深圳、杭州、重庆、长沙。
- 如果 ADB 或真机输入法无法稳定注入中文，可以临时用拼音或英文输入，但语义仍应对应中国本地用户和国内旅行场景。
- 开发策略：核心功能优先；在核心链路完全落地前，不编写过多测试，只确保核心逻辑、接口契约和关键回归可验证。
- 发现 bug 时先写最小复现测试或静态守卫，再修复到测试通过；若因本地环境无法跑通，必须说明原因和替代验证。
- 非热更新自动生效的前后端修改后，要重启当前相关服务；无法安全识别或重启时明确提示用户。

## 重要交接入口

- 当前共享状态：`docs/handoff/ai-shared-state.md`
- 剩余人工事项：`docs/todo.md`
- 最终验收分工：`docs/handoff/final-acceptance.md`
- 端到端验收：`docs/handoff/e2e-acceptance.md`
- Demo 脚本：`docs/handoff/demo-script.md`
- Demo 证据包：`docs/handoff/demo-evidence-pack.md`
- PPT 大纲：`docs/handoff/presentation-outline.md`
- 提交清单：`docs/handoff/submission-checklist.md`
- 隐私合规：`docs/engineering/privacy-and-compliance.md`
- API 契约：`docs/engineering/api-contract.md`
- Agent 图：`docs/engineering/agent-graph.md`
- 数据库迁移：`docs/engineering/database-migrations.md`

## 禁止事项

- 不要把 Mock、固定样例或手动模拟包装成真实完成。
- 不要主动恢复非 Android 平台工程。
- 不要提交真实 `.env` 或任何密钥。
- 不要删除素材、历史文档、平台文件或大文件，除非用户明确确认。
- 不要把当前状态流水账继续追加到本文件；写入 `docs/handoff/ai-shared-state.md`。
