# 首页聊天历史与可拖拽面板 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 Android App 名称恢复为“蓝心同行”，并把首页聊天改为“按行程管理历史 + 可拖拽调整窗口占比 + 纯净聊天模式保留”的真实用户体验。

**Architecture:** 首页继续作为主交互入口，不再用“展开”跳转聊天页。新增本地会话/行程历史服务，复用 Drift 的 `chat_messages` 与 `chat_summaries`，必要时用 `summary` JSON 存储标题、行程绑定、最近消息和更新时间，避免本轮做破坏性数据库迁移。纯聊天页保留为“纯净模式”，从首页历史入口进入或在会话管理中打开。

**Tech Stack:** Flutter 3.44、GoRouter、Drift/SQLite、现有 `AgentChatService`、Android-only。

## Global Constraints

- 只处理 Android/vivo；不恢复或维护 iOS/macOS/Windows/Linux/Web。
- 所有 App 内中文品牌名统一为“蓝心同行”。
- 首页蓝小心直聊是主体验，纯聊天页只是可选模式。
- 聊天历史按“用户新建对话”和“聊天过程中绑定/推断出的行程”分类。
- 每个阶段完成后运行目标验证并提交。

---

### Task 1: 品牌名恢复为“蓝心同行”

**Files:**
- Modify: `apps/mobile/android/app/src/main/AndroidManifest.xml`
- Modify: `apps/mobile/lib/app.dart`
- Modify: `apps/mobile/lib/features/settings/settings_page.dart`
- Modify: `apps/mobile/lib/features/auth/data/auth_session_service.dart`
- Modify: `apps/mobile/lib/features/reminder/data/notification_delivery_service.dart`
- Modify: `apps/mobile/android/app/src/main/kotlin/com/lanxin/lanxin_travelmate/MainActivity.kt`
- Modify: `docs/todo.md`
- Modify: `docs/handoff/ai-shared-state.md`

**Steps:**
- [ ] 全仓搜索 `蓝心同心`，只把产品展示名和用户可见文案替换为 `蓝心同行`。
- [ ] 保留包名 `com.lanxin.lanxin_travelmate` 和数据库名 `lanxin_travelmate` 不变，避免影响安装升级。
- [ ] 运行 `flutter analyze --no-pub`。
- [ ] 构建 Android debug APK。
- [ ] 真机安装并确认桌面应用名为“蓝心同行”。
- [ ] 提交：`fix android app display name to lanxin travelmate`

### Task 2: 本地会话/行程历史服务

**Files:**
- Create: `apps/mobile/lib/features/chat/data/chat_history_service.dart`
- Test: `apps/mobile/test/chat_history_service_test.dart`

**Interfaces:**
- Produces: `ChatHistoryService`
- Produces: `ChatSessionEntry`
- Produces: `TripConversationGroup`
- Produces: `createSession({required String userId})`
- Produces: `bindSessionToTrip({required String sessionId, required String tripTitle, String? destination})`
- Produces: `saveMessage({required String sessionId, required MessageSender sender, required String text, AvatarState? avatarState})`
- Produces: `listGroupedSessions({required String userId})`

**Steps:**
- [ ] 写测试：新建会话后应出现在“未绑定行程”分组。
- [ ] 写测试：保存用户消息后，服务能从目的地关键词生成可读标题，如“杭州行程对话”。
- [ ] 写测试：绑定行程后，列表按行程标题分组，最近更新时间倒序。
- [ ] 实现服务：`chat_messages` 存消息；`chat_summaries.summary` 存 JSON 元数据。
- [ ] 运行对应 Flutter 测试；如 native sqlite 测试在 Windows 卡住，则改用不依赖 native DB 的 metadata 解析单测，并在真机手测持久化。
- [ ] 提交：`feat mobile chat history by trip`

### Task 3: 首页右上角“聊天历史”改为行程会话选择器

**Files:**
- Modify: `apps/mobile/lib/features/home/home_page.dart`
- Create: `apps/mobile/lib/features/chat/widgets/trip_chat_history_sheet.dart`

**Interfaces:**
- Consumes: `ChatHistoryService.listGroupedSessions`
- Consumes: `ChatHistoryService.createSession`
- Consumes: `ChatHistoryService.bindSessionToTrip`

