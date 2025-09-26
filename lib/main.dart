import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_animate/flutter_animate.dart'; // Removed due to compatibility issues
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/google_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Google Auth Service
  await GoogleAuthService().initialize();
  
  // Animate.restartOnHotReload = true; // Disabled due to compatibility issues
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
