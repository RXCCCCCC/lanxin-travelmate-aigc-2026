# 蓝心同行：懂你的全旅程 AI 旅伴

本仓库用于 2026 年 AIGC 创新赛（应用赛道）的产品策划、原型与演示材料。

## 项目简介

- 产品方向：面向移动端的个性化 AI 旅伴，强调长期记忆、可控隐私、主动陪伴、2D 形象表达和全旅程闭环。
- 当前定位：PRD、原型和演示材料为主；当前仓库内没有可运行的前端 Demo 工程，先以文档与原型推进。

## 当前仓库组成

- 产品文档：`doc/PRD.md`、`doc/材料中有用的信息.md`
- 竖屏原型：`prototype/mobile.html`
- 素材目录：`project/img/`

## 本地启动

### 静态原型（当前可用）

```bash
python -m http.server 8765 --bind 127.0.0.1 --directory "e:/contest/C4/2026/AIGC"
# 浏览器打开 http://127.0.0.1:8765/prototype/mobile.html
```

### 前端 Demo（当前仓库未包含）

如果后续把前端 Demo 工程（例如 `demo-app/`）放回仓库，再补充 `npm install`、`npm run dev`、`npm run build`、`npm run preview` 等命令。

## 环境变量

当前仓库没有前端或后端工程配置，因此暂无必须配置的运行时环境变量。

## 分支协作规范

当前约定：

- `main`：稳定可发布分支
- `dev`：开发集成分支
- `feat/*`、`fix/*`、`chore/*`、`docs/*`：功能、修复、工程和文档分支

## 测试与构建

当前主要验证方式：

- `git status --short` 查看改动
- `git diff -- doc/PRD.md README.md .gitignore` 查看文档差异
- 浏览器打开 `prototype/mobile.html` 验证原型链路

当前仓库没有统一的前端/后端构建命令；如后续新增真实工程，再补齐对应测试与构建说明。

## 版本发布

- 在 `main` 打 tag，例如 `v0.1.0`
- 触发 Release workflow
- 自动生成 Release Notes，并上传可用构建产物

## 仓库结构

- `CLAUDE.md`：仓库约定
- `doc/PRD.md`：产品需求文档
- `doc/材料中有用的信息.md`：比赛资源与提交检查参考
- `prototype/mobile.html`：静态原型
- `project/img/`：素材目录
- `材料/`：比赛材料

## 素材约定

- 新增素材统一放在 `project/img/`
- 当前仓库没有 `demo-app/public/img/`，因此不需要先运行素材同步脚本
