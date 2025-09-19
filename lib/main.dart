import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

void main() {
  Animate.restartOnHotReload = true;
  runApp(const ProviderScope(child: BuyRMBOnlineApp()));
}

class BuyRMBOnlineApp extends StatelessWidget {
  const BuyRMBOnlineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'BuyRMBOnline',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
