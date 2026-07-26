# 蓝心同行用户配置与使用指南

> 面向对象：拿到本仓库后需要运行、录制或继续验收“蓝心同行”的同学。本文优先给出可录制 Demo 的最短路径，再说明只能本地运行时如何配置。

## 推荐运行方式

当前作品由三部分组成：

- Android/Flutter App：`apps/mobile/`
- FastAPI + LangGraph 后端：`services/api/`
- Docker/Postgres/Nginx 部署配置：`infra/`、`infra/production/`

录制视频优先使用公网 API：

```text
https://api.rxcccccc.icu
```

录制前先确认服务可用：

```powershell
curl https://api.rxcccccc.icu/api/health
```

预期返回：`status=ok`。如果公网 API 不可用，再切换到“只能本地运行”方案。

## 后端配置

后端使用 Python 3.12+ 和 `uv`：

```powershell
cd services/api
uv sync
Copy-Item .env.example .env
```

最小可运行配置可以保留 `LANXIN_MODEL_PROVIDER=mock`，但录制或答辩时不能把 mock/fallback 说成真实模型能力。

真实演示推荐在 `services/api/.env` 配置：

```env
LANXIN_MODEL_PROVIDER=openai
LANXIN_OPENAI_BASE_URL=<OpenAI兼容模型base URL>
LANXIN_OPENAI_API_KEY=<密钥>
LANXIN_OPENAI_MODEL=<模型名>
LANXIN_MODEL_TIMEOUT_SECONDS=20

LANXIN_AMAP_BASE_URL=https://restapi.amap.com
LANXIN_AMAP_API_KEY=<高德Web服务Key>
LANXIN_TOOL_TIMEOUT_SECONDS=8
LANXIN_TOOL_RATE_LIMIT_PER_MINUTE=0

LANXIN_AUTH_TOKEN_SECRET=<至少32字节随机字符串>
```

也可以使用 vivo/蓝心文本模型：

```env
LANXIN_MODEL_PROVIDER=lanxin
LANXIN_LANXIN_BASE_URL=https://api-ai.vivo.com.cn/v1
LANXIN_LANXIN_API_KEY=<蓝心AppKey>
LANXIN_LANXIN_MODEL=<模型名>
LANXIN_MODEL_TIMEOUT_SECONDS=20
```

真实能力验收：

```powershell
cd services/api
uv run python scripts/real_provider_smoke.py
```

不要提交真实 `.env`、密钥、Token 或私人位置数据。

## Android/Flutter 配置

移动端使用 Flutter 和 Android SDK 35：

```powershell
cd apps/mobile
flutter pub get
```

构建前建议运行：

```powershell
cd ..\..
python scripts/android_release_preflight.py --json
```

当前包名：`com.lanxin.lanxin_travelmate`。当前仍是 debug signing，比赛录屏和内部演示可以使用；最终公开发布前需要正式签名。

## 使用云服务器 API 录制

真机直接运行：

```powershell
cd apps/mobile
flutter run --dart-define=API_BASE_URL=https://api.rxcccccc.icu
```

构建可安装 APK：

```powershell
cd apps/mobile
flutter build apk --debug --no-pub --dart-define=API_BASE_URL=https://api.rxcccccc.icu
```

产物位置：

```text
apps/mobile/build/app/outputs/flutter-apk/app-debug.apk
```

安装到已连接真机：

```powershell
adb install -r -d --no-streaming apps/mobile/build/app/outputs/flutter-apk/app-debug.apk
```

使用公网 API 时不需要 `adb reverse`，手机离开电脑网络后也应能访问后端。

录制前至少检查：

- 首页能正常启动，不停留在离线状态。
- 聊天发送中文旅行需求后有蓝小心回复。
- 真实模型/高德工具可用时，响应或页面参考信息应为 `fallback=false`。
- 如果看到 `fallback=true` 或 `provider=unconfigured`，旁白必须说明这是降级状态。

## 只能本地运行时如何配置

只给本机或模拟器使用：

```powershell
cd services/api
uv run uvicorn app.main:app --host 127.0.0.1 --port 8000
```

给 Android 真机访问时，必须监听局域网：

```powershell
cd services/api
uv run uvicorn app.main:app --host 0.0.0.0 --port 8000
```

