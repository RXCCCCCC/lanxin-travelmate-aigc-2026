# 贡献指南

## 分支说明

- `main`：正式版本分支，只保留稳定可发布代码。
- `dev`：开发集成分支，所有功能优先合并到这里。
- `feat/*`：新功能开发分支。
- `fix/*`：Bug 修复分支。
- `chore/*`：工程配置、依赖、CI、文档等修改。
- `docs/*`：文档类修改。

## 开发流程

1. 从 `dev` 拉取最新代码。
2. 创建自己的功能分支。
3. 在本地完成开发与自测。
4. 提交 commit 并 push 到远程分支。
5. 创建 PR 合并到 `dev`。
6. CI 通过后再合并。
7. 阶段稳定后，由 `dev` 发起 PR 合并到 `main`。
8. `main` 打 tag 后创建 Release。

## 常用命令

```bash
git checkout dev
git pull origin dev
git checkout -b feat/your-feature

git add .
git commit -m "feat: your feature"
git push origin feat/your-feature
```

## 禁止事项

- 禁止直接 push 到 `main`。
- 禁止直接 push 到 `dev`。
- 禁止在 `main` 上直接开发。
- 禁止 force push `main/dev`。
- 禁止提交 `.env`、密钥、token 等敏感信息。

## Commit message 规范

- `feat: add travel plan page`
- `fix: resolve login token error`
- `docs: update setup guide`
- `ci: add release workflow`
- `chore: update dependencies`
