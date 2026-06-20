# 蓝心同行：懂你的全旅程 AI 旅伴

本仓库用于 2026 年 AIGC 创新赛应用赛道作品“蓝心同行”。当前已形成可运行的 Flutter App + FastAPI + LangGraph Agent 骨架，支持本地演示“聊天 → 记忆胶囊 → 个性化规划 → 主动提醒 → 蓝小心状态 → 旅行复盘”的 P0 闭环；模型默认 Mock，天气/POI/路线工具已接入高德 Provider，无 Key 时明确降级。

## 当前结构

- `apps/mobile/`：Flutter 移动端原型，含蓝小心状态、聊天页、记忆、规划、提醒、复盘页面。
- `services/api/`：FastAPI 后端，使用 uv 管理依赖，内置 LangGraph TravelMate Agent Mock 流程。
- `docs/todo.md`：全项目未完成待办总表。
- `docs/product/`：PRD、开发路线、UI 计划和比赛材料整理。
- `docs/engineering/`：技术设计、API 契约、Agent 图、开发路线和贡献说明。
- `docs/handoff/`：面向队友交接和人工阅读的说明材料。
- `infra/docker-compose.yml`：本地 api + postgres 编排，nginx 作为占位服务。
- `project/img/`、`apps/mobile/assets/avatars/`：蓝小心素材。

## 启动后端

```powershell
cd services/api
uv sync
uv run uvicorn app.main:app --host 127.0.0.1 --port 8000
```

访问：

- 健康检查：`http://127.0.0.1:8000/api/health`
- Swagger：`http://127.0.0.1:8000/docs`

Mock 聊天接口：

```powershell
cd services/api
uv run python -c "import httpx; print(httpx.post('http://127.0.0.1:8000/api/agent/chat', json={'message':'周末想去重庆两天，不想太累，喜欢夜景，我不吃香菜'}).json())"
```

## 后端环境变量

可复制 `services/api/.env.example` 为 `services/api/.env`。真实联调时常用配置：

```powershell
LANXIN_MODEL_PROVIDER=lanxin
LANXIN_LANXIN_BASE_URL=你的蓝心接口地址
LANXIN_LANXIN_API_KEY=你的蓝心密钥
LANXIN_LANXIN_MODEL=模型名
LANXIN_AMAP_API_KEY=你的高德Key
```

未配置 `LANXIN_AMAP_API_KEY` 时，天气、POI、路线工具返回 `provider=unconfigured` 和 `fallback=true`，不会伪装真实数据。
## 启动 Flutter

```powershell
cd apps/mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Android 模拟器使用：

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

真机使用局域网 IP：

```powershell
flutter run --dart-define=API_BASE_URL=http://你的电脑局域网IP:8000
```

## 测试与检查

后端：

```powershell
cd services/api
uv run pytest
```

前端：

```powershell
cd apps/mobile
$env:NO_PROXY='localhost,127.0.0.1,::1'
flutter analyze
flutter test --concurrency=1
flutter build apk --debug
```

如果本机设置了 `HTTP_PROXY`，运行 Flutter 测试时需要临时设置 `NO_PROXY`，否则本地 `flutter_tester` WebSocket 可能被代理拦截。

本机执行 `flutter build apk --debug` 需要安装 Android SDK `platforms;android-35`；CI 会自动安装 Android SDK 35 和 `build-tools;35.0.0`。

Docker：

```powershell
docker build -t lanxin-travelmate-api ./services/api
docker compose -f infra/docker-compose.yml up --build
```

## 第一阶段验收

1. 后端 `uv run uvicorn app.main:app --host 127.0.0.1 --port 8000` 可启动。
2. `/api/health` 返回 `status=ok`。
3. `/docs` 可打开。
4. `/api/agent/chat` 返回统一 Agent 响应结构。
5. Flutter 聊天页发送“周末想去重庆两天，不想太累，喜欢夜景，我不吃香菜”后展示蓝小心回复。
6. 聊天页出现记忆候选，点击“确认记忆胶囊”后写入本地 Drift SQLite。
7. 记忆页可看到已确认胶囊，并支持编辑/删除。
8. 规划、提醒、复盘页优先展示本次 Agent Mock 响应。
9. P1 演示可继续验证：规划页备选方案/高德导航入口、多人偏好协调并带入规划、提醒页三类模拟触发、旅拍页文案生成/盲盒任务接受-完成-跳过、盲盒完成奖励数值、复盘页独立生成。
10. `uv run pytest`、`flutter analyze`、`flutter test --concurrency=1` 可作为基础验收命令；本机有 Android SDK 35 时再执行 `flutter build apk --debug`。

## 分支协作

- `main`：稳定发布分支。
- `dev`：开发集成分支。
- `feat/*`：功能分支。
- `fix/*`：修复分支。
- `docs/*`：文档分支。

不自动推送远程；涉及 push、PR、merge、删除远程分支等操作需单独确认。
