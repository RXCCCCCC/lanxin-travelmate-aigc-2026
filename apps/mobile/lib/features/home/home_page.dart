import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/avatar_states.dart';
import '../../shared/widgets/glass_box.dart';

/// 首页 — 完全复刻参考图
/// 上方 65%：天空渐变背景 + 蓝小心立绘浮动 + 浮动状态卡 + 品牌/天气/旅行胶囊
/// 下方 35%：磨砂玻璃聊天面板 + 输入栏 + 快捷指令
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late final AnimationController _floatCtrl;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: LayoutBuilder(
          builder: (context, c) {
            final h = c.maxHeight;
            final topSafe = MediaQuery.of(context).padding.top;

            return Stack(
              children: [
                // ── 天空渐变背景 ──
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF5FA4FF), Color(0xFF89C2FF),
                          Color(0xFFB8DEFF), Color(0xFFDCEEFF), Color(0xFFE8F7FF),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.0, 0.2, 0.45, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),

                // ── 品牌标题（左上）──
                Positioned(
                  top: topSafe + 8,
                  left: 22,
                  child: const _BrandBlock(),
                ),

                // ── 演示模式 + 消息（右上）──
                Positioned(
                  top: topSafe + 8,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      _DemoButton(),
                      SizedBox(height: 8),
                      _NoticePill(),
                    ],
                  ),
                ),

                // ── 旅行胶囊 ──
                Positioned(
                  top: topSafe + 82,
                  left: 22,
                  child: const _TripPill(),
                ),

                // ── 天气卡片 ──
                Positioned(
                  top: topSafe + 120,
                  left: 22,
                  child: const _WeatherCard(),
                ),

                // ── 蓝小心立绘（中央浮动，占 ~58% 高度）──
                AnimatedBuilder(
                  animation: _floatCtrl,
                  builder: (context, child) {
                    final t = math.sin(_floatCtrl.value * math.pi * 2);
                    return Positioned(
                      top: h * 0.08 + t * 6,
                      left: -8,
                      right: -8,
                      height: h * 0.58,
                      child: child!,
                    );
                  },
                  child: IgnorePointer(
                    child: Image.asset(
                      AvatarState.hello.assetPath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.person, size: 120, color: Color(0xFF4C8DFF)),
                      ),
                    ),
                  ),
                ),

                // ── 右侧浮动状态卡 ──
                Positioned(top: h * 0.24, right: 16, child: const _AffinityCard()),
                Positioned(top: h * 0.34, right: 16, child: const _MoodEnergyCard()),
                Positioned(top: h * 0.42, right: 20, child: const _PlanningBadge()),
                Positioned(top: h * 0.48, right: 16, child: const _MemoryCapsuleBadge()),

                // ── 底部磨砂玻璃聊天面板（~37%）──
                Positioned(
                  left: 12, right: 12, bottom: 10, height: h * 0.37,
                  child: const _ChatGlassPanel(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// 子组件
// ══════════════════════════════════════════════════════════

class _BrandBlock extends StatelessWidget {
  const _BrandBlock();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (r) => const LinearGradient(
              colors: [Color(0xFF215ECA), Color(0xFF6F9BFF)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ).createShader(r),
            child: const Text('lanxiaoxin', style: TextStyle(
              color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900,
              height: 0.92, letterSpacing: -1.0,
            )),
          ),
          const SizedBox(height: 4),
          Text('AI Travel Companion', style: TextStyle(
            color: const Color(0xFF275DBF).withOpacity(0.75),
            fontSize: 12.5, fontWeight: FontWeight.w700, letterSpacing: 0.3,
          )),
        ],
      ),
    );
  }
}

class _TripPill extends StatelessWidget {
  const _TripPill();
  @override
  Widget build(BuildContext context) {
    return GlassBox(
      borderRadius: BorderRadius.circular(22),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.location_on_rounded, color: Color(0xFF5F9BFF), size: 19),
        SizedBox(width: 7),
        Text('重庆周末游', style: TextStyle(color: Color(0xFF2B5BA9), fontWeight: FontWeight.w800, fontSize: 13.5)),
        SizedBox(width: 5),
        Icon(Icons.chevron_right_rounded, color: Color(0xFF326BCA), size: 19),
      ]),
    );
  }
}

