# 最终提交检查清单

> 用途：提交比赛平台或交接队友前逐项确认。不要为了勾选而伪造真实 Key、真机或授权结果。

## 1. 代码仓库

- [ ] 当前分支为 `dev`，且需要推送时已由负责人确认远端操作。
- [ ] `git status --short` 为空。
- [ ] 远端仓库只保留 Android/vivo 原生平台壳，没有 `apps/mobile/ios`、`macos`、`windows`、`linux`、`web`。
- [ ] `CLAUDE.md` 和 `AGENTS.md` 规则一致，`AGENTS.md` 继续引用 `CLAUDE.md`。
- [ ] `docs/todo.md` 只保留未完成、待验证或人工介入事项。

## 2. 本地与 CI 验证

- [ ] 后端：`cd services/api && uv run pytest`。
- [ ] Flutter：`cd apps/mobile && flutter analyze`。
- [ ] Android 预检：`python scripts/android_release_preflight.py --json`。
- [ ] GitNexus：提交前已运行 `node .gitnexus\run.cjs detect_changes --repo lanxin-travelmate-aigc-2026`。
- [ ] CI：Flutter analyze/test、Python pytest、Backend Docker build、Android debug APK build 通过。

## 3. 真实能力配置

- [ ] 模型：已配置 `LANXIN_MODEL_PROVIDER`、base URL、API Key、模型名。
- [ ] 地图天气：已配置 `LANXIN_AMAP_API_KEY` 或确认替代服务商。
- [ ] 认证：生产/公开环境已设置 `LANXIN_AUTH_TOKEN_SECRET`。
- [ ] GitHub Secrets：真实 Provider smoke 需要的 secrets 已配置。
- [ ] 日志：确认没有真实密钥、Token、密码或完整敏感原文出现在日志截图里。

## 4. Android/vivo 验收

- [ ] 安装 Android SDK `platforms;android-35` 和 `build-tools;35.0.0`。
- [ ] 确认 `applicationId` / 包名是否为最终包名。
- [ ] 确认 `versionCode` 和 `versionName`。
- [ ] release 签名已替换 debug signing。
- [ ] APK 可安装并启动。
- [ ] vivo/Android 真机验证：相册、相机、定位、麦克风、系统语音识别、TTS、通知。
- [ ] 权限拒绝时页面显示明确中文提示，不白屏、不卡死。

## 5. Demo 素材

- [ ] 真实用户画像：节奏、兴趣、饮食、预算、交通偏好。
- [ ] 真实目的地、路线点和可展示 POI。
- [ ] 真实照片素材或授权可用照片。
- [ ] App 截图：聊天、记忆、规划、提醒、旅拍、复盘、设置/隐私。
- [ ] API 截图：Swagger、`/api/agent/chat`、模型审计、工具审计。
- [ ] toolTrace 截图：真实 Key 成功或明确 fallback/unconfigured。
- [ ] Demo 视频不展示密钥、隐私位置、未经授权照片或队友隐私。

## 6. PPT 与文档

- [ ] PPT 使用 `docs/handoff/presentation-outline.md` 完成页面。
- [ ] Demo 录制按 `docs/handoff/demo-script.md` 执行。
- [ ] 证据图和风险说明来自 `docs/handoff/demo-evidence-pack.md`。
- [ ] README 启动、测试、联调、预检命令可用。
- [ ] API 契约、技术设计、Agent 图、隐私合规文档已随代码更新。

## 7. 平台提交

- [ ] 作品名称、队伍名称、成员信息、联系方式填写正确。
- [ ] 代码仓库链接可访问。
- [ ] PPT、视频、文档和代码分支一致。
- [ ] 平台上传后下载/预览确认无损坏。
- [ ] 最终提交由负责人确认。

