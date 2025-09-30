# BuyRMBOnline - Flutter Fintech App

A comprehensive Flutter web application for buying and sending Chinese Renminbi (RMB) online, inspired by the buy-rmb.com service. This fintech platform enables users in Ghana and other countries to exchange their local currency (primarily Ghana Cedi - GHS) for RMB and transfer funds to China via WeChat, Alipay, or Chinese bank accounts.

## 🚀 Features

### ✅ Completed Features
- **Complete Role-Based Authentication System** - Secure multi-tier authentication with:
  - Supabase integration for user management
  - Google OAuth and email/password authentication
  - Role-based access control (User, Admin, Super Admin)
  - Protected routes with automatic authentication verification
  - Real-time auth state monitoring and session management
- **Admin Dashboard & Management** - Complete administrative interface featuring:
  - Analytics dashboard with transaction insights and user metrics
  - User management with role assignment and KYC verification
  - Transaction oversight with approval workflows
  - System configuration and settings management
  - Financial reports and data analytics
- **Enhanced Security Implementation** - Production-ready security features:
  - Authentication-based user ID derivation preventing privilege escalation
  - Secure configuration with environment variables
  - Server-side timestamp handling and user data scoping
  - Memory leak fixes and improved session management
- **Dashboard with Real-time Data** - Balance overview, quick actions, recent transactions
- **Ghana Cedi (GHS) Support** - Primary currency with live exchange rates
- **Buy RMB Flow** - Complete currency exchange process with:
  - Real-time exchange rates (GHS ↔ RMB)
  - Multiple payment methods including Mobile Money (MOMO)
  - Transaction processing with progress indicators
  - Success confirmation dialogs
- **Mobile Money Integration** - "DIGITAL WALLET OR MOMO" payment option
- **Secure Paystack Payment Infrastructure** - Complete payment service foundation with:
  - PaystackService class with proper security practices
  - Environment-based API key management (no client-side secrets)
  - Database transaction recording with Paystack references
  - Secure payment flow ready for backend implementation
- **Currency Support** - GHS, USD, EUR, GBP, JPY with proper symbols (₵, $, €, £, ¥)
- **Responsive Design** - Professional fintech UI with Material 3 theming
- **Full Profile Management** - Complete user profile system with update capabilities
- **Role-Based UI Components** - Dynamic interface that adapts based on user permissions
- **Transaction Management** - Comprehensive transaction history and status tracking

### 🔄 In Development
- **QR Code Integration** - Alipay/WeChat QR code scanning and input
- **Advanced Transfer Limits** - ¥30 - ¥100,000 validation with rate negotiation
- **Payment Backend Implementation** - Server-side Paystack verification and webhook handling
- **Real-time Transfer Tracking** - Live status updates and receipt generation

## 🏗️ Architecture

### Tech Stack
- **Frontend**: Flutter 3.32.0 (Web)
- **Language**: Dart 3.8.1
- **Backend**: Supabase (PostgreSQL, Authentication, Real-time)
- **Payment Processing**: Paystack integration with paystack_for_flutter SDK
- **State Management**: Riverpod
- **Routing**: GoRouter with role-based route protection
- **UI Framework**: Material 3 with custom role-based components
- **Authentication**: Supabase Auth with Google OAuth support
- **Database**: PostgreSQL with Row Level Security (RLS)
- **Development Server**: Port 5000

### Project Structure
```
lib/
├── core/
│   ├── models/          # Data models (User, Transaction, ExchangeRate)
│   ├── providers/       # Riverpod state providers
│   ├── router/         # Navigation routing with authentication guards
│   ├── services/       # Supabase, Paystack, and admin services
│   ├── theme/          # App theming and styles
│   └── widgets/        # Role-based UI components
├── screens/
│   ├── auth/           # Login, registration, and authentication shells
│   ├── dashboard/      # Main dashboard with role-based features
│   ├── buy_rmb/        # Currency exchange flow
│   ├── profile/        # Complete user profile management
│   ├── wallet/         # Wallet and balance management
│   ├── transaction_history/  # Transaction lists and history
│   └── admin/          # Complete admin dashboard suite
├── widgets/            # Reusable UI components
└── main.dart          # App entry point with Supabase initialization
```

