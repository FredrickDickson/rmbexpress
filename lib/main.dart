import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_animate/flutter_animate.dart'; // Removed due to compatibility issues
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase service
  try {
    await SupabaseService().initialize();
  } catch (e) {
    debugPrint('❌ Critical error initializing Supabase: $e');
    // In production, you might want to show an error screen
    // For now, we continue but the app may not function correctly
  }
  
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
