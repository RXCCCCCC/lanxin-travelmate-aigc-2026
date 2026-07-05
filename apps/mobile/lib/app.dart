import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/local/app_database.dart';
import 'data/repositories/memory_repository.dart';
import 'features/settings/data/settings_data_service.dart';
import 'features/settings/data/sync_retry_service.dart';
import 'features/splash/splash_preference_service.dart';
import 'features/splash/splash_video_gate.dart';

typedef PendingSyncRetryCallback = Future<void> Function();

class LanXinApp extends StatefulWidget {
  const LanXinApp({
    super.key,
    this.onRetryPendingSync,
    this.splashEnabled = true,
    this.splashPreferenceService,
  });

  final PendingSyncRetryCallback? onRetryPendingSync;
  final bool splashEnabled;
  final SplashPreferenceService? splashPreferenceService;

  @override
  State<LanXinApp> createState() => _LanXinAppState();
}

class _LanXinAppState extends State<LanXinApp> with WidgetsBindingObserver {
  bool _retryInFlight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(seconds: 2), _retryPendingSync);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _retryPendingSync();
    }
  }

  Future<void> _retryPendingSync() async {
    if (_retryInFlight) return;
    _retryInFlight = true;
    try {
      final callback = widget.onRetryPendingSync ?? _defaultRetryPendingSync;
      await callback();
    } finally {
      _retryInFlight = false;
    }
  }

  Future<void> _defaultRetryPendingSync() async {
    await SyncRetryService(
      repository: MemoryRepository(AppDatabase.shared()),
      dataService: SettingsDataService(),
    ).retryPendingOperations();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '蓝心同行',
      debugShowCheckedModeBanner: false,
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.light,
      routerConfig: appRouter,
      builder: (context, child) => SplashVideoGate(
        enabled: widget.splashEnabled,
        preferenceService: widget.splashPreferenceService,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
