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

记忆候选会额外包含隐私分级字段，端侧必须提示用户确认后才能保存：

```json
{
  "title": "不吃香菜",
  "category": "dietary_preference",
  "sensitivity": "personal",
  "requiresExplicitConsent": true,
  "recommendedScope": "longTerm",
  "scopeOptions": ["longTerm", "currentTrip", "temporary", "ignore"]
}
```

身体状态、位置和同行人等更敏感信息会使用 `sensitivity=sensitive`，默认不推荐长期保存：

```json
{
  "title": "身体状态需要照顾",
  "category": "health",
  "sensitivity": "sensitive",
  "requiresExplicitConsent": true,
  "recommendedScope": "currentTrip",
  "scopeOptions": ["currentTrip", "temporary", "ignore"]
}
```

当存在 `sensitivity=sensitive` 的候选时，`syncSuggestions` 会包含 `type=sensitiveMemoryConfirmation`。
## `GET /api/memory/capsules`

返回当前用户已确认/同步的记忆胶囊列表，支持 `userId` 查询参数：

```json
{
  "items": []
}
```

## `POST /api/memory/capsules`
记忆若需要进入某次旅程复盘，应设置 `sourceText` 为对应 `tripId`。其中 `scope=currentTrip` 或 `scope=longTerm` 且 `status=confirmed` 的记忆会进入 `newMemories`；`scope=temporary` 且 `status=confirmed` 的记忆会进入 `temporaryMemoryPromotions`，用于提示用户是否长期沉淀。

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

画像字段同时承载设置页偏好；`/api/agent/chat` 会按 `userId` 自动读取这些设置并注入 `context.userSettings`，模型调用审计摘要也会保留脱敏后的设置字段。

```json
{
  "travelPace": "轻松",
  "dietaryPreferences": ["不吃香菜"],
  "interestTags": ["夜景"]
}
```

## `POST /api/trip/plan`

根据输入消息生成出行规划卡，并保存为当前用户当前旅程。同一 `tripId` 再次提交会覆盖当前规划，作为重规划记录。

请求可包含真实规划输入：

```json
{
  "userId": "guest",
  "tripId": "trip-1",
  "message": "周末想去杭州三天，少走路。",
  "destination": "Hangzhou",
  "startDate": "2026-07-01",
  "endDate": "2026-07-03",
  "budget": "medium",
  "companions": ["mother", "child"],
  "preferences": ["night view", "less walking"],
  "transportMode": "transit",
  "tripStyle": "family_relaxed",
  "replanReason": "weather_risk"
}
```

请求可包含 `originCoordinate` 和 `destinationCoordinate`，格式为 `{ "latitude": number, "longitude": number }`；响应会包含 `planningInputs`，并把预算、交通方式、同行人、偏好、坐标和重规划原因写入规划上下文。Agent 工具规划会将坐标转换为高德路线工具使用的 `lng,lat` 字符串并传入 `route_tool.originLocation/destinationLocation`，便于真实路线耗时进入规划解释。

规划卡 P1 字段：`externalContext` 会汇总天气、POI 和路线工具结果；后端会把天气提示、POI 营业时间和路线耗时写入 `profileMatches` 或 `risks`，方便端侧解释规划为什么这样安排。多人出游协调完成后，端侧可在 `POST /api/trip/plan` 中传入 `groupCoordination`，后端会把该结构写入 `planningInputs.groupCoordination`，并将折中节奏/预算摘要写入 `profileMatches`，但不展示成员敏感偏好原文。

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

## Agent `toolTrace` 外部工具元数据

`/api/agent/chat` 的 `toolTrace` 会记录天气、POI、路线等工具调用。真实高德 Key 未配置时，工具返回明确降级，不计为真实数据：

```json
{
  "tool": "weather_tool",
  "provider": "unconfigured",
  "fallback": true,
  "mock": false,
  "output": {
    "fallbackReason": "真实天气 API 尚未配置；请设置 LANXIN_AMAP_API_KEY 或接入其他天气服务商。",
    "sourceTime": null,
    "confidence": 0.0
  }
}
```

配置 `LANXIN_AMAP_API_KEY` 后，高德天气、POI 和路线工具会返回 `provider=amap`、`fallback=false`，并解析温度、天气、POI 评分/营业时间、路线距离和耗时。`route_tool` 支持 `mode=walking/driving/transit/mixed`：驾车返回 `costEstimate.taxiCny/tollCny`、`trafficLights`、`congestionSegments`，公交返回 `costEstimate.transitCny`、`transfers`、`walkingDistanceMeters`，混合路线返回 `alternatives`。Provider 对成功响应做进程内缓存，并对 HTTP 错误执行一次重试。
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
  "nextTripSuggestions": ["Plan a route like Riverside Gate next time because confirmed preference was used."],
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

