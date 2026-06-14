import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const LanXinApp());
}

class LanXinApp extends StatelessWidget {
  const LanXinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '蓝心同行',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: 'sans',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4C8DFF)),
      ),
      home: const LanXinChatPage(),
    );
  }
}

class LanXinChatPage extends StatefulWidget {
  const LanXinChatPage({super.key});

  @override
  State<LanXinChatPage> createState() => _LanXinChatPageState();
}

class _LanXinChatPageState extends State<LanXinChatPage>
    with SingleTickerProviderStateMixin {
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
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFFDCEEFF),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFD7ECFF),
        body: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final h = c.maxHeight;
            final chatHeight = h * 0.43;
            final topSafe = MediaQuery.of(context).padding.top;

            return Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: SkyTravelPainter())),

                Positioned(
                  top: topSafe + 2,
                  left: 22,
                  right: 22,
                  child: const MockStatusBar(),
                ),

                Positioned(
                  top: topSafe + 64,
                  left: 24,
                  child: const BrandBlock(),
                ),

                Positioned(
                  top: topSafe + 70,
                  right: 22,
                  child: const DemoButton(),
                ),

                Positioned(
                  top: topSafe + 157,
                  left: 24,
                  child: const WeatherCard(),
                ),

                Positioned(
                  top: topSafe + 142,
                  left: 24,
                  child: const TripPill(),
                ),

                Positioned(
                  top: topSafe + 122,
                  right: 26,
                  child: const NoticePill(),
                ),

                AnimatedBuilder(
                  animation: _floatCtrl,
                  builder: (context, child) {
                    final t = math.sin(_floatCtrl.value * math.pi * 2);
                    return Positioned(
                      top: h * 0.165 + t * 7,
                      left: -8,
                      right: -8,
                      height: h * 0.565,
                      child: child!,
                    );
                  },
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: LanXiaoXinPainter(),
                    ),
                  ),
                ),

                Positioned(
                  top: h * 0.275,
                  right: 23,
                  child: const AffinityCard(),
                ),

                Positioned(
                  top: h * 0.365,
                  right: 23,
                  child: const MoodEnergyCard(),
                ),

                Positioned(
                  top: h * 0.448,
                  right: 28,
                  child: const PlanningBadge(),
                ),

                Positioned(
                  top: h * 0.505,
                  right: 25,
                  child: const MemoryCapsule(),
                ),

                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 15,
                  height: chatHeight,
                  child: const ChatGlassPanel(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class MockStatusBar extends StatelessWidget {
  const MockStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          '9:41',
          style: TextStyle(
            color: Color(0xFF06224E),
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        const Spacer(),
        Icon(Icons.signal_cellular_alt_rounded, size: 18, color: Colors.black.withOpacity(.92)),
        const SizedBox(width: 5),
        Icon(Icons.wifi_rounded, size: 18, color: Colors.black.withOpacity(.92)),
        const SizedBox(width: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(.9),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            '100',
            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class BrandBlock extends StatelessWidget {
  const BrandBlock({super.key});

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
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(r),
            child: const Text(
              '蓝心同行',
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                height: 0.92,
                letterSpacing: -1.2,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'AI Travel Companion',
            style: TextStyle(
              color: const Color(0xFF275DBF).withOpacity(.78),
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              letterSpacing: .25,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '出行前规划中',
            style: TextStyle(
              color: const Color(0xFF2559B0).withOpacity(.78),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class TripPill extends StatelessWidget {
  const TripPill({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassBox(
      borderRadius: 22,
      blur: 20,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      opacity: .22,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on_rounded, color: Color(0xFF5F9BFF), size: 20),
          const SizedBox(width: 8),
          const Text(
            '重庆周末游',
            style: TextStyle(
              color: Color(0xFF2B5BA9),
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right_rounded, color: const Color(0xFF326BCA).withOpacity(.85), size: 20),
        ],
      ),
    );
  }
}

class WeatherCard extends StatelessWidget {
  const WeatherCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassBox(
      width: 128,
      borderRadius: 23,
      padding: const EdgeInsets.fromLTRB(13, 12, 12, 12),
      opacity: .2,
      blur: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_rounded, color: Colors.white, size: 21),
              const SizedBox(width: 8),
              ShaderMask(
                shaderCallback: (r) => const LinearGradient(
                  colors: [Color(0xFF4A83FF), Color(0xFFA7CBFF)],
                ).createShader(r),
                child: const Text(
                  '24°C 多云',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFDF73), size: 15),
              const SizedBox(width: 6),
              Text(
                '适合夜景',
                style: TextStyle(
                  color: const Color(0xFF2F64BF).withOpacity(.72),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DemoButton extends StatelessWidget {
  const DemoButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassBox(
      borderRadius: 25,
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
      opacity: .20,
      blur: 22,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.smart_toy_rounded, color: Colors.white, size: 22),
          SizedBox(width: 8),
          Text(
            '演示模式',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
          ),
          SizedBox(width: 5),
          Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
        ],
      ),
    );
  }
}

class NoticePill extends StatelessWidget {
  const NoticePill({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassBox(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      opacity: .16,
      blur: 20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.notifications_none_rounded, color: Colors.white, size: 18),
          SizedBox(width: 7),
          Text('消息', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
        ],
      ),
    );
  }
}

class AffinityCard extends StatelessWidget {
  const AffinityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassBox(
      width: 126,
      borderRadius: 22,
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 11),
      opacity: .18,
      blur: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.favorite_rounded, color: Color(0xFFFF8CCF), size: 19),
              SizedBox(width: 8),
              Text('默契值', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text('12', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
              const Spacer(),
              Icon(Icons.sync_rounded, color: Colors.white.withOpacity(.45), size: 18),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: .42,
              backgroundColor: Colors.white.withOpacity(.22),
              color: const Color(0xFF6F98FF),
            ),
          ),
        ],
      ),
    );
  }
}

