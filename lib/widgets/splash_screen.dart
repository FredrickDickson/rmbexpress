import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/supabase_service.dart';
import '../core/router/app_router.dart';
import 'loading_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  final _supabaseService = SupabaseService();
  
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    try {
      // Show loading screen for minimum duration for better UX
      await Future.wait([
        _checkAuthStatus(),
        Future.delayed(const Duration(seconds: 2)), // Minimum splash duration
      ]);
      
      if (mounted) {
        _navigateToNextScreen();
      }
    } catch (e) {
      if (mounted) {
        _navigateToLogin();
      }
    }
  }
  
  Future<void> _checkAuthStatus() async {
    // Initialize Supabase and check authentication status
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate initialization
    
    final user = _supabaseService.currentUser;
    if (user != null) {
      // User is logged in, load user profile to verify account status
      try {
        await _supabaseService.getUserProfile();
      } catch (e) {
        // Profile loading failed, treat as unauthenticated
        rethrow;
      }
    }
  }
  
  void _navigateToNextScreen() {
    final user = _supabaseService.currentUser;
    
    if (user != null) {
      // User is authenticated, navigate to dashboard
      AppRouter.router.go(AppRouter.dashboard);
    } else {
      // User not authenticated, navigate to login
      _navigateToLogin();
    }
  }
  
  void _navigateToLogin() {
    AppRouter.router.go(AppRouter.login);
  }
  
  @override
  Widget build(BuildContext context) {
    return const LoadingScreen(
      message: 'Welcome to BuyRMBOnline',
      showLogo: true,
      duration: Duration(seconds: 3),
    );
  }
}