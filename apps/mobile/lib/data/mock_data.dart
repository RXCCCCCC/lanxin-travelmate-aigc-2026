import '../core/constants/avatar_states.dart';
import '../shared/models/travelmate_models.dart';

/// ============================================================
/// Mock 数据
/// 为各页面提供演示用的模拟数据，便于快速开发和预览。
/// ============================================================

// ── 聊天消息 ──────────────────────────────────────────────────

final List<ChatMessage> mockChatMessages = [
  const ChatMessage(
    id: '1',
    sender: MessageSender.assistant,
    text: '你好呀！我是蓝小心，你的专属AI旅游搭子~ 今天想去哪里玩呢？',
    time: '09:00',
    avatarState: AvatarState.hello,
  ),
  const ChatMessage(
    id: '2',
    sender: MessageSender.user,
    text: '我想去杭州玩两天，有什么推荐的吗？',
    time: '09:01',
  ),
  const ChatMessage(
    id: '3',
    sender: MessageSender.assistant,
    text: '杭州太棒了！根据你的偏好，我为你规划了一条结合自然风光和美食的路线。第一天游西湖，第二天去灵隐寺和龙井村。',
    time: '09:02',
    avatarState: AvatarState.planning,
  ),
  const ChatMessage(
    id: '4',
    sender: MessageSender.user,
    text: '听起来不错，我想看看具体的行程安排',
    time: '09:03',
  ),
  const ChatMessage(
    id: '5',
    sender: MessageSender.assistant,
    text: '好的！我已经为你生成了详细的行程规划，包含时间、地点和推荐理由。你可以点击下方的"查看行程"查看完整安排哦~',
    time: '09:04',
    avatarState: AvatarState.excited,
  ),
];

// ── 记忆胶囊 ──────────────────────────────────────────────────

final List<MemoryCapsule> mockMemoryCapsules = [
  const MemoryCapsule(
    id: '1',
    title: '喜欢海鲜',
    content: '用户提到非常喜欢吃海鲜，特别是清蒸鲈鱼和白灼虾。',
    scope: MemoryScope.longTerm,
    createdAt: '2026-06-01',
    tags: ['饮食', '海鲜'],
  ),
  const MemoryCapsule(
    id: '2',
    title: '不爱早起',
    content: '旅行中不喜欢太早出发，9点以后比较合适。',
    scope: MemoryScope.longTerm,
    createdAt: '2026-06-05',
    tags: ['作息', '节奏'],
  ),
  MemoryCapsule(
    id: '3',
    title: '杭州行程偏好',
    content: '本次杭州之行偏好自然风光和美食，对商业街兴趣不大。',
    scope: MemoryScope.currentTrip,
    createdAt: '2026-06-10',
    tags: const ['杭州', '自然', '美食'],
    isNew: true,
  ),
  const MemoryCapsule(
    id: '4',
    title: '拍照风格',
    content: '喜欢自然风格的照片，不太喜欢摆拍。',
    scope: MemoryScope.longTerm,
    createdAt: '2026-06-08',
    tags: ['拍照', '风格'],
  ),
  const MemoryCapsule(
    id: '5',
    title: '今天心情不错',
    content: '今天到达杭州天气很好，心情很棒。',
    scope: MemoryScope.temporary,
    createdAt: '2026-06-11',
    tags: ['心情'],
  ),
];

// ── 用户画像 ──────────────────────────────────────────────────

const mockUserProfile = UserProfile(
  name: '旅行者小明',
  avatarUrl: '',
  dietaryPreferences: ['海鲜', '清淡', '避免辛辣'],
  travelPace: '舒适型 - 每天2-3个景点',
  transportPreference: '公共交通 + 打车',
  budgetLevel: '中等 - 每日500-800元',
  interestTags: ['自然风光', '美食探店', '历史文化', '摄影', '咖啡'],
);

// ── 出行规划 ──────────────────────────────────────────────────

