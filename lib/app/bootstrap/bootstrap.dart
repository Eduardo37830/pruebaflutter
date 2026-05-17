import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/presentation/widgets/theme_mode_provider.dart';
import '../router/app_router.dart';
import '../theme/stitch_theme.dart';
import '../../sync/engine/sync_engine.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PlatformDispatcher error: $error\n$stack');
    return true;
  };

  runApp(const ProviderScope(child: App()));
}

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  bool _syncStarted = false;

  @override
  Widget build(BuildContext context) {
    if (!_syncStarted) {
      _syncStarted = true;
      Future.microtask(() {
        ref.read(syncEngineProvider).processQueue();
      });
    }

    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Escritor App',
      theme: StitchTheme.light(),
      darkTheme: StitchTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
