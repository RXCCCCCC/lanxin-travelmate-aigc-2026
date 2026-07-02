# 配置实施清单

> 更新时间：2026-07-02  
> 目标：把“蓝心同行”从本地 Mock 闭环推进到真实 API、真实设备、可提交 Demo 的配置闭环。真实密钥不要提交到仓库；本地写入 `services/api/.env`，CI 写入 GitHub Secrets。

## 1. 高德开放平台购买与配置

官方入口：

- Web 服务 API Key 申请：<https://lbs.amap.com/api/webservice/summary>
- 产品定价与服务升级：<https://lbs.amap.com/upgrade>
- 基础服务计费说明：<https://lbs.amap.com/pages/base_service_price>
- 服务协议：<https://lbs.amap.com/pages/terms/>
- 合规中心：<https://lbs.amap.com/compliance-center/check-and-reference/compliance>

当前项目用到的高德 Web 服务：

| 项目能力 | 高德服务分类 | 代码调用 |
| --- | --- | --- |
| 天气 | 其它基础服务-天气预报查询 | `/v3/weather/weatherInfo` |
| POI 搜索 | 基础搜索服务 | `/v5/place/text` |
| 步行路线 | 基础 LBS 服务 | `/v3/direction/walking` |
| 驾车路线 | 基础 LBS 服务 | `/v3/direction/driving` |
| 公交路线 | 基础 LBS 服务 | `/v3/direction/transit/integrated` |
| 外部导航跳转 | App URI 跳转 | `androidamap://route?...`，不消耗后端 Web API Key |

购买与开通步骤：

1. 注册并登录高德开放平台。
2. 完成个人认证或企业认证。公开/商业用途优先走企业认证，并确认是否需要技术服务许可。
3. 控制台创建应用，Key 类型选择 `Web服务`。
4. 复制 Web 服务 Key。
5. 本地 `services/api/.env` 填入：

```env
LANXIN_AMAP_BASE_URL=https://restapi.amap.com
LANXIN_AMAP_API_KEY=你的高德Web服务Key
LANXIN_TOOL_TIMEOUT_SECONDS=8
LANXIN_TOOL_RATE_LIMIT_PER_MINUTE=0
```

6. GitHub 仓库 Secrets 填入：

```text
LANXIN_AMAP_API_KEY
```

7. 验收：

```powershell
cd services/api
uv run python scripts/real_provider_smoke.py
```

预期：日志里 `amap check provider=amap fallback=False`。如果仍是 `fallback=True`，先检查 Key 类型是否为 Web 服务、账号配额是否可用、控制台是否有 IP/域名限制。

价格口径（以 2026-07-02 官方页面为准，提交前需复核）：

| 项目 | 官方价格/配额 |
| --- | --- |
| 技术服务许可基础版 | ¥50,000/年 |
| 技术服务许可高级版 | ¥100,000/年，联系商务 |
| 基础 LBS 服务流量包 | 30 元/万次，有效期 1 年 |
| 基础搜索服务流量包 | 30 元/万次，有效期 1 年 |
| 天气预报查询流量包 | 30 元/万次，有效期 1 年 |
| 基础地图定位服务流量包 | 3 元/万次，有效期 1 年 |
| 基础 LBS 调用折扣 | 0-30w：30 元/万次；30-100w：24 元/万次；100-300w：18 元/万次；更高用量联系商务 |
| 基础搜索/天气 | 官方页面标注暂无折扣，均价 30 元/万次 |
| 技术服务许可权益配额 | 基础 LBS 9,000,000/月；基础搜索 500,000/月；天气 9,000,000/月；智能硬件定位 9,000,000/月 |

比赛 Demo 建议：

- 若只做初赛/课堂展示，先用个人认证 Key 验证真实天气、POI、路线，画面里明确展示 `fallback=false`。
- 若作品公开发布、商业展示、上架或对外运营，先确认技术服务许可与合规要求，不要只按个人 Key 上线。

## 2. 后端模型配置

二选一：蓝心模型或 OpenAI 兼容模型。未配置时保留 `mock`，但不能声称是真实模型链路。

蓝心模型：