返回用户主动加入或选择后的旅拍候选集，支持 `userId` 和 `tripId` 查询参数。字段包含 `id`、`location`、`score`、`description`、`tags`、`canAddToReview`、`copywriting`。


## `POST /api/photo/candidates`

端侧在用户选择照片或拍照后写入旅拍候选元数据。真实图片文件上传可后续接对象存储；当前先保存 `localUri/remoteUrl`、地点、标签和评分。

```json
{
  "userId": "guest",
  "tripId": "trip-1",
  "localUri": "content://photo/night.jpg",
  "location": "洪崖洞",
  "score": 9.3,
  "description": "夜景灯光层次明显。",
  "tags": ["夜景", "高光照片"],
  "canAddToReview": true
}
```

## `POST /api/photo/upload-metadata`

保存用户选择或拍摄照片的文件元数据，供后续多模态分析、复盘引用和对象存储接入。
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

返回 5 类旅行盲盒任务：照片、美食、路线、互动、故事。可选查询参数 `userId`、`tripId` 会合并该用户本次旅程的真实任务状态。

响应字段包含 `status`、`rewardApplied`、`acceptedAt`、`completedAt` 和 `note`。无状态记录时返回 `status=available`。

## `POST /api/trip/blind-box/tasks/{taskId}/status`

写入盲盒任务状态到 `blind_box_task_records`。支持 `accepted`、`skipped`、`completed`；`completed` 会应用奖励并可在后续 `POST /api/trip/review` 中自动进入 `completedTasks`。响应包含 `rewardApplied` 和 `rewardDeltas`，当前完成奖励为 `{ "affection": 2, "rapport": 1 }`，端侧可即时展示蓝小心状态数值变化。

```json
{
  "userId": "guest",
  "tripId": "trip-1",
  "status": "completed",
  "note": "拍到了江边夜景"
}
```

## `GET /api/trip/current`

读取当前用户最近一次保存的旅程。无旅程时返回：

```json
{
  "tripId": null,
  "userId": "guest",
  "status": "empty",
  "plan": {}
}
```

## `DELETE /api/trip/current`

清空当前用户的本次旅行数据：

```json
{
  "deleted": 1,
  "userId": "guest"
}
```

## `GET /api/memory/export`

导出当前用户全部记忆胶囊，用于隐私可控和数据迁移：

```json
{
  "userId": "guest",
  "items": []
}
```

## `DELETE /api/memory/capsules`

按 `userId` 清空全部记忆胶囊：

```json
{
  "deleted": 3,
  "userId": "guest"
}
```

## `POST /api/sync/push`

端侧向后端推送记忆、画像和旅程数据。后端按 `userId` 持久化并记录同步记录。记忆项支持 `updatedAt`，当端侧副本早于服务端版本时会返回 `conflicts`；默认 `conflictStrategy=serverWins` 不覆盖服务端数据，端侧明确传 `clientWins` 时才覆盖。

```json
{
  "userId": "guest",
  "conflictStrategy": "serverWins",
  "memories": [
    {
      "id": "mem-a",
      "title": "不吃香菜",
      "content": "点餐时提醒避开香菜。",
      "scope": "longTerm",
      "updatedAt": "2026-06-20T10:00:00+08:00"
    }
  ],
  "profile": null,
  "trips": []
}
```

响应包含 `pushed` 和 `conflicts`：

```json
{
  "status": "ok",
  "pushed": {"memories": 0, "profile": 0, "trips": 0},
  "conflicts": [
    {
      "entityType": "memory",
      "entityId": "mem-a",
      "resolution": "serverWins",
      "clientUpdatedAt": "2026-06-20T09:00:00+08:00",
      "serverUpdatedAt": "2026-06-20T10:00:00+08:00"
    }
  ]
}
```

## `GET /api/sync/pull`

按 `userId` 拉取云端记忆、画像和旅程数据。

## `POST /api/sync/selected-memory`

仅同步用户选择的记忆 ID，适合“部分同步”模式。
## `POST /api/sync/revoke`

撤销指定云端同步副本，并写入 `sync_records` 作为审计记录。支持按 `userId` 删除指定记忆、当前画像和指定旅程；不会影响未列入请求的其他云端数据。

```json
{
  "userId": "guest",
  "memories": ["mem-a"],
  "profile": true,
  "trips": ["trip-a"]
}
```

