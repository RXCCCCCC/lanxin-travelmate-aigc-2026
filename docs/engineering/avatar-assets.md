# 蓝小心多表情素材索引

当前 Flutter 端素材目录：`apps/mobile/assets/avatars/`。

## 已接入状态

| avatarState | 素材文件 | 用途 |
|---|---|---|
| `idle` | `lanxiaoxin_frontdisplay.png` | 首页待机 |
| `hello` | `lanxiaoxin_hello.png` | 打招呼 |
| `thinking` | `lanxiaoxin_thinking.png` | 思考、离线降级 |
| `planning` | `lanxiaoxin_planning.png` | 规划路线 |
| `warning` | `lanxiaoxin_warning.png` | 风险提醒 |
| `excited` | `lanxiaoxin_excited.png` | 发现小店、旅行盲盒 |
| `tired` | `lanxiaoxin_tired.png` | 精力低 |
| `happy` | `lanxiaoxin_wave.png` | 任务完成、复盘 |
| `speaking` | `lanxiaoxin_listening.png` | 语音播报占位 |
| `listening` | `lanxiaoxin_listening.png` | 倾听输入 |
| `afterPlaying` | `lanxiaoxin_after_playing.png` | 玩累后休息 |

## 后续生成提示词

用于继续生成同风格素材时，保持以下约束：

- 角色：蓝小心，蓝白清爽视觉，轻科技旅行搭子。
- 装备：小背包、耳机或导航装置、旅行徽章、地图/指南针元素。
- 画幅：半身或头像优先，透明或浅色干净背景，适合移动端卡片和 PPT。
- 风格：活泼、细心、可靠，不夸张卖萌。
- 输出：每个状态单独生成，文件名遵循 `lanxiaoxin_<state>.png`。

示例 Prompt：

> 蓝小心，蓝白清爽风格的 2D AI 旅行搭子，半身头像，轻科技旅行装备，小背包和导航耳机，表情为“担心提醒”，正在提醒用户天气或排队风险，干净浅色背景，移动端 App 素材，角色一致性高。