## 🎯 Buy-RMB.com Service Implementation

Based on the buy-rmb.com workflow, our app implements the complete 4-step process:

### 1. Select Transaction Type
- Primary focus on "Buy RMB" for transferring funds to China
- Support for business payments (suppliers) and personal transfers

### 2. Enter Recipient and Transfer Details
- **Recipient Information**: Name, contact details, preferred receiving method
- **Transfer Methods**: WeChat, Alipay, Chinese bank accounts
- **Transfer Limits**: ¥30 minimum, ¥100,000 maximum per transaction
- **Purpose Specification**: Payment type and transaction notes

### 3. Review and Pay GHS Equivalent
- **Live Exchange Rates**: Real-time GHS to RMB conversion
- **Transparent Fees**: Clear breakdown of costs and charges
- **Payment Methods**: 
  - Mobile Money (MTN MoMo, Vodafone Cash)
  - Credit/Debit Cards
  - Bank Transfer
- **Rate Negotiation**: Available for transfers >¥10,000

### 4. Transfer Processing and Receipt
- **Fast Processing**: Target 5-30 minutes transfer time
- **Real-time Tracking**: Live status updates
- **Digital Receipts**: Transaction confirmation with ID
- **Customer Support**: Contact options and issue resolution

## 🚦 Getting Started

### Prerequisites
- Flutter SDK 3.32.0 or higher
- Dart SDK 3.8.1 or higher
- Web browser (Chrome/Edge recommended for development)

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/FredrickDickson/rmbexpress.git
   cd rmbexpress
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure environment variables for Supabase and Paystack integration:
   
   **For Replit Environment:**
   - Environment variables are automatically configured through the Replit secrets manager
   - The application reads from: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `PAYSTACK_PUBLIC_KEY`
   
   **For Local Development:**
   - Copy `.env.example` to `.env`
   - Update the values in `.env` with your actual keys
   - The workflow automatically loads these variables

4. Run the web application:
   ```bash
   # In Replit - uses configured environment variables automatically
   flutter run -d web-server --web-hostname 0.0.0.0 --web-port 5000 --release
   
   # For local development with environment variables
   flutter run -d web-server --web-hostname 0.0.0.0 --web-port 5000 --release \
     --dart-define=SUPABASE_URL=$SUPABASE_URL \
     --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
     --dart-define=PAYSTACK_PUBLIC_KEY=$PAYSTACK_PUBLIC_KEY
   ```

5. Open your browser and navigate to `http://localhost:5000`

### Admin Access Setup
To test admin features:
1. Register a new user account
2. Update the user's role in the database:
   ```sql
   UPDATE profiles 
   SET role = 'admin', kyc_status = 'verified' 
   WHERE email = 'your-email@example.com';
   ```
3. Access admin dashboard at `/admin`

### Development Setup
The app is configured to run in the Replit environment with:
- Hot reload enabled for rapid development
- Web server binding to all hosts (0.0.0.0:5000) for proxy compatibility
- Automatic dependency management

## 📊 Exchange Rates & Currencies

### Supported Currencies
- **GHS** (Ghana Cedi) - Primary currency, default selection
- **USD** (US Dollar) - Secondary option
- **EUR** (Euro) - European market support
- **GBP** (British Pound) - UK market support
- **JPY** (Japanese Yen) - Asian market support

### Rate Management
- Real-time rate simulation with fluctuations
- Rate refresh capability
- Historical rate tracking
- Negotiation system for high-value transfers (>¥10,000)

## 🔒 Security & Compliance

### Current Security Features
- **Complete Role-Based Access Control** - Multi-tier user permissions (User, Admin, Super Admin)
- **Supabase Authentication** - Enterprise-grade auth with Google OAuth integration
- **Protected Routes** - Authentication guards on all user and admin routes
- **Secure User ID Derivation** - Prevention of horizontal privilege escalation
- **Environment-Based Configuration** - Secure secret management with server-side keys
- **Secure Payment Infrastructure** - Paystack integration with no client-side secrets
- **Real-time Auth State Monitoring** - Automatic logout on session expiry
- **Memory Leak Prevention** - Proper cleanup of authentication listeners
- **Form Validation** - Comprehensive input sanitization and validation
- **Database Security** - PostgreSQL with Row Level Security policies

