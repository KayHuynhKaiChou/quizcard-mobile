import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/services/auth_service.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: const QuizcardApp(),
    ),
  );
}

class QuizcardApp extends StatefulWidget {
  const QuizcardApp({super.key});

  @override
  State<QuizcardApp> createState() => _QuizcardAppState();
}

class _QuizcardAppState extends State<QuizcardApp> {
  late final AuthService _authService;
  late final _router;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _authService = context.read<AuthService>();
      _router = AppRouter.router(_authService);
      _initialized = true;
      // Try to restore saved session
      _authService.tryAutoLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Quizcard Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: _router,
    );
  }
}