class _WeatherCard extends StatelessWidget {
  const _WeatherCard();
  @override
  Widget build(BuildContext context) {
    return GlassBox(
      width: 132,
      padding: const EdgeInsets.fromLTRB(13, 11, 12, 11),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.cloud_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 7),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: ShaderMask(shaderCallback: (r) => const LinearGradient(
                colors: [Color(0xFF4A83FF), Color(0xFFA7CBFF)],
              ).createShader(r), child: const Text('24°C 多云',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14.5))),
            ),
          ),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFDF73), size: 14),
          const SizedBox(width: 5),
          Text('适合夜景', style: TextStyle(
            color: const Color(0xFF2F64BF).withOpacity(0.70),
            fontWeight: FontWeight.w800, fontSize: 11.5)),
        ]),
      ]),
    );
  }
}

class _DemoButton extends StatelessWidget {
  const _DemoButton();
  @override
  Widget build(BuildContext context) {
    return GlassBox(
      borderRadius: BorderRadius.circular(25),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
        SizedBox(width: 7),
        Text('演示模式', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
        SizedBox(width: 4),
        Icon(Icons.play_arrow_rounded, color: Colors.white, size: 17),
      ]),
    );
  }
}

class _NoticePill extends StatelessWidget {
  const _NoticePill();
  @override
  Widget build(BuildContext context) {
    return GlassBox(
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.notifications_none_rounded, color: Colors.white, size: 17),
        SizedBox(width: 6),
        Text('消息', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12.5)),
      ]),
    );
  }
}

class _AffinityCard extends StatelessWidget {
  const _AffinityCard();
  @override
  Widget build(BuildContext context) {
    return GlassBox(
      width: 126,
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [
          Icon(Icons.favorite_rounded, color: Color(0xFFFF8CCF), size: 18),
          SizedBox(width: 7),
          Text('默契值', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          const Text('12', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)),
          const Spacer(),
          Icon(Icons.sync_rounded, color: Colors.white.withOpacity(0.40), size: 17),
        ]),
        const SizedBox(height: 6),
        ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(
          minHeight: 4.5, value: 0.42,
          backgroundColor: Colors.white.withOpacity(0.20),
          color: const Color(0xFF6F98FF),
        )),
      ]),
    );
  }
}

class _MoodEnergyCard extends StatelessWidget {
  const _MoodEnergyCard();
  @override
  Widget build(BuildContext context) {
    final ls = TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12.5, fontWeight: FontWeight.w700);
    const vs = TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900);

    return GlassBox(
      width: 126,
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
      child: Column(children: [
        Row(children: [
          const Icon(Icons.mood_rounded, color: Color(0xFFFFDA7D), size: 17),
          const SizedBox(width: 6), Text('心情', style: ls), const Spacer(), const Text('开心', style: vs),
        ]),
        const SizedBox(height: 9),
        Divider(height: 1, color: Colors.white.withOpacity(0.22)),
        const SizedBox(height: 9),
        Row(children: [
          const Icon(Icons.bolt_rounded, color: Color(0xFFFFD953), size: 17),
          const SizedBox(width: 6), Text('精力', style: ls), const Spacer(), const Text('90', style: vs),
        ]),
      ]),
    );
  }
}

class _PlanningBadge extends StatelessWidget {
  const _PlanningBadge();
  @override
  Widget build(BuildContext context) {
    return GlassBox(
      borderRadius: BorderRadius.circular(18),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('正在帮你规划', style: TextStyle(
          color: Colors.white.withOpacity(0.90), fontWeight: FontWeight.w900, fontSize: 11.5)),
        const SizedBox(width: 6),
        const Icon(Icons.graphic_eq_rounded, color: Color(0xFFA6D9FF), size: 15),
      ]),
    );
  }
}

class _MemoryCapsuleBadge extends StatelessWidget {
  const _MemoryCapsuleBadge();
  @override
  Widget build(BuildContext context) {
    return GlassBox(
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      showGlow: true, glowColor: const Color(0xFF4A9FFF),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(
            colors: [Color(0xFF6FB3FF), Color(0xFF4A8DFF)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ), boxShadow: [BoxShadow(color: const Color(0xFF4A8DFF).withOpacity(0.4), blurRadius: 10)]),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 15),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          const Text('发现了新的旅行偏好', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
          Text('点击查看 ›', style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 10.5)),
        ]),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════
