# Agent 评测说明

## 目标

蓝心同行将 Agent 的确定性能力与真实 Provider 效果分开评测：

- 确定性评测用于 CI 和本地回归，不调用模型或高德 API。
- 真实 Provider 评测用于人工 smoke 和效果观察，不作为普通提交的稳定门禁。

这样可以避免 API Key、网络、RPM、模型随机性和第三方服务波动掩盖代码回归。

## 数据集

Golden Cases 位于：

```text
services/api/evals/cases/golden_cases.json
```

当前包含 32 条中文和英文场景，覆盖：

- 纯聊天与无工具问题；
- 中文、英文行程规划；
- 多轮目的地继承与目的地切换；
- 长期、当前行程、敏感和冲突记忆；
- 天气、POI、路线工具选择；
- Provider、Schema、限流降级；
- 旅行复盘。

每条 Case 声明输入消息、结构化上下文和期望约束，不保存真实用户对话。

## 评分器

确定性评分器检查：

| 指标 | 判定方式 |
| --- | --- |
| 意图准确率 | `IntentDecision.intent` 与期望一致 |
| 工具选择准确率 | 实际工具集合与期望集合完全一致 |
| 目的地一致性 | ToolPlan 中目的地与期望一致 |
| 记忆命中率 | 期望记忆标题均被规则抽取 |
| 敏感确认规则 | 敏感候选必须同时标记 `sensitive` 和 `requiresExplicitConsent=true` |
| Schema 通过率 | Case、结果和报告均通过 Pydantic 校验 |
| fallback 比例 | 记录确定性 Planner 的降级使用情况 |
| P50/P95 | 记录本地规则执行耗时，不冒充真实 Provider 延迟 |

## 运行

```powershell
cd services/api
uv run python -m evals.runner --output-dir artifacts/evals
```

输出：

- `artifacts/evals/deterministic-eval.json`
- `artifacts/evals/deterministic-eval.md`

生成目录默认被 Git 忽略。

## 当前基线

2026 年 8 月 10 日的本地确定性基线：

- Cases：32
- 通过：32
- 意图准确率：100%
- 工具选择准确率：100%
- 目的地一致性：100%
- 记忆命中率：100%
- 敏感确认规则：100%
- Schema 通过率：100%

## 边界

- 本地规则耗时不能代表大模型或高德 API 的线上延迟。
- 规则评测不能判断回复是否自然、是否有帮助。
- 真实 Provider 评测需要单独记录模型、Prompt 版本、配置、日期和外部服务状态。
- CI 工作流接入尚待单独确认；当前 Runner 和测试已可直接执行。