class MoodEnergyCard extends StatelessWidget {
  const MoodEnergyCard({super.key});

  @override
  Widget build(BuildContext context) {
    TextStyle labelStyle = TextStyle(color: Colors.white.withOpacity(.78), fontSize: 13, fontWeight: FontWeight.w700);
    const valueStyle = TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900);

    return GlassBox(
      width: 126,
      borderRadius: 22,
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      opacity: .18,
      blur: 22,
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.mood_rounded, color: Color(0xFFFFDA7D), size: 18),
              const SizedBox(width: 7),
              Text('心情', style: labelStyle),
              const Spacer(),
              const Text('开心', style: valueStyle),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: Colors.white.withOpacity(.23)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: Color(0xFFFFD953), size: 18),
              const SizedBox(width: 7),
              Text('精力', style: labelStyle),
              const Spacer(),
              const Text('90', style: valueStyle),
            ],
          ),
        ],
      ),
    );
  }
}

class PlanningBadge extends StatelessWidget {
  const PlanningBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassBox(
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      opacity: .17,
      blur: 22,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('正在帮你规划', style: TextStyle(color: Colors.white.withOpacity(.92), fontWeight: FontWeight.w900, fontSize: 12)),
          const SizedBox(width: 7),
          const Icon(Icons.graphic_eq_rounded, color: Color(0xFFA6D9FF), size: 16),
        ],
      ),
    );
  }
}

class MemoryCapsule extends StatelessWidget {
  const MemoryCapsule({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 222,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 10,
            right: 52,
            child: GlassBox(
              borderRadius: 22,
              blur: 24,
              opacity: .24,
              padding: const EdgeInsets.fromLTRB(15, 13, 14, 13),
              child: Row(
                children: [
                  const CrystalDot(size: 22),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '发现了新的旅行偏好',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '点击查看 》',
                          style: TextStyle(color: Colors.white.withOpacity(.74), fontSize: 12.2, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: -2,
            child: Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Colors.white, Color(0xFF9DD7FF), Color(0xFF3676FF), Color(0xFF705AFF)],
                  stops: [0.05, .28, .67, 1],
                  center: Alignment(-.32, -.38),
                ),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF5A8DFF).withOpacity(.50), blurRadius: 25, spreadRadius: 5),
                  BoxShadow(color: Colors.white.withOpacity(.9), blurRadius: 8, spreadRadius: -1),
                ],
                border: Border.all(color: Colors.white.withOpacity(.75), width: 1.2),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatGlassPanel extends StatelessWidget {
  const ChatGlassPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassBox(
      borderRadius: 34,
      opacity: .21,
      blur: 30,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.42),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                return SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: c.maxHeight),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: const [
                        ChatRow(
                          isUser: false,
                          text: '嗨嗨！想去哪儿玩呢？\n我来帮你规划吧！',
                        ),
                        SizedBox(height: 14),
                        ChatRow(
                          isUser: true,
                          text: '周末想去重庆两天，不想太累，\n喜欢夜景，我不吃香菜。',
                        ),
                        SizedBox(height: 14),
                        ChatRow(
                          isUser: false,
                          text: '收到！我先帮你抓几个会影响旅行体验的\n小偏好，保存前会让你自己决定哦～',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          const ComposerBar(),
          const SizedBox(height: 12),
          const QuickChips(),
        ],
      ),
    );
  }
}