响应：

```json
{
  "status": "ok",
  "revoked": {"memories": 1, "profile": 1, "trips": 1},
  "records": [
    {"entityType": "memory", "entityId": "mem-a", "status": "revoked"}
  ]
}
```
## Auth 与用户

### `POST /api/auth/guest`

创建或读取游客用户，返回 HMAC-SHA256 JWT Bearer token：

```json
{
  "deviceId": "device-a",
  "displayName": "游客"
}
```

### `POST /api/auth/register`

邮箱/账号 + 密码注册。当前使用后端 PBKDF2 密码哈希，并返回 HMAC-SHA256 JWT。生产环境必须通过 `LANXIN_AUTH_TOKEN_SECRET` 覆盖默认开发 secret。

```json
{
  "account": "user@example.com",
  "password": "secret123",
  "displayName": "蓝心用户"
}
```

### `POST /api/auth/upgrade-guest`

需要 `Authorization: Bearer <guestAccessToken>`。将当前游客原地升级为密码账号，不改变 `userId`，因此该游客名下已经持久化的记忆、画像、旅程、照片候选、提醒历史、路线点、蓝小心状态事件和同步记录继续按同一用户归属读取。请求账号已存在时返回 `409`。

请求：
```json
{
  "account": "user@example.com",
  "password": "secret123",
  "displayName": "蓝心用户"
}
```

响应包含新的非游客 JWT、迁移策略和归属数据摘要：
```json
{
  "userId": "guest-device-a",
  "displayName": "蓝心用户",
  "authMode": "password",
  "isGuest": false,
  "accessToken": "<jwt>",
  "migrationStrategy": "in_place_guest_upgrade",
  "migrationSummary": {
    "memories": 1,
    "profiles": 1,
    "trips": 1,
    "photoCandidates": 0,
    "reminders": 0,
    "groupCoordinations": 0,
    "blindBoxTasks": 0,
    "routePoints": 0,
    "avatarStateEvents": 0,
    "syncRecords": 0
  }
}
```
### `POST /api/auth/login`

账号密码登录，返回 `accessToken`。token 为三段式 JWT，payload 至少包含 `sub`、`isGuest`、`iat`、`exp`。

### `GET /api/users/me`

需要 `Authorization: Bearer <accessToken>`，返回当前用户信息。后端仍兼容旧本地 HMAC token 以便既有游客会话过渡，但新签发 token 均为 JWT。
## `GET /api/audio/status`

返回后端音频能力状态。真实 ASR/TTS 未配置时返回 fallback ready，前端可使用文字或系统 TTS 降级。

## `POST /api/audio/asr`

语音转文字任务接口。当前支持 `audioRef` 和 `mockText` 进行端到端联调；真实 ASR 接入后返回同一结构。

```json
{
  "userId": "guest",
  "audioRef": "file-audio-1",
  "mockText": "我想用语音规划重庆两天",
  "language": "zh-CN"
}
```

## `POST /api/audio/tts`

文字转语音任务接口。真实 TTS 未配置时返回 `voiceText` 和 `audioUrl: null`，前端可使用系统 TTS 或文字模式。

```json
{
  "userId": "guest",
  "text": "蓝小心正在规划你的路线。",
  "voice": "lanxiaoxin",
  "format": "mp3"
}
```

## `GET /api/privacy/summary`

返回端侧可展示的隐私说明、权限用途、记忆保存规则、敏感分级和用户控制能力。

```json
{
  "version": "2026-06-19",
  "permissions": [],
  "memoryRules": [],
  "sensitivityLevels": [],
  "userControls": {
    "canExportData": true,
    "canDeleteAllMemories": true,
    "canClearCurrentTrip": true,
    "canDisableSync": true,
    "canUseGuestMode": true
  }
}
```
## 持久化事件接口补充

### `POST /api/trip/avatar-state/events`

写入蓝小心状态变化事件到 `avatar_state_events`。用于记录记忆确认、盲盒完成、行程调整等真实交互对精力、心情、好奇心、默契值、好感度的影响。

```json
{
  "userId": "guest",
  "tripId": "trip-1",
  "eventType": "memory_confirmed",
  "title": "确认了不吃香菜记忆",
  "deltas": {"rapport": 2, "affection": 1},
  "reason": "用户确认长期记忆，默契提升"
}
```

### `GET /api/trip/avatar-state/events`

按 `userId` 和 `tripId` 读取状态事件历史。`POST /api/trip/review` 会优先使用这些事件生成 `avatarStatusChanges`。盲盒任务被标记为 `completed` 时，后端会自动写入一次 `blind_box_completed` 状态事件。
### `POST /api/trip/route-points`

