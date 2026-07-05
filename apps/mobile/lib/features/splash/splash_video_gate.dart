import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'splash_preference_service.dart';

class SplashVideoGate extends StatefulWidget {
  const SplashVideoGate({
    super.key,
    required this.child,
    this.assetPath = 'assets/splash/lanxin_splash.mp4',
    this.idleAssetPath = 'assets/splash/lanxin_idle_silent.mp4',
    this.enabled = true,
    this.preferenceService,
    this.minimumDisplay = const Duration(milliseconds: 700),
    this.maximumDisplay = const Duration(seconds: 30),
    this.fadeDuration = const Duration(milliseconds: 1200),
    this.childRevealDuration = const Duration(milliseconds: 3000),
    this.videoVolume = 1.0,
    this.idleVideoVolume = 0.0,
    this.continueLabel = '开始我们的旅行吧!!!',
  });

  final Widget child;
  final String assetPath;
  final String idleAssetPath;
  final bool enabled;
  final SplashPreferenceService? preferenceService;
  final Duration minimumDisplay;
  final Duration maximumDisplay;
  final Duration fadeDuration;
  final Duration childRevealDuration;
  final double videoVolume;
  final double idleVideoVolume;
  final String continueLabel;

  @override
  State<SplashVideoGate> createState() => _SplashVideoGateState();
}

class _SplashVideoGateState extends State<SplashVideoGate> {
  late final SplashPreferenceService _preferenceService;
  VideoPlayerController? _openingController;
  VideoPlayerController? _idleController;
  VideoPlayerController? _activeController;
  Timer? _fallbackTimer;
  DateTime? _shownAt;
  bool _checkingPolicy = true;
  bool _visible = false;
  bool _removed = true;
  bool _finishing = false;
  bool _childRevealed = false;
  bool _idleReady = false;
  bool _waitingForContinue = false;

  @override
  void initState() {
    super.initState();
    _preferenceService = widget.preferenceService ?? SplashPreferenceService();
    _prepare();
  }

  Future<void> _prepare() async {
    if (!widget.enabled) {
      _finishPolicyCheckWithoutVideo();
      return;
    }
    final shouldPlay = await _preferenceService.shouldPlay();
    if (!mounted) return;
    if (!shouldPlay) {
      _finishPolicyCheckWithoutVideo();
      return;
    }
    setState(() {
      _checkingPolicy = false;
      _visible = true;
      _removed = false;
    });
    _shownAt = DateTime.now();
    await _startVideo();
  }

  void _finishPolicyCheckWithoutVideo() {
    if (!mounted) return;
    setState(() {
      _checkingPolicy = false;
      _visible = false;
      _removed = true;
    });
  }

  Future<void> _startVideo() async {
    final controller = VideoPlayerController.asset(widget.assetPath);
    _openingController = controller;
    _activeController = controller;
    controller.addListener(_handleOpeningVideoChanged);
    try {
      final idleFuture = _prepareIdleVideo();
      await controller.initialize();
      if (!mounted || _finishing) return;
      await controller.setLooping(false);
      await controller.setVolume(widget.videoVolume.clamp(0.0, 1.0));
      await controller.play();
      _scheduleOpeningFallback(controller.value.duration);
      unawaited(idleFuture);
      setState(() {});
    } catch (_) {
      _finishSplash();
    }
  }

  void _scheduleOpeningFallback(Duration openingDuration) {
    _fallbackTimer?.cancel();
    final fallbackDelay = openingDuration > Duration.zero
        ? openingDuration + const Duration(milliseconds: 900)
        : widget.maximumDisplay;
    _fallbackTimer = Timer(fallbackDelay, () {
      final controller = _openingController;
      if (controller == null || _waitingForContinue || _finishing || _removed) {
        return;
      }
      if (controller.value.hasError || controller.value.isCompleted) {
        unawaited(_enterIdleLoop());
      }
    });
  }

  Future<void> _prepareIdleVideo() async {
    final controller = VideoPlayerController.asset(widget.idleAssetPath);
    _idleController = controller;
    try {
      await controller.initialize();
      if (!mounted || _finishing) return;
      await controller.setLooping(true);
      await controller.setVolume(widget.idleVideoVolume.clamp(0.0, 1.0));
      if (!mounted || _finishing) return;
      setState(() => _idleReady = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _idleReady = false);
    }
  }

