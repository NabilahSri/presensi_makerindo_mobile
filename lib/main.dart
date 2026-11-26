import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/splash_screen.dart';
import 'services/api_service.dart';
import 'services/auth_controller.dart';
import 'theme/chrono_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  final api = ApiService();
  final auth = AuthController(api: api);

  runApp(ChronoMobileApp(auth: auth));
}

class ChronoMobileApp extends StatefulWidget {
  final AuthController auth;
  final Duration splashDuration;

  const ChronoMobileApp({
    super.key,
    required this.auth,
    this.splashDuration = const Duration(milliseconds: 1600),
  });

  @override
  State<ChronoMobileApp> createState() => _ChronoMobileAppState();
}

class _ChronoMobileAppState extends State<ChronoMobileApp>
    with WidgetsBindingObserver {
  bool _splashCompleted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !widget.auth.isAuthenticated) {
      widget.auth.refreshBranding().catchError((_) {});
    }
  }

  Future<void> _initializeApp() async {
    await Future.wait([
      widget.auth.bootstrap(),
      Future<void>.delayed(widget.splashDuration),
    ]);
    if (mounted) {
      setState(() => _splashCompleted = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.auth,
      builder: (context, _) {
        final auth = widget.auth;
        final brand = auth.brand;

        final Widget activeScreen;
        if (!_splashCompleted || !auth.isInitialized) {
          activeScreen = SplashScreen(
            key: const ValueKey('splash_screen'),
            brand: brand,
            statusText: auth.isAuthenticated
                ? 'Memuat halaman utama...'
                : 'Memeriksa sesi akun...',
          );
        } else if (!auth.isAuthenticated) {
          activeScreen = LoginScreen(
            key: const ValueKey('login_screen'),
            auth: auth,
          );
        } else {
          activeScreen = MainShell(
            key: ValueKey('shell_${auth.user?.id}_${auth.sessionVersion}'),
            auth: auth,
          );
        }

        return MaterialApp(
          title: '${brand.appName} Mobile',
          debugShowCheckedModeBanner: false,
          theme: ChronoTheme.build(),
          home: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: activeScreen,
          ),
        );
      },
    );
  }
}