// 底部磨砂玻璃聊天面板
// ══════════════════════════════════════════════════════════

class _ChatGlassPanel extends StatelessWidget {
  const _ChatGlassPanel();
  @override
  Widget build(BuildContext context) {
    return GlassBox(
      borderRadius: BorderRadius.circular(32),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      opacity: 0.18, blur: 30.0,
      child: Column(children: [
        Expanded(child: ListView(padding: EdgeInsets.zero, children: [
          _ChatBubble(isUser: false, text: '嗨嗨！我想去哪儿玩呢？我来帮你规划吧！', avatarPath: AvatarState.hello.assetPath),
          const SizedBox(height: 8),
          _ChatBubble(isUser: true, text: '周末想去重庆两天，不想太累，喜欢夜景，我不吃香菜。'),
          const SizedBox(height: 8),
          _ChatBubble(isUser: false, text: '收到！我先帮你抓几个会影响旅行体验的小偏好，保存前会让你自己决定哦～', avatarPath: AvatarState.hello.assetPath),
        ])),
        // 输入栏
        GlassBox(
          borderRadius: BorderRadius.circular(24),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          opacity: 0.10, blur: 16,
          child: Row(children: const [
            Icon(Icons.mic_rounded, color: Color(0xFF5F8FBF), size: 22),
            SizedBox(width: 8),
            Expanded(child: Text('说点什么吧...', style: TextStyle(color: Color(0xFF8FABC4), fontSize: 14))),
            Icon(Icons.emoji_emotions_outlined, color: Color(0xFF5F8FBF), size: 21),
            SizedBox(width: 10),
            Icon(Icons.photo_library_outlined, color: Color(0xFF5F8FBF), size: 21),
            SizedBox(width: 10),
            Icon(Icons.add_circle_outline, color: Color(0xFF5F8FBF), size: 22),
          ]),
        ),
        const SizedBox(height: 6),
        // 快捷指令
        Row(children: const [
          _QuickChip(icon: Icons.route_rounded, label: '规划路线'),
          SizedBox(width: 6),
          _QuickChip(icon: Icons.bubble_chart_rounded, label: '记忆胶囊'),
          SizedBox(width: 6),
          _QuickChip(icon: Icons.edit_road_rounded, label: '调整行程'),
          SizedBox(width: 6),
          _QuickChip(icon: Icons.auto_stories_rounded, label: '生成复盘'),
        ]),
      ]),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.isUser, required this.text, this.avatarPath});
  final bool isUser;
  final String text;
  final String? avatarPath;

  @override
  Widget build(BuildContext context) {
    if (isUser) {
      return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        const Spacer(),
        Container(
          constraints: const BoxConstraints(maxWidth: 240),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              const Color(0xFF4C8DFF).withOpacity(0.75),
              const Color(0xFF6FA8FF).withOpacity(0.65),
            ]),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18), topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18), bottomRight: Radius.circular(4)),
            border: Border.all(color: Colors.white.withOpacity(0.30), width: 0.8),
          ),
          child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.4)),
        ),
      ]);
    }

    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.5), width: 1)),
        child: ClipOval(child: avatarPath != null
            ? Image.asset(avatarPath!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.smart_toy, size: 18, color: Color(0xFF4C8DFF)))
            : const Icon(Icons.smart_toy, size: 18, color: Color(0xFF4C8DFF))),
      ),
      const SizedBox(width: 8),
      Container(
        constraints: const BoxConstraints(maxWidth: 240),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.white.withOpacity(0.35), Colors.white.withOpacity(0.22)]),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18), topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4), bottomRight: Radius.circular(18)),
          border: Border.all(color: Colors.white.withOpacity(0.45), width: 0.8),
        ),
        child: Text(text, style: const TextStyle(color: Color(0xFF06224E), fontSize: 13.5, height: 1.4)),
      ),
      const Spacer(),
    ]);
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.white.withOpacity(0.22), Colors.white.withOpacity(0.12)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.35), width: 0.8),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 13, color: const Color(0xFF4A7FCC)),
          const SizedBox(width: 3),
          Text(label, style: const TextStyle(color: Color(0xFF2B5BA9), fontSize: 11, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}