写入用户本次旅程的真实路线轨迹点到 `trip_route_points`。该接口用于端侧定位、手动打点或导入轨迹后的云端持久化；没有真机定位权限时不应伪造为真实轨迹。

```json
{
  "userId": "guest",
  "tripId": "trip-1",
  "points": [
    {
      "label": "真实起点",
      "latitude": 29.56301,
      "longitude": 106.55156,
      "source": "device",
      "recordedAt": "2026-06-20T09:00:00+08:00"
    }
  ]
}
```

响应包含 `saved`、标准化 `points` 和按点位顺序拼接的 `route`。

### `GET /api/trip/route-points`

按 `userId` 和 `tripId` 读取已保存路线轨迹点，响应同样包含 `points` 与 `route`。`POST /api/trip/review` 会优先使用这里的真实路线作为复盘 `route`。
### `GET /api/trip/review`

按 `tripId` 读取最近一次已保存的旅行复盘。

```json
{
  "reviewId": "review-...",
  "tripId": "trip-1",
  "review": {
    "route": "...",
    "completedTasks": [],
    "temporaryMemoryPromotions": []
  }
}
```

### `POST /api/trip/review`

生成复盘后会写入 `cloud_trip_reviews`，响应在原复盘字段外追加 `reviewId` 和 `tripId`。如果请求没有显式传入 `completedTasks`，后端会读取当前 `userId/tripId` 下已完成的盲盒任务并写入复盘；同时会优先读取 `trip_route_points` 生成真实 `route`，聚合 `photo_candidates.can_add_to_review=true` 的照片地点为 `highlightPhotos`，聚合 `reminder_events` 为 `reminderHighlights`，聚合 `avatar_state_events` 为 `avatarStatusChanges`，并按 `CloudMemory.source_text=tripId` 聚合本次旅程确认记忆到 `newMemories/temporaryMemoryPromotions`；`nextTripSuggestions` 会优先由已保存路线点、可复盘照片、提醒历史和本次确认记忆派生，只有缺少真实上下文时才使用降级建议。前端应保存 `reviewId` 用于调试与交接追踪，但展示仍以 `review` 内容为主。

### `GET /api/trip/reminders/history`

### `GET /api/trip/dashboard`

Aggregates one trip for mobile real-data screens. The backend only returns a trip when the requested `tripId` belongs to the same `userId`; otherwise `currentTrip.status=empty` is returned to avoid cross-user data exposure.

Query: `userId`, optional `tripId`.

Response groups existing persisted data without creating new records: `currentTrip`, `routePoints`, `reminderHistory`, `blindBoxTasks`, `avatarStateEvents`, `latestReview`, `photoCandidates`, and `memories`. Flutter can use this as the single read endpoint for home/planning/reminder/review state while device permissions and real provider keys are still configured separately.

Flutter client entry: `TripDashboardService.fetchDashboard(userId, tripId?)` maps this response and returns an empty offline payload on network failure.

### `GET /api/trip/reminders/history`

按 `userId` 和可选 `tripId` 读取主动提醒触发历史。

```json
{
  "items": [
    {
      "historyId": "reminder-...",
      "userId": "guest",
      "tripId": "trip-1",
      "triggerType": "status",
      "location": "解放碑",
      "eventPayload": {"energy": 28},
      "items": [],
      "createdAt": "2026-06-19T..."
    }
  ]
}
```

### `POST /api/trip/reminders/evaluate`

根据端侧上报的时间、位置、状态和外部事件自动评估是否触发主动提醒；命中后写入 `reminder_events`，重复调用会按冷却时间抑制。`proactivityLevel` 支持 `quiet`、`standard`、`active`，其中 `quiet` 只保留低精力等高价值提醒。

请求：

```json
{
  "userId": "guest",
  "tripId": "trip-1",
  "proactivityLevel": "standard",
  "currentTime": "2026-06-20T18:20:00+08:00",
  "location": "Hongyadong",
  "status": {"energy": 31},
  "external": {"weatherWarning": "rain", "queueLevel": "high"}
}
```

响应：

```json
{
  "triggered": true,
  "historyId": "reminder-...",
  "items": [],
  "suppressedReason": null,
  "cooldownRemainingSeconds": 0
}
```
### `POST /api/trip/reminders/trigger`

触发提醒后会写入 `reminder_events`，响应包含 `historyId` 与本次提醒 `items`。当前接口可由端侧真实时间/位置/状态触发，也可作为调试入口调用；调试入口不能作为最终真实触发验收。

