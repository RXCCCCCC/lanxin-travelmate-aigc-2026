# 蓝心同行：懂你的全旅程 AI 旅伴（项目仓库）

本仓库为 2026 年 AIGC 创新赛（应用赛道）的项目资料与轻量原型集合，用于存放产品需求文档、原型与前端 Demo。当前仓库以产品策划、PRD、演示原型为主，非完整后端服务。

## 项目目标
- 产品方向：面向移动端的个性化 AI 旅伴（长期记忆、可控隐私、主动陪伴、2D 形象表达、全旅程闭环）。
- 用途：整理 PRD、演示原型、前期 Demo 与提交材料，支持快速在本地预览原型与前端演示。

## 仓库结构（关键文件）
- `PRD.md`：产品需求文档（核心说明）。
- `CLAUDE.md`：仓库维护与开发约定。
- `prototype/mobile.html`：单文件竖屏静态原型（可直接打开预览）。
- `demo-app/`：基于 Vite 的前端 Demo（用于演示与热开发）。
  - `demo-app/public/img/`：Demo 使用的静态素材（由同步脚本维护）。
  - `demo-app/src/`：Demo 源码。
- `project/img/`：原始素材与角色立绘（设计稿、表情等）。
- `材料/`：比赛材料与宣讲 PPT/PDF。

## 快速开始
1. 本地预览单文件原型：
   - 在仓库根目录运行一个静态服务器（示例）：

```bash
python -m http.server 8765 --bind 127.0.0.1 --directory "e:/contest/C4/2026/AIGC"
# 然后在浏览器打开 http://127.0.0.1:8765/prototype/mobile.html
```

2. 运行前端 Demo（需 Node.js）：
   - 进入 `demo-app/`：

```bash
cd demo-app
npm install
npm run sync:images   # 将 project/img 同步到 demo-app/public/img
npm run dev -- --host 127.0.0.1
```

3. 构建与预览生产包：

```bash
cd demo-app
npm run build
npm run preview -- --host 127.0.0.1
```

## 常用脚本说明
- `demo-app/sync-images.mjs`：把 `project/img/` 中的素材同步到 `demo-app/public/img/`，保证原型与 Demo 的素材路径一致。

## 素材与约定
- 设计素材统一保存在 `project/img/`；若要让 Demo 页面通过 `/img/...` 引用，请先运行 `npm run sync:images`。
- 文档默认使用中文维护（见 `CLAUDE.md` 中说明）。

## 检查清单（提交前）
- [ ] PRD 与 Demo 演示脚本一致。
- [ ] `prototype/mobile.html` 在本地可正常打开并适配竖屏截图。
- [ ] Demo 的蓝小心角色图在页面完整展示（不是只截到头部）。

## 联系与贡献
欢迎通过仓库 Issues 提交建议或更改请求。有关开发约定与命令请参阅 `CLAUDE.md`。

---
（README 自动生成 — 如果需要补充更详细的安装/部署步骤或增加示例截图，我可以根据需求继续补充。）