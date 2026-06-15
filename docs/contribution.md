# 贡献指南

## 开发原则

- 默认中文文档和中文注释。
- 优先完成可运行、可体验、可验收闭环。
- 新能力先 Mock，真实 API 必须有降级路径。
- 不引入大型 UI 框架，不实现高权限风险能力。
- 修改超过 3 个文件前先拆分任务，保持模块边界清晰。

## 本地验证

后端：

```powershell
cd services/api
uv sync
uv run pytest
```

前端：

```powershell
cd apps/mobile
flutter pub get
$env:NO_PROXY='localhost,127.0.0.1,::1'
flutter analyze
flutter test
```

## 添加蓝小心状态

1. 在 `apps/mobile/lib/core/constants/avatar_states.dart` 新增枚举值。
2. 把素材放入 `apps/mobile/assets/avatars/`。
3. 确认 `pubspec.yaml` 已包含 `assets/avatars/`。
4. 更新 Agent 响应中的 `avatarState` 映射。
5. 补充测试或手动验收截图。

## 分支协作

- 从 `dev` 拉功能分支。
- 提交前运行 Flutter 和 API 基础检查。
- 不在未确认时执行 push、merge、force push 或删除远程分支。
