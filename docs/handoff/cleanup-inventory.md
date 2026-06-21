# 仓库清理候选清单

更新时间：2026-06-21

本清单用于交接与清理记录。按负责人最新要求，仓库只保留 Android/vivo 原生平台壳；非 Android Flutter 平台壳已可删除并不再作为保留项。删除素材、样例或生成文件前仍必须由负责人确认用途和可恢复来源。

## 当前扫描结论

- 未发现已跟踪的 `build/`、`.dart_tool/`、`.venv/`、`node_modules/`、`.pytest_cache/`、`coverage/` 等构建缓存目录。
- 根目录和 Flutter/后端 `.gitignore` 已覆盖常见本地缓存、日志、数据库文件和压缩包。
- 仓库体积主要来自蓝小心 PNG/PSD 素材；其中 `project/img/lanxiaoxin/` 与 `apps/mobile/assets/avatars/` 存在同名 PNG 资产重复。
- 当前仅保留 Android 平台目录下的生成/配置文件；`pubspec.lock`、`services/api/uv.lock`、`app_database.g.dart` 仍保留以保证 Android 交接可复现。

## 高优先级人工确认候选

| 路径 | 约大小 | 当前用途 | 建议 |
| --- | ---: | --- | --- |
| `project/img/lanxiaoxin/lanxiaoxin_live2d_scaffold.psd` | 16.1 MB | Live2D/动态形象源文件候选，App 当前不直接引用 | 若最终不做 Live2D 或已有外部素材归档，可从代码仓库移到网盘/素材仓库；删除前需视觉负责人确认。 |
| `project/img/lanxiaoxin/*.png` | 约 18.1 MB | 与 `apps/mobile/assets/avatars/*.png` 大多同名重复，疑似源素材备份 | 若 `apps/mobile/assets/avatars/` 已是唯一运行时资产，可将 `project/img/lanxiaoxin/` 归档到外部素材仓库；删除前需确认没有设计文档继续引用。 |
| `apps/mobile/assets/avatars/*.png` | 约 18.1 MB | Flutter 运行时头像资产，`pubspec.yaml` 已引用 `assets/avatars/` | 保留，除非替换为最终 GIF/WebP/Lottie 动态资产并完成 Flutter 资产映射。 |

## 中优先级候选

| 路径 | 当前用途 | 建议 |
| --- | --- | --- |
| `apps/mobile/lib/data/mock_data.dart` | 离线样例/测试 fixture，主链路已有防回归测试禁止运行时依赖 | 暂时保留；若测试 fixture 迁到 `apps/mobile/test/fixtures/` 后，可再申请删除。 |
| `apps/mobile/lib/data/demo_agent_state.dart` | 跨页面保存最近一次真实 Agent 响应，不是 mock 源 | 保留；命名可在后续重构为 `latest_agent_state.dart`，避免队友误解。 |
| `project/img/ui/*` | UI 风格参考图和提示词 | 保留到答辩素材定稿；若已进入 PPT/设计稿，可归档。 |

## 不建议删除

| 路径 | 原因 |
| --- | --- |
| `apps/mobile/lib/data/local/app_database.g.dart` | Drift 生成代码；当前仓库未要求队友每次先跑 build_runner，保留可降低交接成本。 |
| `apps/mobile/pubspec.lock` | Flutter 应用锁定依赖版本，保证队友可复现。 |
| `services/api/uv.lock` | 后端 uv 锁文件，保证依赖可复现。 |
| `apps/mobile/android/` | Android/vivo 原生平台壳，当前唯一保留的 Flutter 平台工程。 |

## 后续人工动作

1. 视觉负责人确认是否保留 `project/img/lanxiaoxin/` 作为源素材目录。
2. 若决定瘦身，先把源 PSD/PNG 归档到外部素材仓库或网盘，再由维护者执行删除并单独提交。
3. 删除后必须运行：`flutter analyze`、头像状态相关检查、后端 mock-boundary 测试。
4. 不要运行 `git prune` 作为常规清理；当前仓库自动打包提示的 unreachable loose objects 属于本地 Git 维护项，不应混入产品交接提交。

## 已确认清理

- `apps/mobile/ios/`、`apps/mobile/macos/`、`apps/mobile/windows/`、`apps/mobile/linux/`、`apps/mobile/web/`：负责人已确认远端仓库无需保留其他端平台壳，当前项目后续只维护 Android/vivo 原生侧。