### Planned Security Enhancements
- **Enhanced KYC Verification** - Extended identity verification workflows
- **Biometric Authentication** - Fingerprint and face recognition support
- **Transaction PINs** - Additional security layer for financial operations
- **Device Registration** - Multi-factor authentication and fraud detection
- **AML Compliance** - Anti-Money Laundering monitoring and reporting
- **Advanced Encryption** - End-to-end encryption for sensitive data

## 🎨 UI/UX Design

### Design Principles
- **Professional Fintech Aesthetic** - Clean, trustworthy interface
- **Material 3 Guidelines** - Modern Android/Web design patterns
- **Accessibility** - Screen reader support and keyboard navigation
- **Responsive Layout** - Optimized for various screen sizes
- **Color Scheme** - Green-based financial theme with high contrast

### User Experience Flow
1. **Onboarding** - Simple login/registration process
2. **Dashboard** - Quick overview of balance and recent activity
3. **Buy RMB** - Streamlined currency exchange process
4. **Transaction Tracking** - Clear status updates and confirmations
5. **Support Integration** - Easy access to help and customer service

## 🤝 Contributing

### Development Guidelines
1. Follow Flutter best practices and conventions
2. Use Riverpod for state management
3. Implement proper error handling and validation
4. Write clear, self-documenting code
5. Test thoroughly before submitting changes

### Contribution Process
1. Fork the repository
2. Create a feature branch
3. Make your changes with proper testing
4. Submit a pull request with clear description
5. Ensure all checks pass

## 🐛 Known Issues & Limitations

### Current Limitations
- Development environment setup required for Supabase
- Web-only deployment (mobile apps planned)
- Payment processing requires backend implementation for live transactions
- Row Level Security policies need production configuration
- Admin features require manual database role assignment

### Bug Reports
Please report bugs by creating an issue in the GitHub repository with:
- Detailed description of the problem
- Steps to reproduce
- Expected vs actual behavior
- Browser/environment information

## 📈 Roadmap

### Phase 1: Core Enhancement (Completed ✅)
- [x] Complete Role-Based Authentication System
- [x] Admin Dashboard & Management Suite
- [x] Comprehensive User Profile Management
- [x] Security Hardening & Bug Fixes
- [x] Secure Paystack Payment Infrastructure Foundation
- [ ] QR Code Integration (Alipay/WeChat)
- [ ] Transfer Limits & Validation
- [ ] Rate Negotiation System

### Phase 2: Platform Enhancement (Current)
- [ ] Production Supabase RLS Policies
- [ ] Backend Payment Processing & Verification
- [ ] Paystack Webhook Integration
- [ ] Advanced KYC Verification Workflows
- [ ] Real-time Transfer Tracking
- [ ] Enhanced Transaction Management

### Phase 3: Production Readiness
- [ ] Mobile App Development
- [ ] Advanced Analytics & Reporting
- [ ] Performance Optimization
- [ ] Compliance & Regulatory Features
- [ ] Multi-language Support

## 📞 Support & Contact

### Development Team
- **Repository**: [https://github.com/FredrickDickson/rmbexpress](https://github.com/FredrickDickson/rmbexpress)
- **Issues**: Report bugs and feature requests via GitHub Issues
- **Discussions**: Use GitHub Discussions for questions and ideas


## 📄 License

This project is developed for educational and demonstration purposes. Please ensure compliance with financial regulations in your jurisdiction before production use.

---

**Last Updated**: September 30, 2025  
**Version**: 1.3.0-beta  
**Flutter Version**: 3.32.0  
**Supabase Integration**: ✅ Complete  
**Paystack Integration**: ✅ Infrastructure Complete  
**Status**: Secure Payment Foundation Ready - Backend Implementation Pending
