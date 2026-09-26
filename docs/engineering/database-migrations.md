# 数据库迁移与回滚策略

本文用于真实 Postgres 环境发布前的人工检查。当前 API 容器启动时会执行 `uv run alembic upgrade head`，本地和 Docker/Postgres 共用 `services/api/migrations` 下的 Alembic 版本链。

## 发布前检查

1. 确认 `LANXIN_DATABASE_URL` 指向目标 Postgres，不要指向本地临时库。
2. 执行迁移链检查：

```powershell
cd services/api
uv run python scripts/migration_plan.py check
```

3. 记录当前数据库 revision：

```powershell
uv run alembic current
```

4. 对目标数据库做可恢复备份，并记录备份文件位置。生产环境不得在没有备份的情况下升级 schema。

## 升级流程

使用脚本生成人工执行命令：

```powershell
uv run python scripts/migration_plan.py plan --target head --rollback-to <升级前revision> --backup-path <备份文件路径>
```

脚本只打印命令，不会直接修改数据库。人工确认维护窗口、备份和环境变量后再执行输出中的 `uv run alembic upgrade head`。

## 回滚流程

如果升级后 smoke 检查失败：

1. 停止写入或切到维护模式。
2. 执行脚本输出的 `uv run alembic downgrade <升级前revision>`。
3. 如果升级后已经产生真实写入，按备份恢复策略恢复数据；Alembic downgrade 只负责 schema，不保证业务数据自动恢复。
4. 重新执行 `uv run alembic current`，确认 revision 回到预期版本。
5. 记录失败原因、受影响 revision 和恢复方式，再决定是否重新发布。

## 验收边界

AI 可以维护迁移脚本、版本链、Docker 启动前升级和回滚文档；真实 Postgres 容器启动、生产数据库备份恢复、维护窗口和回滚演练必须由人工在目标环境确认。