class ChatRow extends StatelessWidget {
  const ChatRow({super.key, required this.isUser, required this.text});

  final bool isUser;
  final String text;

  @override
  Widget build(BuildContext context) {
    final bubble = Flexible(
      child: GlassBox(
        borderRadius: 21,
        opacity: isUser ? .34 : .30,
        blur: 18,
        gradient: isUser
            ? const LinearGradient(
                colors: [Color(0xAA4C86FF), Color(0xAA6CA2FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        padding: const EdgeInsets.fromLTRB(14, 11, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isUser ? Colors.white : const Color(0xFF21395D),
                height: 1.42,
                fontSize: 14.8,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                isUser ? '09:41 ✓✓' : '09:41',
                style: TextStyle(
                  color: isUser ? Colors.white.withOpacity(.72) : const Color(0xFF4B6290).withOpacity(.55),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: isUser
          ? [
              const SizedBox(width: 46),
              bubble,
              const SizedBox(width: 8),
              const UserAvatar(),
            ]
          : [
              const MascotAvatar(),
              const SizedBox(width: 8),
              bubble,
              const SizedBox(width: 38),
            ],
    );
  }
}

class MascotAvatar extends StatelessWidget {
  const MascotAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(colors: [Colors.white, Color(0xFFD9EEFF)]),
        border: Border.all(color: Colors.white.withOpacity(.85), width: 1.2),
        boxShadow: [
          BoxShadow(color: const Color(0xFF66A2FF).withOpacity(.28), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: ClipOval(
        child: CustomPaint(painter: MiniMascotPainter()),
      ),
    );
  }
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFD3E9FF), Color(0xFF5C87C8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(.85), width: 1.2),
      ),
      child: Icon(Icons.person_rounded, color: Colors.white.withOpacity(.9), size: 24),
    );
  }
}

class ComposerBar extends StatelessWidget {
  const ComposerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GlassRoundButton(icon: Icons.mic_none_rounded),
        const SizedBox(width: 10),
        Expanded(
          child: GlassBox(
            height: 47,
            borderRadius: 25,
            opacity: .22,
            blur: 20,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '说点什么吧...',
                  style: TextStyle(
                    color: const Color(0xFF425D8E).withOpacity(.45),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Icon(Icons.emoji_emotions_outlined, color: Colors.white.withOpacity(.86), size: 24),
                const SizedBox(width: 16),
                Icon(Icons.image_outlined, color: Colors.white.withOpacity(.86), size: 24),
                const SizedBox(width: 16),
                Icon(Icons.place_outlined, color: Colors.white.withOpacity(.86), size: 25),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        GlassRoundButton(icon: Icons.add_rounded, iconSize: 32),
      ],
    );
  }
}

class GlassRoundButton extends StatelessWidget {
  const GlassRoundButton({super.key, required this.icon, this.iconSize = 26});

  final IconData icon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return GlassBox(
      width: 47,
      height: 47,
      borderRadius: 99,
      blur: 18,
      opacity: .18,
      padding: EdgeInsets.zero,
      child: Icon(icon, color: Colors.white.withOpacity(.88), size: iconSize),
    );
  }
}

class QuickChips extends StatelessWidget {
  const QuickChips({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.map_rounded, '规划路线'),
      (Icons.trip_origin_rounded, '记忆胶囊'),
      (Icons.tune_rounded, '调整行程'),
      (Icons.star_rounded, '生成复盘'),
      (Icons.grid_view_rounded, ''),
    ];