const mockTripPlan = TripPlan(
  title: '杭州两日深度游',
  dateRange: '6月11日 - 6月12日',
  destination: '杭州',
  days: [
    TripDay(
      dayLabel: '第一天 - 西湖漫步',
      items: [
        TripItem(
          time: '09:30',
          location: '断桥残雪',
          activity: '晨间漫步西湖，从断桥出发沿白堤前行',
          reason: '你偏好自然风光，清晨的西湖人少景美',
          isCurrent: true,
        ),
        TripItem(
          time: '11:00',
          location: '楼外楼',
          activity: '品尝正宗杭帮菜',
          reason: '你喜欢清淡口味，楼外楼的西湖醋鱼和龙井虾仁值得一试',
        ),
        TripItem(
          time: '14:00',
          location: '雷峰塔',
          activity: '登塔俯瞰西湖全景',
          reason: '历史文化的绝佳体验点，适合拍照留念',
        ),
        TripItem(
          time: '16:30',
          location: '南山路',
          activity: '咖啡街漫步，找一家临湖咖啡馆休息',
          reason: '你对咖啡感兴趣，南山路有很多特色咖啡馆',
        ),
      ],
    ),
    TripDay(
      dayLabel: '第二天 - 灵隐禅意',
      items: [
        TripItem(
          time: '09:30',
          location: '灵隐寺',
          activity: '游览千年古刹，感受禅意氛围',
          reason: '历史文化景点，环境清幽适合慢节奏',
        ),
        TripItem(
          time: '12:00',
          location: '龙井村',
          activity: '品龙井茶，体验茶园风光',
          reason: '自然风光+美食，龙井虾仁的原料产地',
        ),
        TripItem(
          time: '14:30',
          location: '九溪烟树',
          activity: '漫步九溪十八涧',
          reason: '人少清幽的自然步道，符合你对自然风光的偏好',
        ),
        TripItem(
          time: '17:00',
          location: '河坊街',
          activity: '逛老街，购买伴手礼',
          reason: '综合体验区，有各种杭州特产和小吃',
        ),
      ],
    ),
  ],
  risks: ['6月12日下午可能有阵雨，建议携带雨具', '灵隐寺周末人流量大，建议早到', '龙井村山路较多，建议穿舒适运动鞋'],
);

// ── 主动提醒 ──────────────────────────────────────────────────

final List<Reminder> mockReminders = [
  const Reminder(
    id: '1',
    title: '该出发啦',
    description: '距离下一个行程"断桥残雪漫步"还有30分钟，建议现在出发~',
    triggerReason: '时间触发：行程倒计时30分钟',
    actionLabel: '开始导航',
    iconName: 'directions_walk',
  ),
  const Reminder(
    id: '2',
    title: '别忘了带伞',
    description: '下午2点后杭州有60%降雨概率，记得带上雨具哦~',
    triggerReason: '天气触发：降雨概率>50%',
    actionLabel: '知道了',
    iconName: 'umbrella',
  ),
  const Reminder(
    id: '3',
    title: '拍照好时机',
    description: '当前位置光线很好，适合在雷峰塔前拍一张逆光照片~',
    triggerReason: '位置触发：到达雷峰塔 + 光线条件好',
    actionLabel: '打开相机',
    iconName: 'camera_alt',
  ),
];

// ── 旅拍候选 ──────────────────────────────────────────────────

final List<PhotoCandidate> mockPhotoCandidates = [
  const PhotoCandidate(
    id: '1',
    location: '断桥残雪',
    score: 9.2,
    description: '清晨逆光剪影，断桥与远山层次分明',
  ),
  const PhotoCandidate(
    id: '2',
    location: '雷峰塔',
    score: 8.8,
    description: '夕阳下的雷峰塔倒影，金色光芒映照湖面',
  ),
  const PhotoCandidate(
    id: '3',
    location: '龙井茶园',
    score: 8.5,
    description: '翠绿茶园中的自然漫步抓拍',
  ),
  const PhotoCandidate(
    id: '4',
    location: '九溪烟树',
    score: 9.0,
    description: '溪水潺潺，光影斑驳的林间小径',
  ),
  const PhotoCandidate(
    id: '5',
    location: '南山路咖啡馆',
    score: 7.8,
    description: '临窗品味咖啡的文艺瞬间',
  ),
  const PhotoCandidate(
    id: '6',
    location: '灵隐寺',
    score: 8.3,
    description: '古刹黄墙前的禅意留影',
  ),
];

// ── 旅行复盘 ──────────────────────────────────────────────────

const mockTripReview = TripReview(
  title: '杭州两日深度游',
  dateRange: '2026年6月11日 - 6月12日',
  route: '断桥残雪 → 楼外楼 → 雷峰塔 → 南山路 → 灵隐寺 → 龙井村 → 九溪烟树',
  highlightPhotoCount: 12,
  newMemoryCount: 5,
  highlightPhotos: ['断桥晨曦剪影', '雷峰塔夕阳倒影', '龙井茶园漫步', '九溪林间小径'],
  newMemories: [
    '你特别喜欢清晨的西湖，说"人少的时候最有味道"',
    '在龙井村你学会了区分明前龙井和雨前龙井',
    '你在九溪烟树待了比计划多一倍的时间，说这是"意外的惊喜"',
    '南山路的%Arabica咖啡被评为本次旅行最佳咖啡',
  ],
  nextTripSuggestions: [
    '乌镇水乡 - 古镇慢生活，适合你的舒适节奏',
    '莫干山 - 清幽山居+咖啡文化，延续自然+咖啡路线',
    '西塘古镇 - 小桥流水，适合你喜欢的自然风光',
  ],
);
