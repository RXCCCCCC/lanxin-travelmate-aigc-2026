export type DemoStep = {
  id: string;
  nav: string;
  eyebrow: string;
  title: string;
  subtitle: string;
  image: string;
  mood: string;
  energy: string;
  trust: string;
  speech: string;
  tags: string[];
  cards: Array<{
    title: string;
    meta: string;
    text: string;
  }>;
  actions: string[];
  showcase: {
    headline: string;
    insight: string;
    model: string;
    ppt: string;
  };
};

export const demoSteps: DemoStep[] = [
  {
    id: 'home',
    nav: '同行',
    eyebrow: 'Lanxin TravelMate',
    title: '嗨，我叫蓝小心',
    subtitle: '会记住你、主动陪你玩、帮你沉淀旅行回忆的AI旅行搭子。',
    image: '/img/lanxiaoxin_hello.png',
    mood: '开心',
    energy: '90',
    trust: '12',
    speech: '告诉我这次想怎么玩，我会先问清楚，再决定哪些偏好值得放进记忆胶囊。',
    tags: ['重庆 · 出行前', '蓝白清爽系', '具身化Agent'],
    cards: [
      { title: '今日建议', meta: '试试这样说', text: '周末想去重庆两天，不想太累，喜欢夜景，我不吃香菜。' },
      { title: '演示闭环', meta: 'P0 Demo', text: '需求输入 → 初步规划 → 记忆胶囊 → 主动提醒 → 旅行复盘。' },
    ],
    actions: ['创建旅行', '查看记忆', '开始Demo'],
    showcase: {
      headline: '第一眼建立“AI旅行搭子”心智',
      insight: '首页要让评委快速理解：蓝小心不是工具按钮，而是贯穿全旅程的具身化伙伴。',
      model: '角色化对话、用户意图理解、旅行上下文初始化。',
      ppt: '适合放在作品简介页或产品原型设计页，作为核心视觉入口。',
    },
  },
  {
    id: 'brief',
    nav: '需求',
    eyebrow: 'Trip Brief',
    title: '先说你想怎么玩',
    subtitle: '用户先提出旅行目标，蓝小心再理解偏好并给出初步方向。',
    image: '/img/lanxiaoxin_planning.png',
    mood: '认真',
    energy: '88',
    trust: '13',
    speech: '收到！我先按“重庆两天、轻松、夜景、不吃香菜”做一版路线，再问你哪些偏好要不要长期记住。',
    tags: ['自然语言输入', '意图理解', '旅行约束'],
    cards: [
      { title: '用户输入', meta: '一句话创建旅行', text: '周末想去重庆两天，不想太累，喜欢夜景，我不吃香菜。' },
      { title: '初步判断', meta: '蓝心大模型理解', text: '目的地、时间、节奏偏好、兴趣点和饮食忌口被拆解成规划条件。' },
    ],
    actions: ['生成路线', '补充预算', '添加同行人'],
    showcase: {
      headline: '先有需求，再产生记忆与规划',
      insight: '这一页解决流程逻辑：用户表达本次旅行目标，Agent 才能识别偏好和上下文。',
      model: '自然语言意图识别、槽位抽取、旅行约束结构化。',
      ppt: '适合放在产品原型设计页，作为核心交互流程第一步。',
    },
  },
  {
    id: 'memory',
    nav: '记忆',
    eyebrow: 'Memory Capsule',
    title: '保存前，先问你',
    subtitle: '蓝小心识别偏好，但是否长期记住由用户决定。',
    image: '/img/lanxiaoxin_thinking.png',
    mood: '思考',
    energy: '86',
    trust: '14',
    speech: '我理解到3个可能影响旅行体验的偏好，你可以决定哪些让我长期记住，哪些只用于这次旅行。',
    tags: ['不偷偷记', '长期/本次/临时', '隐私可控'],
    cards: [
      { title: '不吃香菜', meta: '建议长期记忆', text: '以后推荐餐厅时自动避开香菜，点餐备注也会优先提醒。' },
      { title: '喜欢夜景', meta: '建议长期记忆', text: '规划时优先安排傍晚和夜景路线，保留拍照时间。' },
      { title: '这次不想太累', meta: '本次旅行记忆', text: '本次重庆行程减少跨区移动和高强度步行。' },
    ],
    actions: ['确认保存', '编辑胶囊', '不记住'],
    showcase: {
      headline: '记忆胶囊是差异化核心',
      insight: '把“AI知道我”变成可控机制，避免用户担心被偷偷记住。',
      model: '偏好抽取、记忆分类、隐私边界提示。',
      ppt: '适合放在创新点说明页，突出长期记忆与隐私可控。',
    },
  },
  {
    id: 'plan',
    nav: '规划',
    eyebrow: 'Personal Plan',
    title: '重庆两日轻松夜景路线',
    subtitle: '不是通用攻略，而是会解释“为什么适合你”的规划。',
    image: '/img/lanxiaoxin_planning.png',
    mood: '认真',
    energy: '84',
    trust: '17',
    speech: '我把洪崖洞安排在晚上，因为你喜欢夜景；今天减少跨区移动，因为你这次想轻松。',
    tags: ['夜景优先', '少跨区', '避开香菜'],
    cards: [
      { title: 'Day1 下午 · 解放碑轻量步行', meta: '低强度开场', text: '到达后先适应城市节奏，不急着赶路。' },
      { title: 'Day1 傍晚 · 洪崖洞夜景', meta: '匹配喜欢夜景', text: '把最佳夜景时间留给你最在意的体验。' },
      { title: 'Day2 下午 · 观景休息点', meta: '匹配不想太累', text: '保留休息时间，减少连续步行。' },
    ],
    actions: ['保存行程', '更省钱', '增加拍照点'],
    showcase: {
      headline: '规划要解释“为什么适合我”',
      insight: '让推荐从通用攻略变成有画像依据的个性化路线。',
      model: '多约束规划推理、推荐理由生成、路线方案组织。',
      ppt: '适合放在产品原型设计页，展示核心功能卖点。',
    },
  },
  {
    id: 'alert',
    nav: '提醒',
    eyebrow: 'Active Companion',
    title: '排队可能影响夜景时间',
    subtitle: '蓝小心根据排队和行程节点主动参与决策。',
    image: '/img/lanxiaoxin_warning.png',
    mood: '担心',
    energy: '65',
    trust: '20',
    speech: '这里排队可能会影响晚上看夜景。要不要先去附近的轻量景点？我帮你重新排一下路线。',
    tags: ['主动触发', '路线调整', '不打扰'],
    cards: [
      { title: '风险判断', meta: '当前排队约60分钟', text: '可能错过18:30前到达洪崖洞的最佳夜景窗口。' },
      { title: '方案A · 先去轻量景点', meta: '推荐', text: '保留夜景重点，减少等待。' },
      { title: '方案B · 找附近休息点', meta: '慢节奏', text: '匹配“这次不想太累”的本次记忆。' },
    ],
    actions: ['采用方案A', '先休息', '继续原计划'],
    showcase: {
      headline: '主动陪伴体现真实旅途价值',
      insight: '旅行中很多关键时刻不是用户主动问，而是需要 AI 在合适时机提醒。',
      model: '情境判断、风险提示、动态路线重排。',
      ppt: '适合放在创新点说明页，展示主动情境陪伴。',
    },
  },
  {
    id: 'recap',
    nav: '复盘',
    eyebrow: 'Travel Recap',
    title: '这次旅行，让我更懂你',
    subtitle: '旅行结束不是服务结束，而是下一次更懂你的开始。',
    image: '/img/lanxiaoxin_happy.png',
    mood: '开心',
    energy: '82',
    trust: '20',
    speech: '我记住啦：你喜欢慢节奏夜景路线，也不吃香菜。下次旅行我会更懂你。',
    tags: ['新增记忆', '默契值 12→20', '好感度 35→45'],
    cards: [
      { title: '今日路线', meta: '高光回顾', text: '解放碑 → 洪崖洞夜景 → 山城步道 → 观景休息点。' },
      { title: '新增长期记忆', meta: '下次继续使用', text: '喜欢慢节奏夜景路线；餐饮默认避开香菜。' },
      { title: '下次建议', meta: '越旅行越懂你', text: '下次会优先推荐慢节奏路线、夜景点和可备注忌口的餐厅。' },
    ],
    actions: ['保存复盘卡', '生成朋友圈', '计划下一次'],
    showcase: {
      headline: '用复盘完成全旅程闭环',
      insight: '复盘不是总结页，而是把本次体验沉淀为下一次更懂用户的起点。',
      model: '旅行摘要、记忆沉淀、分享文案生成。',
      ppt: '适合放在前景评估或 Demo 闭环页，展示长期价值。',
    },
  },
];