  void _handleOpeningVideoChanged() {
    final controller = _openingController;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.hasError || controller.value.isCompleted) {
      _enterIdleLoop();
    }
  }

  Future<void> _enterIdleLoop() async {
    if (_finishing || _removed || _waitingForContinue) return;
    _fallbackTimer?.cancel();
    final shownAt = _shownAt;
    if (shownAt != null) {
      final elapsed = DateTime.now().difference(shownAt);
      final remaining = widget.minimumDisplay - elapsed;
      if (remaining > Duration.zero) {
        await Future<void>.delayed(remaining);
      }
    }
    if (!mounted || _finishing || _removed || _waitingForContinue) return;
    final idleController = _idleController;
    if (idleController != null && idleController.value.isInitialized) {
      await idleController.setLooping(true);
      await idleController.setVolume(widget.idleVideoVolume.clamp(0.0, 1.0));
      await idleController.play();
      _openingController?.pause();
      setState(() {
        _activeController = idleController;
        _idleReady = true;
        _waitingForContinue = true;
      });
      return;
    }
    setState(() => _waitingForContinue = true);
  }

  Future<void> _finishSplash() async {
    if (_finishing || _removed) return;
    _finishing = true;
    final shownAt = _shownAt;
    if (shownAt != null) {
      final elapsed = DateTime.now().difference(shownAt);
      final remaining = widget.minimumDisplay - elapsed;
      if (remaining > Duration.zero) {
        await Future<void>.delayed(remaining);
      }
    }
    await _preferenceService.markPlayedToday();
    if (!mounted) return;
    _fallbackTimer?.cancel();
    await _activeController?.pause();
    setState(() {
      _visible = false;
      _childRevealed = true;
      _waitingForContinue = false;
    });
    await Future<void>.delayed(widget.fadeDuration);
    if (!mounted) return;
    setState(() => _removed = true);
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    final openingController = _openingController;
    openingController?.removeListener(_handleOpeningVideoChanged);
    openingController?.dispose();
    _idleController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedOpacity(
          opacity: _childRevealed ? 1 : 0,
          duration: widget.childRevealDuration,
          curve: Curves.easeOutCubic,
          child: AnimatedSlide(
            offset: _childRevealed ? Offset.zero : const Offset(0, 0.018),
            duration: widget.childRevealDuration,
            curve: Curves.easeOutCubic,
            child: widget.child,
          ),
        ),
        if (_checkingPolicy || !_removed)
          AnimatedOpacity(
            opacity: _visible ? 1 : 0,
            duration: widget.fadeDuration,
            curve: Curves.easeInOutCubic,
            child: _SplashLayer(
              controller: _activeController,
              idleReady: _idleReady,
              waitingForContinue: _waitingForContinue,
              continueLabel: widget.continueLabel,
              onContinue: _finishSplash,
            ),
          ),
      ],
    );
  }
}

class _SplashLayer extends StatelessWidget {
  const _SplashLayer({
    required this.controller,
    required this.idleReady,
    required this.waitingForContinue,
    required this.continueLabel,
    required this.onContinue,
  });

  final VideoPlayerController? controller;
  final bool idleReady;
  final bool waitingForContinue;
  final String continueLabel;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final ready = controller?.value.isInitialized ?? false;
    return ColoredBox(
      color: const Color(0xFF050B1C),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (ready)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller!.value.size.width,
                height: controller!.value.size.height,
                child: VideoPlayer(controller!),
              ),
            )
          else
            const _SplashFallback(),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 30,
            child: IgnorePointer(child: _SplashBrandMark()),
          ),
          Positioned(
            left: 28,
            right: 28,
            bottom: 74,
            child: _ContinueTravelButton(
              visible: waitingForContinue,
              label: continueLabel,
              onTap: onContinue,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueTravelButton extends StatelessWidget {
  const _ContinueTravelButton({
    required this.visible,
    required this.label,
    required this.onTap,
  });

  final bool visible;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, 0.12),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        child: IgnorePointer(
          ignoring: !visible,
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.24),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: Colors.white.withOpacity(0.72),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF06245C).withOpacity(0.20),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        letterSpacing: 0,
                        shadows: [
                          Shadow(
                            color: Color(0x66000000),
                            blurRadius: 12,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashFallback extends StatelessWidget {
  const _SplashFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF061A4A), Color(0xFF1C7FE8), Color(0xFFE8F7FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}

class _SplashBrandMark extends StatelessWidget {
  const _SplashBrandMark();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '蓝心同行',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
        shadows: [
          Shadow(
            color: Color(0x66000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