```env
LANXIN_MODEL_PROVIDER=lanxin
LANXIN_LANXIN_BASE_URL=你的蓝心接口地址
LANXIN_LANXIN_API_KEY=你的蓝心密钥
LANXIN_LANXIN_MODEL=模型名
LANXIN_MODEL_TIMEOUT_SECONDS=20
```

OpenAI 兼容模型：

```env
LANXIN_MODEL_PROVIDER=openai
LANXIN_OPENAI_BASE_URL=你的OpenAI兼容base URL
LANXIN_OPENAI_API_KEY=你的OpenAI兼容API Key
LANXIN_OPENAI_MODEL=模型名
LANXIN_MODEL_TIMEOUT_SECONDS=20
```

CI Secrets 对应填入：

```text
LANXIN_MODEL_PROVIDER
LANXIN_LANXIN_BASE_URL
LANXIN_LANXIN_API_KEY
LANXIN_LANXIN_MODEL
LANXIN_OPENAI_BASE_URL
LANXIN_OPENAI_API_KEY
LANXIN_OPENAI_MODEL
```

验收：

```powershell
cd services/api
uv run python scripts/real_provider_smoke.py
uv run pytest tests/test_model_providers.py -q
```

## 3. 后端安全、数据库与部署配置

本地开发可使用 SQLite；公开演示或部署建议使用 Postgres，并必须替换 JWT secret。

```env
LANXIN_DATABASE_URL=postgresql+psycopg://USER:PASSWORD@HOST:5432/lanxin_travelmate
LANXIN_AUTH_TOKEN_SECRET=至少32字节的随机字符串
LANXIN_AUTH_TOKEN_TTL_SECONDS=2592000
LANXIN_LOG_LEVEL=INFO
```

部署/公网联调时按实际前端域名配置 CORS：

```env
LANXIN_CORS_ORIGINS=["https://your-domain.example"]
```

验收：

```powershell
cd services/api
uv run python scripts/migration_plan.py check
uv run pytest tests/test_auth_routes.py tests/test_authenticated_data_routes_scope.py tests/test_privacy_routes.py -q
```

## 4. Flutter / Android 配置

本机已完成：

| 配置 | 当前值 |
| --- | --- |
| Flutter SDK | `G:\develop\flutter` |
| Android SDK | `G:\develop\Android\Sdk` |
| Pub Cache | `G:\develop\pub-cache` |
| Gradle Cache | `G:\develop\.gradle` |
| SQLite DLL | `G:\develop\sqlite\sqlite3.dll` |

运行 App 时按目标设备选择：

```powershell
cd apps/mobile
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
flutter run --dart-define=API_BASE_URL=http://你的电脑局域网IP:8000
```

发布前仍需人工确认：

| 配置 | 当前状态 | 下一步 |
| --- | --- | --- |
| `applicationId` | `com.lanxin.lanxin_travelmate` | 确认是否最终包名 |
| `versionCode` / `versionName` | Flutter 默认读取 | 发布前锁定版本 |
| release 签名 | 仍使用 debug signing | 生成正式 keystore 并替换 Gradle 配置 |
| Android/vivo 真机权限 | 需真机验收 | 相册、相机、定位、麦克风、通知、TTS |

验收：

```powershell
python scripts/android_release_preflight.py --json
cd apps/mobile
flutter analyze
flutter test --concurrency=1
flutter build apk --debug
```

## 5. 最终提交前配置检查

- [ ] 高德 Web 服务 Key 已配置，天气/POI/路线 smoke 为 `fallback=false`。
- [ ] 模型 Provider 已配置，真实模型 smoke 通过。
- [ ] `LANXIN_AUTH_TOKEN_SECRET` 已替换默认值。
- [ ] 若公开部署，`LANXIN_DATABASE_URL` 指向 Postgres，迁移检查通过。
- [ ] GitHub Secrets 与本地 `.env` 保持同一套真实 provider 配置。
- [ ] Android 包名、版本号、签名、SDK 35、debug/release APK 均确认。
- [ ] Demo 截图和视频不泄露 Key、Token、用户隐私或未授权照片。
- [ ] 高德账号主体、购买方式、技术服务许可和合规要求由负责人确认。