    return Row(
      children: [
        for (final item in items) ...[
          Expanded(
            flex: item.$2.isEmpty ? 7 : 14,
            child: GlassBox(
              height: 42,
              borderRadius: 17,
              opacity: .18,
              blur: 18,
              padding: EdgeInsets.symmetric(horizontal: item.$2.isEmpty ? 0 : 9),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.$1, color: item.$2 == '记忆胶囊' ? const Color(0xFF5C82FF) : const Color(0xFF72A8FF), size: 19),
                  if (item.$2.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        item.$2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF2D62BD).withOpacity(.72),
                          fontWeight: FontWeight.w900,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (item != items.last) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class GlassBox extends StatelessWidget {
  const GlassBox({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius = 24,
    this.padding = const EdgeInsets.all(12),
    this.opacity = .18,
    this.blur = 18,
    this.gradient,
  });

  final Widget child;
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double opacity;
  final double blur;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: gradient ??
                LinearGradient(
                  colors: [
                    Colors.white.withOpacity(opacity + .16),
                    const Color(0xFFBBD8FF).withOpacity(opacity),
                    Colors.white.withOpacity(opacity * .55),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
            border: Border.all(color: Colors.white.withOpacity(.48), width: 1.1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5C97FF).withOpacity(.20),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(.35),
                blurRadius: 5,
                offset: const Offset(-1.4, -1.4),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    gradient: LinearGradient(
                      colors: [Colors.white.withOpacity(.28), Colors.transparent],
                      begin: Alignment.topLeft,
                      end: Alignment.center,
                    ),
                  ),
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class CrystalDot extends StatelessWidget {
  const CrystalDot({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Colors.white, Color(0xFF8CE4FF), Color(0xFF396EFF), Color(0xFF785EFF)],
          stops: [0.05, .32, .7, 1],
          center: Alignment(-.3, -.35),
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFF558DFF).withOpacity(.55), blurRadius: 14, spreadRadius: 2),
        ],
        border: Border.all(color: Colors.white.withOpacity(.72), width: 1),
      ),
    );
  }
}

class SkyTravelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF5FA4FF),
          Color(0xFFAAD6FF),
          Color(0xFFE8F7FF),
          Color(0xFFCFEAFF),
        ],
        stops: [0, .35, .63, 1],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    _drawSunGlow(canvas, size);
    _drawClouds(canvas, size);
    _drawCity(canvas, size);
    _drawMapTexture(canvas, size);
    _drawRoutes(canvas, size);
  }

  void _drawSunGlow(Canvas canvas, Size s) {
    final p = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(.70),
          Colors.white.withOpacity(.25),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(s.width * .24, s.height * .17), radius: s.width * .55));
    canvas.drawCircle(Offset(s.width * .24, s.height * .17), s.width * .55, p);

    final rightGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF3B76FF).withOpacity(.16),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(s.width * .88, s.height * .1), radius: s.width * .45));
    canvas.drawCircle(Offset(s.width * .88, s.height * .1), s.width * .45, rightGlow);
  }

  void _drawClouds(Canvas canvas, Size s) {
    final cloudPaint = Paint()..color = Colors.white.withOpacity(.55);
    final blurPaint = Paint()
      ..color = Colors.white.withOpacity(.20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);

    void cloud(double x, double y, double scale, double opacity) {
      final p = Paint()..color = Colors.white.withOpacity(opacity);
      canvas.drawOval(Rect.fromLTWH(x, y + 20 * scale, 150 * scale, 42 * scale), p);
      canvas.drawCircle(Offset(x + 38 * scale, y + 26 * scale), 31 * scale, p);
      canvas.drawCircle(Offset(x + 78 * scale, y + 10 * scale), 42 * scale, p);
      canvas.drawCircle(Offset(x + 120 * scale, y + 31 * scale), 29 * scale, p);
    }

    canvas.drawCircle(Offset(s.width * .8, s.height * .2), 72, blurPaint);
    cloud(-28, s.height * .25, 1.25, .36);
    cloud(s.width * .58, s.height * .18, 1.1, .30);
    cloud(s.width * .01, s.height * .49, 1.0, .25);
    cloud(s.width * .52, s.height * .63, 1.4, .18);
    canvas.drawOval(Rect.fromLTWH(-40, s.height * .58, s.width * .72, 70), cloudPaint..color = Colors.white.withOpacity(.18));
  }

  void _drawCity(Canvas canvas, Size s) {
    final p = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white.withOpacity(.10), const Color(0xFF5B91DA).withOpacity(.12)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, s.height * .47, s.width, s.height * .36));

    final baseY = s.height * .64;
    final path = Path();
    double x = -20;
    final rnd = [74.0, 42.0, 96.0, 58.0, 82.0, 46.0, 111.0, 70.0, 50.0, 92.0, 66.0];
    for (int i = 0; x < s.width + 30; i++) {
      final w = 24 + (i % 3) * 8.0;
      final h = rnd[i % rnd.length];
      path.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, baseY - h, w, h + 25),
          const Radius.circular(5),
        ),
      );
      x += w + 7;
    }
    canvas.drawPath(path, p);

    final line = Paint()
      ..color = Colors.white.withOpacity(.25)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, baseY), Offset(s.width, baseY), line);
  }

  void _drawMapTexture(Canvas canvas, Size s) {
    final p = Paint()
      ..color = Colors.white.withOpacity(.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    for (int i = 0; i < 6; i++) {
      final y = s.height * (.12 + i * .10);
      final path = Path()..moveTo(-20, y);
      for (double x = -20; x < s.width + 40; x += 80) {
        path.quadraticBezierTo(x + 38, y + (i.isEven ? 18 : -18), x + 78, y + (i.isEven ? 2 : -2));
      }
      canvas.drawPath(path, p);
    }

    final pinPaint = Paint()..color = Colors.white.withOpacity(.82);
    final glow = Paint()
      ..color = const Color(0xFF5C91FF).withOpacity(.24)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
    _pin(canvas, Offset(s.width * .83, s.height * .25), pinPaint, glow, 1.0);
    _pin(canvas, Offset(s.width * .2, s.height * .50), pinPaint, glow, .72);
  }

  void _pin(Canvas canvas, Offset c, Paint p, Paint glow, double scale) {
    canvas.drawCircle(c, 22 * scale, glow);
    final path = Path()
      ..moveTo(c.dx, c.dy + 24 * scale)
      ..cubicTo(c.dx - 20 * scale, c.dy - 4 * scale, c.dx - 13 * scale, c.dy - 22 * scale, c.dx, c.dy - 22 * scale)
      ..cubicTo(c.dx + 13 * scale, c.dy - 22 * scale, c.dx + 20 * scale, c.dy - 4 * scale, c.dx, c.dy + 24 * scale)
      ..close();
    canvas.drawPath(path, p);
    canvas.drawCircle(Offset(c.dx, c.dy - 4 * scale), 7 * scale, Paint()..color = const Color(0xFF6FA8FF).withOpacity(.70));
  }

  void _drawRoutes(Canvas canvas, Size s) {
    final p = Paint()
      ..color = Colors.white.withOpacity(.66)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(-10, s.height * .51)
      ..cubicTo(s.width * .22, s.height * .39, s.width * .28, s.height * .32, s.width * .52, s.height * .32)
      ..cubicTo(s.width * .70, s.height * .32, s.width * .74, s.height * .24, s.width * .86, s.height * .24);
    _drawDashedPath(canvas, path, p, 9, 9);

    final path2 = Path()
      ..moveTo(s.width * .13, s.height * .76)
      ..cubicTo(s.width * .30, s.height * .70, s.width * .36, s.height * .82, s.width * .58, s.height * .75)
      ..cubicTo(s.width * .77, s.height * .70, s.width * .73, s.height * .58, s.width * .92, s.height * .56);
    _drawDashedPath(canvas, path2, p..color = Colors.white.withOpacity(.33), 7, 10);

    final planePaint = Paint()..color = Colors.white.withOpacity(.78);
    final plane = Path()
      ..moveTo(s.width * .16, s.height * .42)
      ..lineTo(s.width * .25, s.height * .39)
      ..lineTo(s.width * .20, s.height * .48)
      ..lineTo(s.width * .19, s.height * .43)
      ..close();
    canvas.drawPath(plane, planePaint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint, double dash, double gap) {
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, math.min(d + dash, metric.length)), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LanXiaoXinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.save();
    canvas.translate(w * .5, 0);
    final scale = math.min(w / 390, h / 520);
    canvas.scale(scale);

    _drawAura(canvas);
    _drawBackpack(canvas);
    _drawBody(canvas);
    _drawHeadphones(canvas);
    _drawNeckAndFace(canvas);
    _drawHair(canvas);
    _drawFaceDetails(canvas);
    _drawAccessories(canvas);

    canvas.restore();
  }

  void _drawAura(Canvas canvas) {
    final p = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(.55),
          const Color(0xFF95C7FF).withOpacity(.28),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: const Offset(0, 235), radius: 230));
    canvas.drawOval(const Rect.fromLTWH(-175, 50, 350, 470), p);
  }

  void _drawBackpack(Canvas canvas) {
    final p = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1E4B95), Color(0xFF163263)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(const Rect.fromLTWH(-150, 210, 300, 260));
    final left = Path()
      ..moveTo(-118, 240)
      ..cubicTo(-160, 285, -168, 410, -124, 478)
      ..lineTo(-82, 468)
      ..cubicTo(-100, 378, -92, 299, -68, 238)
      ..close();
    canvas.drawPath(left, p);
    final right = Path()
      ..moveTo(118, 245)
      ..cubicTo(158, 292, 166, 407, 124, 478)
      ..lineTo(80, 468)
      ..cubicTo(100, 372, 94, 304, 68, 240)
      ..close();
    canvas.drawPath(right, p..color = const Color(0xFF1C478C));
  }

  void _drawBody(Canvas canvas) {
    final jacket = Path()
      ..moveTo(-104, 265)
      ..cubicTo(-148, 295, -166, 402, -151, 505)
      ..lineTo(151, 505)
      ..cubicTo(166, 402, 148, 294, 104, 265)
      ..cubicTo(66, 303, -66, 303, -104, 265)
      ..close();

    canvas.drawShadow(jacket, const Color(0xFF2C5DB0).withOpacity(.35), 16, false);

    final jacketPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.white, Color(0xFFEAF5FF), Color(0xFFD0E7FF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(const Rect.fromLTWH(-170, 250, 340, 280));
    canvas.drawPath(jacket, jacketPaint);

    final leftBlue = Path()
      ..moveTo(-104, 270)
      ..cubicTo(-137, 333, -144, 425, -128, 502)
      ..lineTo(-88, 502)
      ..cubicTo(-105, 395, -94, 319, -50, 285)
      ..close();
    canvas.drawPath(leftBlue, Paint()..color = const Color(0xFF3178D8).withOpacity(.86));

    final rightBlue = Path()
      ..moveTo(104, 270)
      ..cubicTo(137, 333, 144, 425, 128, 502)
      ..lineTo(87, 502)
      ..cubicTo(105, 395, 94, 319, 50, 285)
      ..close();
    canvas.drawPath(rightBlue, Paint()..color = const Color(0xFF4B91EF).withOpacity(.40));

    final shirt = Path()
      ..moveTo(-48, 286)
      ..cubicTo(-25, 316, 25, 316, 48, 286)
      ..lineTo(74, 505)
      ..lineTo(-74, 505)
      ..close();
    canvas.drawPath(shirt, Paint()..color = Colors.white.withOpacity(.92));

    final zipper = Paint()
      ..color = const Color(0xFF5E9EF8).withOpacity(.5)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-48, 307), const Offset(-72, 503), zipper);
    canvas.drawLine(const Offset(48, 307), const Offset(72, 503), zipper);

    final strapPaint = Paint()
      ..color = const Color(0xFF163B7D).withOpacity(.78)
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-92, 283), const Offset(-116, 505), strapPaint);
    canvas.drawLine(const Offset(92, 283), const Offset(116, 505), strapPaint);

    final handPaint = Paint()
      ..shader = const LinearGradient(colors: [Color(0xFFFFEFEA), Color(0xFFFFD3CF)]).createShader(const Rect.fromLTWH(-128, 330, 50, 80));
    canvas.drawOval(const Rect.fromLTWH(-128, 340, 40, 56), handPaint);
    canvas.drawCircle(const Offset(-101, 365), 13, handPaint);
  }

  void _drawHeadphones(Canvas canvas) {
    final band = Paint()
      ..color = const Color(0xFF79AFFF).withOpacity(.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(const Rect.fromLTWH(-70, 226, 140, 78), math.pi * .08, math.pi * .84, false, band);

    Paint cup = Paint()
      ..shader = const LinearGradient(colors: [Colors.white, Color(0xFF9CCBFF), Color(0xFF4B83E5)]).createShader(const Rect.fromLTWH(-100, 260, 200, 80));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-78, 255, 48, 58), const Radius.circular(22)), cup);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(30, 255, 48, 58), const Radius.circular(22)), cup);
    canvas.drawCircle(const Offset(-54, 284), 14, Paint()..color = Colors.white.withOpacity(.72));
    canvas.drawCircle(const Offset(54, 284), 14, Paint()..color = Colors.white.withOpacity(.72));
  }

  void _drawNeckAndFace(Canvas canvas) {
    final neckPaint = Paint()
      ..shader = const LinearGradient(colors: [Color(0xFFFFE0DE), Color(0xFFFFF1EC)]).createShader(const Rect.fromLTWH(-30, 214, 60, 85));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-28, 210, 56, 75), const Radius.circular(22)), neckPaint);

    final face = Path()
      ..moveTo(-72, 116)
      ..cubicTo(-88, 174, -62, 227, -8, 241)
      ..cubicTo(56, 257, 90, 198, 73, 126)
      ..cubicTo(61, 81, -53, 77, -72, 116)
      ..close();

    canvas.drawShadow(face, const Color(0xFF315AA3).withOpacity(.15), 12, false);
    final facePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFF7F4), Color(0xFFFFE0DE)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(const Rect.fromLTWH(-90, 80, 180, 170));
    canvas.drawPath(face, facePaint);
  }

  void _drawHair(Canvas canvas) {
    final hairPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.white, Color(0xFFEAF6FF), Color(0xFFBBD8FF)],
        stops: [0, .55, 1],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(const Rect.fromLTWH(-135, 20, 270, 235));

    final backHair = Path()
      ..moveTo(-96, 112)
      ..cubicTo(-128, 143, -126, 216, -93, 252)
      ..cubicTo(-72, 275, -33, 266, -20, 238)
      ..cubicTo(34, 278, 102, 258, 112, 196)
      ..cubicTo(130, 89, 39, 39, -35, 56)
      ..cubicTo(-62, 62, -82, 79, -96, 112)
      ..close();
    canvas.drawPath(backHair, hairPaint);

    final frontHair = Path()
      ..moveTo(-80, 104)
      ..cubicTo(-54, 56, 22, 45, 74, 84)
      ..cubicTo(43, 75, 20, 88, 5, 130)
      ..cubicTo(-15, 88, -45, 86, -80, 104)
      ..close();
    canvas.drawPath(frontHair, hairPaint);

    final bangs = Paint()
      ..shader = const LinearGradient(colors: [Colors.white, Color(0xFFDDEFFF)]).createShader(const Rect.fromLTWH(-75, 78, 150, 110));
    for (final spec in [
      [-54.0, 78.0, -12.0, 173.0, 18.0, 102.0],
      [-18.0, 67.0, -4.0, 182.0, 34.0, 96.0],
      [20.0, 72.0, 4.0, 176.0, 70.0, 113.0],
      [-83.0, 107.0, -67.0, 201.0, -12.0, 123.0],
    ]) {
      final path = Path()
        ..moveTo(spec[0], spec[1])
        ..quadraticBezierTo(spec[4], spec[5], spec[2], spec[3])
        ..quadraticBezierTo(spec[0] - 26, spec[1] + 44, spec[0], spec[1]);
      canvas.drawPath(path, bangs);
    }

    final ahoge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(colors: [Colors.white, Color(0xFFCFE6FF)]).createShader(const Rect.fromLTWH(-25, 0, 80, 70));
    final p = Path()
      ..moveTo(-12, 61)
      ..cubicTo(-4, 26, 28, 18, 24, 48)
      ..cubicTo(41, 34, 54, 52, 34, 69);
    canvas.drawPath(p, ahoge);

    final shine = Paint()
      ..color = Colors.white.withOpacity(.68)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-72, 135), const Offset(-106, 211), shine);
    canvas.drawLine(const Offset(76, 136), const Offset(102, 204), shine);
    canvas.drawLine(const Offset(12, 88), const Offset(2, 154), shine);
  }

  void _drawFaceDetails(Canvas canvas) {
    final eyePaint = Paint()
      ..shader = const RadialGradient(
        colors: [Colors.white, Color(0xFF8DD7FF), Color(0xFF2F66E8), Color(0xFF102D82)],
        stops: [0.02, .22, .62, 1],
        center: Alignment(-.3, -.45),
      ).createShader(const Rect.fromLTWH(-72, 130, 144, 50));
    canvas.drawOval(const Rect.fromLTWH(-58, 139, 32, 42), eyePaint);
    canvas.drawOval(const Rect.fromLTWH(26, 139, 32, 42), eyePaint);

    final pupil = Paint()..color = const Color(0xFF0E2676).withOpacity(.9);
    canvas.drawOval(const Rect.fromLTWH(-48, 151, 13, 22), pupil);
    canvas.drawOval(const Rect.fromLTWH(36, 151, 13, 22), pupil);
    final hi = Paint()..color = Colors.white.withOpacity(.94);
    canvas.drawCircle(const Offset(-48, 148), 5.2, hi);
    canvas.drawCircle(const Offset(36, 148), 5.2, hi);
    canvas.drawCircle(const Offset(-35, 164), 2.4, hi);
    canvas.drawCircle(const Offset(49, 164), 2.4, hi);

    final lash = Paint()
      ..color = const Color(0xFF172B5F).withOpacity(.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final l = Path()..moveTo(-66, 143)..quadraticBezierTo(-43, 130, -22, 141);
    final r = Path()..moveTo(22, 141)..quadraticBezierTo(43, 130, 66, 143);
    canvas.drawPath(l, lash);
    canvas.drawPath(r, lash);

    final blush = Paint()..color = const Color(0xFFFF8DA4).withOpacity(.18);
    canvas.drawOval(const Rect.fromLTWH(-78, 184, 32, 14), blush);
    canvas.drawOval(const Rect.fromLTWH(48, 184, 32, 14), blush);

    final mouth = Paint()
      ..color = const Color(0xFFB25E6D).withOpacity(.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final m = Path()..moveTo(-8, 202)..quadraticBezierTo(0, 208, 10, 202);
    canvas.drawPath(m, mouth);
  }

  void _drawAccessories(Canvas canvas) {
    final crystal = Paint()
      ..shader = const RadialGradient(
        colors: [Colors.white, Color(0xFF7BE2FF), Color(0xFF3468F8), Color(0xFF6E58FF)],
        stops: [.08, .30, .7, 1],
        center: Alignment(-.35, -.35),
      ).createShader(const Rect.fromLTWH(60, 88, 48, 48));
    canvas.drawCircle(const Offset(82, 112), 22, crystal);
    canvas.drawCircle(const Offset(82, 112), 22, Paint()
      ..color = Colors.white.withOpacity(.62)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);

    final ribbon = Paint()..color = const Color(0xFF2B6CD8).withOpacity(.88);
    final bow1 = Path()
      ..moveTo(96, 119)
      ..lineTo(132, 104)
      ..lineTo(125, 144)
      ..close();
    final bow2 = Path()
      ..moveTo(100, 123)
      ..lineTo(138, 142)
      ..lineTo(110, 152)
      ..close();
    canvas.drawPath(bow1, ribbon);
    canvas.drawPath(bow2, ribbon..color = const Color(0xFF4C91EE).withOpacity(.88));

    final badgePaint = Paint()
      ..shader = const RadialGradient(
        colors: [Colors.white, Color(0xFF7BE2FF), Color(0xFF477CFF), Color(0xFF7963FF)],
        stops: [.1, .35, .75, 1],
      ).createShader(const Rect.fromLTWH(30, 334, 42, 42));
    canvas.drawCircle(const Offset(52, 356), 18, badgePaint);
    canvas.drawCircle(const Offset(52, 356), 18, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withOpacity(.65));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MiniMascotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height * .08);
    final sc = size.width / 130;
    canvas.scale(sc);

    final hair = Paint()
      ..shader = const LinearGradient(colors: [Colors.white, Color(0xFFD2EAFF)]).createShader(const Rect.fromLTWH(-50, 0, 100, 80));
    canvas.drawOval(const Rect.fromLTWH(-48, 5, 96, 90), hair);

    final face = Paint()..color = const Color(0xFFFFEEE9);
    canvas.drawOval(const Rect.fromLTWH(-34, 30, 68, 66), face);

    final eye = Paint()
      ..shader = const RadialGradient(colors: [Colors.white, Color(0xFF59BBFF), Color(0xFF255EE4)]).createShader(const Rect.fromLTWH(-30, 48, 60, 20));
    canvas.drawOval(const Rect.fromLTWH(-23, 53, 13, 18), eye);
    canvas.drawOval(const Rect.fromLTWH(10, 53, 13, 18), eye);

    final body = Paint()..color = const Color(0xFF73A9FF);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-35, 88, 70, 45), const Radius.circular(20)), body);
    canvas.drawCircle(const Offset(31, 28), 11, Paint()..color = const Color(0xFF5F86FF));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