**Steps:**
- [ ] 右上角按钮保留“聊天历史”，点击后不直接跳转 `/chat`，而是打开底部弹层。
- [ ] 弹层顶部提供“新建对话”按钮，新建后回到首页并切换当前 `sessionId`。
- [ ] 弹层按“当前/未绑定行程”和各行程标题分组展示历史会话。
- [ ] 每条会话显示会话标题、最近一条消息摘要、更新时间、是否已绑定行程。
- [ ] 点击会话后首页加载该会话最近消息，继续和蓝小心同屏聊天。
- [ ] 提供“进入纯净模式”入口，打开 `/chat?sessionId=...&tripId=...`。
- [ ] 真机验证：新建对话、切换历史对话、继续发送消息均可用。
- [ ] 提交：`feat home trip chat history sheet`

### Task 4: 首页“展开”替换为可拖拽横线

**Files:**
- Modify: `apps/mobile/lib/features/home/home_page.dart`

**Steps:**
- [ ] 删除/隐藏右侧“展开”按钮，不再从首页聊天面板跳转纯聊天页。
- [ ] 在聊天面板顶部居中放一个横向拖拽柄。
- [ ] 用 `GestureDetector.onVerticalDragUpdate` 调整 `panelHeightRatio`。
- [ ] 小屏范围建议：`0.32 <= ratio <= 0.62`；键盘弹出时自动限制最大高度，避免遮挡输入框。
- [ ] 拖拽时人物图与状态气泡按面板高度联动上移/压缩，避免重叠。
- [ ] 记住用户本次运行内的面板高度；本轮先不做持久化，避免设置复杂化。
- [ ] 真机验证：上拉可看更多聊天，下拉可看更多蓝小心立绘；输入框和快捷按钮不被遮挡。
- [ ] 提交：`feat draggable home chat panel`

### Task 5: 纯净聊天页头像化与会话参数

**Files:**
- Modify: `apps/mobile/lib/core/router/app_router.dart`
- Modify: `apps/mobile/lib/features/chat/chat_page.dart`
- Modify: `apps/mobile/lib/shared/widgets/chat_bubble.dart`

**Steps:**
- [ ] 让 `/chat` 支持 `sessionId`、`tripId` 查询参数；无参数时仍可创建临时会话。
- [ ] `ChatPage` 标题文案改为“纯净聊天”或“蓝小心对话”，避免和首页主入口冲突。
- [ ] 助手头像从机器人 Icon 改为蓝小心大头头像，优先用 `AvatarState.assetPath`。
- [ ] 纯净页进入时加载该会话历史消息。
- [ ] 纯净页发送消息继续写入同一会话历史。
- [ ] 真机验证：从首页历史弹层进入纯净模式，头像为蓝小心大头，返回首页不丢当前会话。
- [ ] 提交：`feat pure chat mode with lanxiaoxin avatar`

### Task 6: 验收、文档和最终提交

**Files:**
- Modify: `docs/todo.md`
- Modify: `docs/handoff/ai-shared-state.md`

**Steps:**
- [ ] 运行 `flutter analyze --no-pub`。
- [ ] 运行 Android debug APK build，不运行 Windows 桌面构建。
- [ ] 真机 `8507100b` 安装或 `flutter run` 验收：首页、聊天历史、新建会话、绑定行程、拖拽面板、纯净模式。
- [ ] 运行 `git diff --check`。
- [ ] 运行 `node .gitnexus\run.cjs detect_changes --repo lanxin-travelmate-aigc-2026`。
- [ ] 更新 `docs/todo.md`，把本轮完成项从未完成移入已完成记录，保留真实用户验收反馈项。
- [ ] 更新 `docs/handoff/ai-shared-state.md`，记录交互入口和真机验收结论。
- [ ] 提交：`docs update home chat acceptance state`

## Open Questions

1. 行程绑定的第一版是否可以先用“用户手动新建/选择 + Agent 回复中推断目的地标题”的方式实现，后续再接更强的行程实体识别？
2. 纯净模式入口是否只放在“聊天历史”弹层里，而不在首页主面板常驻展示？

## Self-Review

- 覆盖了应用名、聊天历史分类、首页拖拽、纯净聊天页头像、真机验证和文档提交。
- 没有引入非 Android 平台任务。
- 第一版复用现有 Drift 表，避免本轮增加数据库迁移风险。
