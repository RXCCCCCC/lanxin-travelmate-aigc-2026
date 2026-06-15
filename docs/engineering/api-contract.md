# API 契约

## `GET /api/health`

返回：

```json
{
  "status": "ok",
  "service": "lanxin-travelmate-api",
  "version": "0.1.0"
}
```

## `POST /api/agent/chat`

请求：

```json
{
  "message": "周末想去重庆两天，不想太累，喜欢夜景，我不吃香菜",
  "sessionId": "demo-session",
  "userId": "guest",
  "tripId": "demo-chongqing-weekend",
  "context": {}
}
```

响应字段固定为 camelCase：

```json
{
  "replyText": "...",
  "voiceText": "...",
  "avatarState": "planning",
  "emotion": "curious",
  "cards": [],
  "memoryCandidates": [],
  "toolTrace": [],
  "nextActions": [],
  "syncSuggestions": [],
  "errors": []
}
```

`syncSuggestions` 可包含记忆冲突提示：

```json
{
  "type": "memoryConflict",
  "title": "发现节奏偏好变化",
  "description": "本次行程优先按低强度规划，长期画像不直接覆盖。",
  "conflictId": "conflict-pace"
}
```

## 卡片类型

- `tripPlan`：出行规划卡，包含标题、目的地、日期、每日行程、画像匹配解释、风险提示和动态调整。
- `reminders`：主动提醒列表，包含触发类型、标题、说明和冷却时间。
- `tripReview`：旅行复盘卡，包含路线、高光照片、新增记忆、完成任务、状态变化、下次建议和临时记忆沉淀询问。

## 记忆候选

```json
{
  "id": "mem-cilantro",
  "title": "不吃香菜",
  "content": "用户明确表示不吃香菜，后续餐厅和菜品推荐需要避开。",
  "scopeOptions": ["longTerm", "currentTrip", "temporary", "ignore"],
  "recommendedScope": "longTerm",
  "reason": "这是稳定饮食偏好，会长期影响餐饮推荐。"
}
```

## `GET /api/memory/capsules`

返回后端 Mock 记忆胶囊列表：

```json
{
  "items": []
}
```

## `POST /api/memory/capsules`

请求：

```json
{
  "id": "mem-cilantro",
  "title": "不吃香菜",
  "content": "后续推荐避开香菜。",
  "scope": "longTerm"
}
```

## `PUT /api/memory/capsules/{memoryId}`

请求：

```json
{
  "title": "不要香菜",
  "content": "点单提醒不要香菜。"
}
```

## `DELETE /api/memory/capsules/{memoryId}`

返回：

```json
{
  "deleted": true
}
```

## `GET /api/profile/me` 与 `PUT /api/profile/me`

画像字段：

```json
{
  "travelPace": "轻松",
  "dietaryPreferences": ["不吃香菜"],
  "interestTags": ["夜景"]
}
```

## `POST /api/trip/plan`

根据输入消息生成 Mock 出行规划卡。

规划卡 P1 字段：

```json
{
  "alternatives": [
    {
      "id": "alt-rainy-day",
      "title": "雨天室内轻松版",
      "summary": "减少山城步道停留，改去室内观景。",
      "bestFor": "下雨或体力下降时"
    }
  ],
  "navigationLinks": [
    {
      "provider": "amap",
      "label": "打开高德导航到洪崖洞",
      "url": "androidamap://route?sourceApplication=lanxin-travelmate&dname=洪崖洞&dev=0&t=0"
    }
  ]
}
```

## `POST /api/trip/review`

请求：

```json
{
  "message": "生成今天重庆夜景行程复盘",
  "tripId": "demo-chongqing-weekend",
  "completedTasks": [
    {
      "id": "task-night-photo",
      "title": "拍一张不是游客照的重庆夜景",
      "status": "completed"
    }
  ],
  "temporaryMemories": [
    {
      "id": "mem-slow-pace",
      "title": "本次旅行想轻松一点",
      "content": "本次行程希望低强度，减少跨区移动。"
    }
  ]
}
```

响应：

```json
{
  "route": "解放碑 → 山城步道 → 洪崖洞 → 南山一棵树",
  "highlightPhotos": ["洪崖洞夜景"],
  "newMemories": ["喜欢夜景"],
  "completedTasks": [],
  "avatarStatusChanges": ["默契值 +1", "好感度 +2"],
  "nextTripSuggestions": ["成都慢节奏美食线"],
  "temporaryMemoryPromotions": []
}
```

## `POST /api/trip/reminders/trigger`

根据时间或位置等触发类型返回主动提醒列表。

P1 支持的 `triggerType`：

- `behavior`：新拍照、长时间无操作等行为触发。
- `status`：蓝小心精力低、默契值变化等状态触发。
- `external`：天气变化、排队变长等外部事件触发。

请求示例：

```json
{
  "triggerType": "behavior",
  "location": "洪崖洞",
  "eventPayload": {
    "event": "newPhoto"
  }
}
```

## `GET /api/agent/avatar-state`

返回蓝小心状态字段：精力、心情、好奇心、默契值、好感度。

## `GET /api/photo/candidates`

返回用户主动加入或选择后的旅拍候选集。字段包含 `id`、`location`、`score`、`description`、`tags`、`canAddToReview`。

## `POST /api/photo/copywriting`

根据候选照片生成朋友圈、小红书、旅行日记和 Vlog 旁白文案。不会自动发布到任何社交平台。

请求：

```json
{
  "photoIds": ["photo-night"],
  "persona": "活泼向导",
  "style": "轻松"
}
```

## `GET /api/trip/blind-box/tasks`

返回 5 类旅行盲盒任务：照片、美食、路线、互动、故事。任务结果可进入旅行复盘。
