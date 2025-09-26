# BuyRMBOnline - Flutter Web Project

## Overview
This is a Flutter web application called "BuyRMBOnline" that has been successfully set up to run in the Replit environment.

## Project Architecture
- **Language**: Dart 3.8.1
- **Framework**: Flutter 3.32.0
- **Target Platform**: Web
- **Server Port**: 5000
- **Build System**: Flutter CLI with pub package manager

## Current Setup
- Flutter project created with web platform support
- Main application entry point: `lib/main.dart`
- Web assets and configuration: `web/` directory
- Dependencies managed via `pubspec.yaml`

## Workflow Configuration
- **Flutter Web Server**: Runs on `0.0.0.0:5000` for web development
- Command: `flutter run -d web-server --web-hostname 0.0.0.0 --web-port 5000`
- Hot reload enabled for development

## Recent Changes (Sep 26, 2025)
- **Security Enhancement**: Fixed critical Supabase integration vulnerabilities by implementing authentication-based user ID derivation, preventing horizontal privilege escalation
- **Unified Authentication**: Completely migrated to Supabase-only authentication, removed GoogleAuthService dependency and google_sign_in package
- **Secure Configuration**: Updated workflow to use environment variables properly (SUPABASE_URL, SUPABASE_ANON_KEY, PAYSTACK_PUBLIC_KEY only - secret keys secured server-side)
- **Professional Branding**: Enhanced app with generated logo, improved typography, and cohesive brand identity throughout the app
- **Database Integration**: Implemented secure Supabase service with proper user scoping and server-side timestamp handling
- **Paystack Integration Foundation**: Added secure payment infrastructure with paystack_for_flutter SDK, implemented PaystackService class with proper security practices (no client-side secrets), and prepared foundation for backend payment processing
- **Payment Security**: Implemented secure payment flow that requires backend implementation before processing real transactions, protecting against client-side vulnerabilities
- **Error Resolution**: Fixed JSON parsing errors and improved application stability

## User Preferences
- No specific user preferences recorded yet

## Project Status
- ✅ Flutter environment configured
- ✅ Web server running successfully
- ✅ Application accessible via port 5000
- ⏳ Ready for deployment configuration