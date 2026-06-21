# 隐私与合规说明

## 当前已落地

- 后端提供 `GET /api/privacy/summary`，返回权限用途、记忆保存范围、隐私分级和用户控制能力。
- Agent 记忆候选包含 `sensitivity` 和 `requiresExplicitConsent` 字段。
- 饮食忌口等个人偏好标记为 `personal`，可建议长期保存，但必须由用户确认。
- 身体状态、位置上下文、同行人信息标记为 `sensitive`，默认只建议本次旅行、当前会话或不记忆。
- 已有接口支持导出记忆、清空全部记忆、清空本次旅行。

- Flutter `PhotoExperienceService.createUploadMetadata()` 不向后端发送设备本地 `localPath`；后端照片候选和上传元数据响应固定返回 `localUri/localPath=null`。
- `services/api/tests/test_mobile_privacy_boundaries.py` 静态检查移动端运行时代码不得使用 `print/debugPrint/developer.log/console.log` 输出潜在照片、音频、路径或 Token。

## 端侧展示要求

- 多人协调结果只能展示 `privacySummary.publicRule`、`sensitiveMemberDetailsHidden` 和 `sensitiveMemberCount` 等汇总信息，不得展示成员 `sensitivePreferences` 原文。

- 聊天页记忆候选必须读取 `sensitivity/requiresExplicitConsent`，当候选包含 `personal` 或 `sensitive` 时展示显式确认提示，再允许保存。

- 所有记忆候选保存前必须展示保存范围：长期记忆、本次旅行、当前会话、不记忆。
- `sensitivity=personal` 需要明确提示“会影响后续个性化推荐”。
- `sensitivity=sensitive` 需要独立提示，不得默认勾选长期记忆。
- 用户拒绝定位、相册、相机、麦克风、通知权限时，必须提供文字输入、手动地点或应用内展示等降级路径。

## 仍需人工确认

- 比赛公开演示前的隐私政策最终措辞。
- 权限弹窗文案与 Android 权限声明。
- Demo 数据、照片和素材授权。