### `POST /api/tools/{tool_name}/call`

统一工具调用接口。调用已注册工具后写入 `tool_call_logs`，响应包含 `toolTraceId`、`toolName`、`userId` 和工具 `result`。真实高德 Key 未配置时，`result.provider=unconfigured` 且 `fallback=true`。

### `GET /api/audit/tool-calls`

读取工具调用审计日志，支持 `toolName`、`provider`、`fallback` 和 `limit` 筛选。响应字段包含 `toolTraceId`、`toolName`、`provider`、`mock`、`fallback` 和 `createdAt`，用于排查真实工具配置、降级和演示链路。

### `GET /api/audit/model-calls`

读取模型调用审计日志，支持 `provider`、`scenario`、`fallback` 和 `limit` 筛选。响应字段包含 `modelTraceId`、`provider`、`scenario`、`fallback`、`elapsedMs`、`error`、`requestSummary` 和 `createdAt`；`requestSummary` 使用后端脱敏规则，不返回用户原文、密钥或 Token。

```json
{
  "userId": "guest",
  "payload": {"city": "杭州"}
}
```

```json
{
  "toolTraceId": "tool-...",
  "toolName": "weather_tool",
  "userId": "guest",
  "result": {
    "provider": "unconfigured",
    "fallback": true
  }
}
```
## 多人出游协调接口

### `POST /api/trip/group/coordinate`

接收至少 2 名成员的真实偏好，生成冲突识别、折中方案和隐私汇总，并写入 `group_coordination_records`。`sensitivePreferences` 只用于生成汇总标记，不会在对外响应中返回原文。

```json
{
  "userId": "organizer-a",
  "tripId": "trip-1",
  "destination": "重庆",
  "members": [
    {
      "memberId": "member-a",
      "displayName": "小林",
      "preferences": {
        "pace": "slow",
        "dietary": ["不吃香菜"],
        "interests": ["夜景"],
        "budget": "medium"
      },
      "sensitivePreferences": {"health": "不适合久走"}
    },
    {
      "memberId": "member-b",
      "displayName": "阿远",
      "preferences": {
        "pace": "packed",
        "dietary": ["想吃火锅"],
        "interests": ["夜景", "山城步道"],
        "budget": "low"
      }
    }
  ]
}
```

响应：

```json
{
  "coordinationId": "group-...",
  "tripId": "trip-1",
  "members": [
    {"memberId": "member-a", "displayName": "小林", "hasSensitivePreferences": true}
  ],
  "conflicts": [
    {"type": "pace", "title": "节奏偏好不一致"}
  ],
  "compromisePlan": {
    "pace": "balanced_slow",
    "budget": "low_first",
    "sharedInterests": ["夜景"]
  },
  "privacySummary": {
    "sensitiveMemberDetailsHidden": true,
    "sensitiveMemberCount": 1
  }
}
```

### `GET /api/trip/group/coordination`

按 `tripId` 读取最近一次多人协调结果。无结果时返回空成员、空冲突和空折中方案。


## 模型 Provider 输出契约

真实模型必须返回带根字段的结构化 JSON，后端按场景校验后才进入主链路：

| scenario | 根字段 | schema | 失败处理 |
| --- | --- | --- | --- |
| `memory_extraction` | `memoryExtraction` | `MemoryExtractionOutput` | 回退本地隐私规则记忆抽取，`toolTrace.errorType=schema_validation` 或 `provider_error` |
| `trip_planning` | `tripPlanning` | `TripPlanningOutput` | 回退 `MockModelProvider.plan_trip`，保留 `model_provider` trace |
| `photo_copywriting` | `photoCopywriting` | `PhotoCopywritingOutput` | `/api/photo/copywriting` 返回确定性文案并附带 `provider/fallback/errorType/fallbackReason` |
| `trip_review` | `tripReview` | `TripReviewOutput` | 回退真实持久化上下文聚合复盘 |
| `companion_chat` | `chat` | `ChatOutput` | 回退本地响应组合器 |

`/api/agent/chat` 的 `toolTrace` 会包含模型调用 trace，例如：

```json
{
  "tool": "model_provider",
  "provider": "lanxin",
  "scenario": "companion_chat",
  "fallback": false
}
```

schema 无效或 Provider 未配置时，`fallback=true`，并带 `errorType` 与脱敏错误摘要。真实验收时必须同时检查业务字段、`toolTrace` 和 `GET /api/audit/model-calls`，确认没有把 Mock 或 unconfigured 降级当作真实模型结果。
