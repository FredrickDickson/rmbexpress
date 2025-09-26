#!/bin/bash

# Environment Setup Script for BuyRMBOnline
# This script helps configure environment variables for local development

echo "🔧 BuyRMBOnline Environment Setup"
echo "=================================="

# Check if .env.example exists
if [ ! -f ".env.example" ]; then
    echo "❌ .env.example file not found"
    exit 1
fi

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo "📝 Creating .env file from .env.example..."
    cp .env.example .env
    echo "✅ .env file created successfully"
    echo ""
    echo "🔑 Please update the following values in your .env file:"
    echo "   - SUPABASE_URL: Your Supabase project URL"
    echo "   - SUPABASE_ANON_KEY: Your Supabase anonymous key"
    echo "   - PAYSTACK_PUBLIC_KEY: Your Paystack public key"
    echo "   - PAYSTACK_SECRET_KEY: Your Paystack secret key"
    echo ""
    echo "📖 You can find these values in:"
    echo "   - Supabase: https://app.supabase.com/project/[your-project]/settings/api"
    echo "   - Paystack: https://dashboard.paystack.com/#/settings/developer"
else
    echo "✅ .env file already exists"
fi

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    echo "   Please install Flutter: https://docs.flutter.dev/get-started/install"
    exit 1
fi

echo "✅ Flutter is installed"

# Check Flutter dependencies
echo "📦 Checking Flutter dependencies..."
flutter pub get

echo ""
echo "🚀 Environment setup complete!"
echo "   Run: flutter run -d web-server --web-hostname 0.0.0.0 --web-port 5000"
echo "   Or use the Replit Run button"