# 蓝心同行：懂你的全旅程 AI 旅伴

本仓库用于 2026 年 AIGC 创新赛（应用赛道）的产品策划、原型与前端 Demo。

## 项目简介

- 产品方向：面向移动端的个性化 AI 旅伴，强调长期记忆、可控隐私、主动陪伴、2D 形象表达和全旅程闭环。
- 当前定位：PRD、原型、演示材料和轻量 Demo 为主，不是完整后端服务。

## 技术栈

- `demo-app/`：Vite + React + TypeScript
- `prototype/mobile.html`：单文件静态原型
- 资源素材：`project/img/`、`demo-app/public/img/`

## 本地启动

### 静态原型

```bash
python -m http.server 8765 --bind 127.0.0.1 --directory .
# 浏览器打开 http://127.0.0.1:8765/prototype/mobile.html
```

### 前端 Demo

```bash
cd demo-app
npm ci
npm run sync:images
npm run dev -- --host 127.0.0.1
```

### 构建与预览

```bash
cd demo-app
npm run build
npm run preview -- --host 127.0.0.1
```

## 环境变量

仓库目前未发现明确的运行时环境变量读取逻辑，先统一参考根目录 `.env.example`。

## 分支协作规范

请参考 `CONTRIBUTING.md`。当前约定：

- `main`：稳定可发布分支
- `dev`：开发集成分支
- `feat/*`、`fix/*`、`chore/*`、`docs/*`：功能、修复、工程和文档分支

## 测试与构建

当前主要验证方式：

```bash
cd demo-app
npm run lint --if-present
npm test --if-present
npm run build --if-present
```

仓库当前没有单独的 Python 或 Android 工程目录；如果后续新增，会在 CI 中自动检测并执行对应检查。

## 版本发布

- 在 `main` 打 tag，例如 `v0.1.0`
- 触发 Release workflow
- 自动生成 Release Notes，并上传可用构建产物

## 仓库结构

- `PRD.md`：产品需求文档
- `CLAUDE.md`：仓库约定
- `prototype/mobile.html`：静态原型
- `demo-app/`：前端 Demo
- `材料/`：比赛材料

## 素材约定

- 新增素材统一放在 `project/img/`
- Demo 通过 `/img/...` 引用素材时，先同步到 `demo-app/public/img/`