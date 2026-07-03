# AI 共享开发状态

> 用途：给 Claude Code、Codex 和人工成员提供同一份短上下文。新会话优先读本文件，再按需读 `docs/todo.md`、`CLAUDE.md` 和具体代码。  
> 维护口径：只写当前结论和下一步，不复述完整对话，不堆历史细节。  
> 最近更新：2026-07-03 by Codex

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

### 2026-07-03

- 本地 `dev` 已 fast-forward 到 `origin/dev` 最新提交 `155c2f0`，工作区同步后保持干净。
- 已运行 `python scripts/android_release_preflight.py --json`，Android-only、包名、版本、SDK 35、build-tools 35.0.0、CI APK job 和预检链路均通过；release 仍需人工配置正式签名。
- 已运行 `python scripts/docker_compose_preflight.py --json`，Docker Compose 文件、API/Postgres 连接、健康检查、命名卷、迁移启动命令和 `docker compose config` 均通过。
- `docker compose -f infra/docker-compose.yml up --build -d` 尚未完成：Docker CLI 可用，但 `desktop-linux`/`default` daemon 管道不存在，`com.docker.service` 为 `Stopped`，当前会话无权启动该服务；需人工先启动 Docker Desktop 后继续验收。
- `docs/todo.md` 已更新：删除已完成的预检待办，只保留真机权限验收、最终 APK/签名、Docker 实际 `up --build`、隐私素材确认、Demo/PPT 和比赛上传等人工事项。
- 下一步 AI 可在 Docker Desktop 启动后继续做 Docker 实际启动验证，或继续做轻量文档/脚本修补；Android 真机、正式签名、素材授权和比赛提交仍需负责人介入。

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
