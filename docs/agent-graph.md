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

当前图是确定性 Mock 流程。输入“周末想去重庆两天，不想太累，喜欢夜景，我不吃香菜”后，会生成：

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

1. 在 `services/api/app/tools/mock_tools.py` 新增工具函数。
2. 在 `build_mock_tool_registry()` 注册工具名。
3. 在 `tool_planner` 中加入调用计划。
4. 在 `tests/test_tools.py` 补充工具存在性和返回结构测试。
