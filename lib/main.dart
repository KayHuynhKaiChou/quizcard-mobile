import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/services/auth_service.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Restore saved session BEFORE building the widget tree so the router
  // redirect sees the correct isAuthenticated value on first evaluation.
  final authService = AuthService();
  await authService.tryAutoLogin();

  runApp(
    ChangeNotifierProvider.value(
      value: authService,
      child: QuizcardApp(authService: authService),
    ),
  );
}

class QuizcardApp extends StatelessWidget {
  final AuthService authService;
  const QuizcardApp({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Quizcard Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: AppRouter.router(authService),
    );
  }
}