健康检查：

```powershell
curl http://127.0.0.1:8000/api/health
```

Swagger：`http://127.0.0.1:8000/docs`

Android 模拟器访问宿主机：

```powershell
cd apps/mobile
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Android 真机同一局域网访问电脑：

```powershell
ipconfig
cd apps/mobile
flutter run --dart-define=API_BASE_URL=http://<电脑局域网IP>:8000
```

USB 调试兜底：

```powershell
adb reverse tcp:8000 tcp:8000
cd apps/mobile
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

如果需要接近生产环境的本地 Postgres 链路：

```powershell
cd <repo-root>
python scripts/docker_compose_preflight.py --json
docker compose -f infra/docker-compose.yml up --build -d
curl http://127.0.0.1:8000/api/health
```

停止：

```powershell
docker compose -f infra/docker-compose.yml down
```

不要随意删除 Docker volume，除非确认不需要保留演示数据。

## App 主要功能入口

### 首页

首页是录制主入口，包含蓝小心角色立绘、陪伴/纯净模式、当前旅程、天气、消息、聊天历史、首页直聊和底部导航。

### 聊天与记忆

推荐输入：

```text
周末想去广州两天，不想太累，喜欢夜景，我不吃香菜，预算别太高。
```

观察蓝小心回复、记忆候选、长期/本次/临时/不记忆选择，以及记忆页编辑删除能力。

### 行程规划

行程页支持目的地、日期、同行人、偏好、预算、交通方式、定位出发地、多人偏好协调、生成行程、修改方案和重规划。真实高德 Key 可用时，天气、POI、路线应来自真实工具；没有 Key 时必须明确显示降级。

### 主动提醒

提醒页可演示拍照触发、状态触发、天气触发、提醒历史和主动程度控制。主链路录制只需要触发一次代表性提醒。

### 旅拍与旅行盲盒

旅拍页支持拍摄照片或登记相册候选、生成朋友圈/小红书/日记/Vlog 文案、接受/完成/跳过旅行盲盒任务，以及完成后的好感/默契奖励。录制前准备 2 到 3 张可公开展示照片。

### 旅行复盘

复盘页展示路线、高光照片、完成任务、提醒历史、新增记忆、状态变化和下次旅行建议。复盘应基于已记录数据，不应把固定样例包装成真实发生。

### 设置与账号

设置页支持游客、注册、登录、主动程度、人格、语音/文字偏好、开屏动画策略、权限与隐私说明、记忆和云端同步的数据控制入口。手机号短信、OAuth 和正式发布签名仍属于后续产品化事项。

## 录制前检查清单

- [ ] `https://api.rxcccccc.icu/api/health` 或本地 `/api/health` 正常。
- [ ] App 的 `API_BASE_URL` 指向本次录制要用的后端。
- [ ] 真实模型和高德 Key 的状态已确认；若降级，旁白会明确说明。
- [ ] 手机定位、相机、相册、麦克风、通知权限按演示需要提前检查。
- [ ] 已准备可公开展示的照片素材。
- [ ] 已清理或隔离旧测试数据，避免旧记忆污染演示。
- [ ] 录屏画面不展示 `.env`、密钥、Token、私人位置、身份证明或未授权照片。

## 常见问题

### App 一直离线或请求失败

先确认构建时的 `API_BASE_URL`。当前代码默认地址是 `http://127.0.0.1:8000`，真实手机上通常指向手机自己，不是电脑或云服务器。公网版本必须传：

```powershell
--dart-define=API_BASE_URL=https://api.rxcccccc.icu
```

本地真机版本则传电脑局域网 IP，或使用 `adb reverse`。

### 模型回复像固定模板

检查 `LANXIN_MODEL_PROVIDER` 是否仍为 `mock`，以及真实模型 Key 是否可用：

```powershell
cd services/api
uv run python scripts/real_provider_smoke.py
```

### 天气、路线、POI 不真实

检查 `LANXIN_AMAP_API_KEY` 是否是高德 Web 服务 Key，不是 Android 平台 Key。无 Key 或 Key 类型错误时，页面应显示 `fallback/unconfigured`。

### Flutter 测试连接异常

如果本机配置了代理，先设置：

```powershell
$env:NO_PROXY='localhost,127.0.0.1,::1'
```

