# 端到端验收清单

> 目标：让接手同学能快速判断当前作品是否达到“可运行、可演示、可继续开发”的基线。本文只列验收动作，不替代 `docs/todo.md` 的剩余开发任务。

## 1. 后端本地验收

```powershell
cd services/api
uv sync
uv run uvicorn app.main:app --host 127.0.0.1 --port 8000
```

验收点：

- `GET http://127.0.0.1:8000/api/health` 返回 `status=ok`。
- `http://127.0.0.1:8000/docs` 可打开 Swagger。
- `POST /api/agent/chat` 返回固定 camelCase 字段：`replyText`、`cards`、`memoryCandidates`、`toolTrace`、`errors`。
- 未配置真实模型或高德 Key 时，响应必须明确显示 fallback/unconfigured，不得伪装为真实数据。

Docker/Postgres 编排预检：

```powershell
cd <repo-root>
python scripts/docker_compose_preflight.py --json
docker compose -f infra/docker-compose.yml config
```

预检只检查配置，不启动容器。真正的 `docker compose -f infra/docker-compose.yml up --build` 仍需要本机 Docker 可用，并会拉取/构建镜像。

## 2. 后端数据闭环验收

建议按顺序调用：

1. `POST /api/auth/guest` 创建游客用户。
2. `POST /api/memory/capsules` 写入本次旅程确认记忆，`sourceText` 使用同一个 `tripId`。
3. `POST /api/trip/route-points` 写入真实或人工录制的轨迹点。
4. `POST /api/photo/candidates` 写入用户选择的照片候选元数据。
5. `POST /api/trip/reminders/trigger` 写入一次提醒历史。
6. `POST /api/trip/blind-box/tasks/{taskId}/status` 将盲盒任务标记为 `completed`，响应包含 `rewardApplied=true` 和 `rewardDeltas={affection:2, rapport:1}`。
7. `POST /api/trip/review` 生成复盘。

复盘响应应包含：

- `reviewId`、`tripId`
- `route`
- `highlightPhotos`
- `completedTasks`
- `reminderHighlights`
- `avatarStatusChanges`
- `newMemories`
- `nextTripSuggestions`
- `temporaryMemoryPromotions`

## 3. 审计与降级验收

- `GET /api/audit/tool-calls` 可读工具调用日志，并可用 `toolName`、`provider`、`fallback` 筛选。
- `GET /api/audit/model-calls` 可读模型调用日志，并可用 `provider`、`scenario`、`fallback` 筛选。
- 模型审计响应不得出现用户完整原文、密钥、Token 或密码。
- `toolTrace` 中需要能看出 `provider`、`fallback`、`fallbackReason`、`retryCount`、`cacheHit`、`circuitOpen` 等字段。

## 4. Flutter 联调验收

```powershell
cd apps/mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Android 模拟器使用：

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

真机使用电脑局域网 IP：

```powershell
flutter run --dart-define=API_BASE_URL=http://你的电脑局域网IP:8000
```

验收点：

- 聊天页发送旅行需求后能看到蓝小心回复。
- 记忆候选能进入确认流程。
- 规划、提醒、旅拍、复盘页能读取或展示后端/本地状态。
- 网络失败时有明确降级提示，不应白屏或卡死。
- 小屏 Android/vivo 尺寸下无明显遮挡、底部按钮不压住系统导航区。

## 5. 命令级回归

不要运行历史上耗时的 Flutter 长测试，尤其不要运行 `apps/mobile/test/review_page_integration_test.dart`。

推荐后端快速回归：

```powershell
cd services/api
uv run pytest tests/test_audit_routes.py tests/test_model_providers.py tests/test_trip_review_next_suggestions.py tests/test_trip_review_aggregation.py tests/test_trip_review_memory_settlement.py tests/test_trip_route_points.py tests/test_avatar_state_events.py tests/test_blind_box_task_state.py
```

可选全量后端：

```powershell
cd services/api
uv run pytest
```

真实 Provider / CI smoke：

```powershell
cd services/api
uv run python scripts/real_provider_smoke.py
uv run pytest tests/test_ci_real_smoke_workflow.py -q
```

CI 侧验收需要在 GitHub Secrets 配置高德或模型相关密钥后触发 `Real provider smoke` job；日志中只能出现 provider/scenario/fallback/errorType 和 `[REDACTED]`，不能出现真实密钥。
Flutter 建议先跑：

```powershell
cd apps/mobile
$env:NO_PROXY='localhost,127.0.0.1,::1'
flutter analyze
```

Android APK 预检：

```powershell
cd <repo-root>
python scripts/android_release_preflight.py --json
```

预检会报告 Android-only 平台壳、包名、版本号、SDK 35、build-tools 35.0.0、CI APK job 和 release 签名状态。当前 release 仍使用 debug signing，最终公开发布前必须替换为正式签名。

提交就绪总览：

```powershell
cd <repo-root>
python scripts/submission_readiness_report.py --json
```

总览脚本会聚合 Git 工作区、Android-only 平台壳、关键交接文档、`docs/todo.md` 人工事项口径、Android 预检和 Docker Compose 预检。它不会启动服务、构建 APK、读取密钥值或修改文件；如只想检查仓库结构与文档，可加 `--skip-git`，避免被本地未跟踪素材影响。

## 6. 必须人工介入的验收

- 配置真实 `LANXIN_MODEL_PROVIDER`、base URL、API Key、模型名，并验证模型效果。
- 配置真实 `LANXIN_AMAP_API_KEY`，验证天气、POI、路线返回真实数据。
- 使用 vivo/Android 真机验证定位、相册、相机、麦克风、通知和系统 TTS 权限。
- 确认 Android 包名、签名证书、版本号、SDK 35 和 APK 安装。
- 录制最终 Demo 视频并检查隐私、素材授权、队伍信息和比赛提交材料。

## 7. 结构化 Provider 验收

无需真实密钥的本地结构化链路回归：

```powershell
cd services/api
uv run pytest tests/test_model_providers.py -q
```

重点用例：`test_graph_runs_structured_provider_across_core_agent_loop`。它验证同一个结构化 Provider 能驱动：

- `memory_extraction` 生成候选记忆。
- `trip_planning` 生成规划。
- `trip_review` 生成复盘。
- `companion_chat` 生成最终回复。

验收时需要检查四个 `model_provider` trace 均为 `fallback=false`。真实密钥联调时再运行 `scripts/real_provider_smoke.py` 和 CI 的 Real provider smoke；未配置 secrets 的结果只代表降级可用，不代表真实模型验收通过。
