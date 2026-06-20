# Agent 图

## 节点顺序

1. `input_normalizer`
2. `context_loader`
3. `intent_router`
4. `memory_extractor`
5. `memory_confirm_interrupt`
6. `memory_writer`
7. `profile_updater`
8. `trip_context_builder`
9. `tool_planner`
10. `tool_executor`
11. `trip_planner`
12. `trip_adjuster`
13. `reminder_checker`
14. `photo_analyzer`
15. `copywriter`
16. `review_generator`
17. `avatar_state_mapper`
18. `response_composer`
19. `error_fallback`

## 当前行为

当前图仍保留确定性演示响应，但 `tool_executor` 已接入真实工具注册器。无高德 Key 时工具轨迹会返回 `provider=unconfigured` 与 `fallback=true`，不会把固定样例伪装成真实外部数据。输入“周末想去重庆两天，不想太累，喜欢夜景，我不吃香菜”后，会生成：

- 记忆候选：不吃香菜、喜欢夜景、本次旅行想轻松一点。
- 规划卡：重庆两日轻松夜景线。
- 规划卡：备选方案、高德外部导航入口、风险提示和动态调整。
- 提醒卡：饭点、位置、行为、状态和外部事件提醒。
- 复盘卡：路线、高光照片、新记忆、完成任务、蓝小心状态变化、下次建议和临时记忆转长期询问。
- 旅拍与内容：旅拍候选、照片标签评分、朋友圈/小红书/日记/Vlog 文案和旅行盲盒任务。

## 添加新节点

1. 在 `services/api/app/agents/travelmate/nodes/mock_nodes.py` 新增函数，签名为 `def node_name(state: TravelMateState) -> TravelMateState`。
2. 使用 `_next_state(state, "node_name")` 复制状态并记录访问节点。
3. 将节点名加入 `NODE_SEQUENCE`。
4. 将函数加入 `NODE_TABLE`。
5. 为节点影响的响应或状态补充 pytest。

## 添加新工具

1. 若是真实外部工具，优先在 `services/api/app/tools/external_providers.py` 或独立 provider 文件中实现，并通过 `build_tool_registry()` 注册。
2. Mock/离线降级工具仍放在 `services/api/app/tools/mock_tools.py`，并通过 `build_mock_tool_registry()` 仅供测试或显式降级使用。
3. 在 `tool_planner` 中加入调用计划，并保证输出包含 `provider`、`fallback`、`sourceTime` 或 `confidence` 等可解释元数据。
4. 在 `tests/test_real_tool_providers.py` 或对应测试中补充无 Key 降级与 HTTP 响应解析测试。
