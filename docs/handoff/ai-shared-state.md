# AI 共享开发状态

> 用途：给 Claude Code、Codex 和人工成员提供同一份短上下文。新会话优先读本文件，再按需读 `docs/todo.md`、`CLAUDE.md` 和具体代码。  
> 维护口径：只写当前结论和下一步，不复述完整对话，不堆历史细节。  
> 最近更新：2026-06-28 by Codex

## 当前阶段

项目主链路代码和交接文档已经基本成型，当前重点是比赛提交前的真实能力验收、Android/vivo 真机验证、APK/部署验证、Demo/PPT/素材与平台提交。

## 当前结论

- 仓库协作上下文以 `CLAUDE.md` 为总规则，`AGENTS.md` 继续引用 `CLAUDE.md`。
- 后续 Claude Code 和 Codex 不同步完整聊天窗口，而是共同维护本文件作为项目级共享状态。
- `docs/todo.md` 只保留需要人工、真实设备、真实密钥、授权、提交确认等事项；AI 不应把 Mock 或固定样例标记为真实完成。
- 项目仍保持 Android/vivo 优先，不主动恢复 iOS、macOS、Windows、Linux、Web 平台工程。
- 代码变更前要遵守现有 GitNexus/验证要求；文档类轻量变更可做 `git diff --check` 作为基本检查。

## 下一步

1. 每个新 AI 会话先读本文件，确认当前阶段、约束和下一步。
2. 如果继续做代码开发，按 `CLAUDE.md` 中的 GitNexus、测试和 Android-only 约束执行。
3. 如果继续做提交准备，优先推进 `docs/todo.md` 中真实模型、高德 Key、真机、APK、Docker、PPT、Demo 和上传确认。
4. 每次阶段性工作结束后，用 3 到 8 条短 bullet 更新本文件，保证下一位 AI 能直接接手。

## 最近日报

### 2026-06-28

- 建立 Claude Code 与 Codex 共用的项目级状态同步方案。
- 采用低摩擦 Markdown 维护方式，不新增强制脚本或 MCP 服务。
- 共享状态放在 `docs/handoff/ai-shared-state.md`，同步规则放在 `docs/handoff/ai-sync-protocol.md`。
- 目标是让新会话先读短状态，再按需读代码，减少重复全仓库扫描。

## 未决人工事项

以 `docs/todo.md` 为准。本文件不重复维护完整待办清单。
