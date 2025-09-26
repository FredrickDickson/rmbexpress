-- BuyRMBOnline Seed Data
-- Created: 2025-09-26
-- Description: Initial data for development and testing

-- =====================================================
-- DEMO USER ACCOUNTS
-- =====================================================

-- Note: These will be created via Supabase Auth, this is just for reference
-- Demo Admin: admin@buyrmbonline.com / password123
-- Demo User: user@buyrmbonline.com / password123

-- =====================================================
-- ADDITIONAL EXCHANGE RATES
-- =====================================================
INSERT INTO exchange_rates (from_currency, to_currency, rate, is_active) VALUES
    -- Major African currencies
    ('NGN', 'RMB', 0.0180),  -- Nigerian Naira
    ('KES', 'RMB', 0.0550),  -- Kenyan Shilling
    ('ZAR', 'RMB', 0.4200),  -- South African Rand
    
    -- Other major currencies
    ('CAD', 'RMB', 5.3500),  -- Canadian Dollar
    ('AUD', 'RMB', 4.8200),  -- Australian Dollar
    ('CHF', 'RMB', 8.1200),  -- Swiss Franc
    ('SEK', 'RMB', 0.6900),  -- Swedish Krona
    ('NOK', 'RMB', 0.6800),  -- Norwegian Krone
    ('DKK', 'RMB', 1.0500),  -- Danish Krone
    
    -- Crypto to RMB (for future implementation)
    ('BTC', 'RMB', 285000.00),  -- Bitcoin
    ('ETH', 'RMB', 18500.00),   -- Ethereum
    ('USDT', 'RMB', 7.20)       -- Tether
ON CONFLICT (from_currency, to_currency) DO UPDATE SET
    rate = EXCLUDED.rate,
    updated_at = NOW();

-- =====================================================
-- EXTENDED SYSTEM SETTINGS
-- =====================================================
INSERT INTO system_settings (key, value, description) VALUES
    -- Transaction limits by user tier
    ('tier_limits', '{
        "basic": {"daily": 5000, "monthly": 50000, "per_transaction": 1000},
        "verified": {"daily": 25000, "monthly": 250000, "per_transaction": 10000},
        "premium": {"daily": 100000, "monthly": 1000000, "per_transaction": 50000}
    }', 'Transaction limits by user verification tier'),
    
    -- KYC requirements
    ('kyc_requirements', '{
        "basic": ["email_verification"],
        "verified": ["email_verification", "phone_verification", "identity_document"],
        "premium": ["email_verification", "phone_verification", "identity_document", "address_verification", "income_verification"]
    }', 'KYC requirements for different user tiers'),
    
    -- Supported countries
    ('supported_countries', '[
        {"code": "GH", "name": "Ghana", "currency": "GHS", "enabled": true},
        {"code": "NG", "name": "Nigeria", "currency": "NGN", "enabled": true},
        {"code": "KE", "name": "Kenya", "currency": "KES", "enabled": true},
        {"code": "ZA", "name": "South Africa", "currency": "ZAR", "enabled": true},
        {"code": "US", "name": "United States", "currency": "USD", "enabled": true},
        {"code": "GB", "name": "United Kingdom", "currency": "GBP", "enabled": true},
        {"code": "EU", "name": "European Union", "currency": "EUR", "enabled": true},
        {"code": "JP", "name": "Japan", "currency": "JPY", "enabled": true}
    ]', 'List of supported countries and their currencies'),
    
    -- Mobile money providers
    ('mobile_money_providers', '{
        "GH": [
            {"name": "MTN Mobile Money", "code": "mtn_gh", "enabled": true},
            {"name": "Vodafone Cash", "code": "vodafone_gh", "enabled": true},
            {"name": "AirtelTigo Money", "code": "airteltigo_gh", "enabled": true}
        ],
        "NG": [
            {"name": "MTN Mobile Money", "code": "mtn_ng", "enabled": true},
            {"name": "Airtel Money", "code": "airtel_ng", "enabled": true},
            {"name": "9mobile Money", "code": "9mobile_ng", "enabled": false}
        ],
        "KE": [
            {"name": "M-Pesa", "code": "mpesa_ke", "enabled": true},
            {"name": "Airtel Money", "code": "airtel_ke", "enabled": true},
            {"name": "T-Kash", "code": "tkash_ke", "enabled": false}
        ]
    }', 'Mobile money providers by country'),
    
    -- Chinese transfer methods
    ('chinese_transfer_methods', '[
        {"name": "WeChat Pay", "code": "wechat", "enabled": true, "min_amount": 1, "max_amount": 50000, "processing_time": "5-15 minutes"},
        {"name": "Alipay", "code": "alipay", "enabled": true, "min_amount": 1, "max_amount": 50000, "processing_time": "5-15 minutes"},
        {"name": "Bank Transfer", "code": "bank_transfer", "enabled": true, "min_amount": 100, "max_amount": 500000, "processing_time": "10-30 minutes"},
        {"name": "UnionPay", "code": "unionpay", "enabled": false, "min_amount": 50, "max_amount": 100000, "processing_time": "15-45 minutes"}
    ]', 'Available transfer methods to China'),
    
    -- Fee structure
    ('fee_structure', '{
        "platform_fee": {
            "type": "percentage",
            "value": 2.5,
            "min": 2,
            "max": 50,
            "currency": "base"
        },
        "exchange_fee": {
            "type": "percentage", 
            "value": 1.0,
            "description": "Applied to exchange rate"
        },
        "processing_fee": {
            "type": "fixed_by_currency",
            "values": {"GHS": 5, "USD": 1, "EUR": 1, "GBP": 1, "JPY": 100, "NGN": 500, "KES": 150, "ZAR": 20}
        },
        "express_fee": {
            "type": "percentage",
            "value": 1.5,
            "description": "Additional fee for express processing (under 5 minutes)"
        }
    }', 'Detailed fee structure for all transaction types'),
    
    -- Rate refresh settings
    ('rate_refresh_settings', '{
        "auto_refresh": true,
        "refresh_interval_minutes": 30,
        "max_deviation_percentage": 2.5,
        "source_apis": ["exchangerate-api", "fixer-io", "currencylayer"],
        "business_hours_only": false
    }', 'Exchange rate refresh configuration'),
    
    -- Notification settings
    ('notification_settings', '{
        "email_notifications": {
            "transaction_created": true,
            "transaction_completed": true,
            "transaction_failed": true,
            "kyc_approved": true,
            "kyc_rejected": true,
            "daily_summary": false,
            "marketing": false
        },
        "sms_notifications": {
            "transaction_completed": true,
            "transaction_failed": true,
            "security_alerts": true
        },
        "push_notifications": {
            "transaction_updates": true,
            "rate_alerts": true,
            "promotional": false
        }
    }', 'Default notification preferences'),
    
    -- Security settings
    ('security_settings', '{
        "max_login_attempts": 5,
        "lockout_duration_minutes": 30,
        "session_timeout_minutes": 120,
        "require_2fa_for_large_transactions": true,
        "large_transaction_threshold": {"GHS": 10000, "USD": 2000, "EUR": 1800, "GBP": 1500},
        "ip_whitelist_enabled": false,
        "device_fingerprinting": true,
        "suspicious_activity_auto_freeze": true
    }', 'Security and fraud prevention settings'),
    
    -- Customer support
    ('support_settings', '{
        "business_hours": {
            "monday": {"start": "06:00", "end": "18:00", "enabled": true},
            "tuesday": {"start": "06:00", "end": "18:00", "enabled": true},
            "wednesday": {"start": "06:00", "end": "18:00", "enabled": true},
            "thursday": {"start": "06:00", "end": "18:00", "enabled": true},
            "friday": {"start": "06:00", "end": "18:00", "enabled": true},
            "saturday": {"start": "08:00", "end": "16:00", "enabled": true},
            "sunday": {"start": "10:00", "end": "14:00", "enabled": false}
        },
        "timezone": "GMT",
        "emergency_contact": "+233 508 341 200",
        "support_email": "support@buyrmbonline.com",
        "live_chat_enabled": true,
        "auto_response_enabled": true
    }', 'Customer support configuration'),
    
    -- API rate limits
    ('api_rate_limits', '{
        "public_endpoints": {"requests_per_minute": 60, "burst": 10},
        "authenticated_endpoints": {"requests_per_minute": 300, "burst": 50},
        "admin_endpoints": {"requests_per_minute": 1000, "burst": 100},
        "webhook_endpoints": {"requests_per_minute": 500, "burst": 100}
    }', 'API rate limiting configuration'),
    
    -- Maintenance windows
    ('maintenance_windows', '{
        "scheduled": [],
        "emergency_contacts": ["admin@buyrmbonline.com", "tech@buyrmbonline.com"],
        "status_page_url": "https://status.buyrmbonline.com",
        "notification_channels": ["email", "sms", "push", "dashboard_banner"]
    }', 'System maintenance configuration')
ON CONFLICT (key) DO UPDATE SET
    value = EXCLUDED.value,
    updated_at = NOW();

-- =====================================================
-- SAMPLE TRANSACTIONS (for development/demo)
-- =====================================================

-- Note: These would typically be created through the application
-- This is just for demo/testing purposes

DO $$
DECLARE
    demo_user_id UUID;
    demo_admin_id UUID;
BEGIN
    -- Create demo user profile (assuming auth user exists)
    -- In real scenario, this would be created by the trigger when user signs up
    INSERT INTO profiles (id, email, full_name, role, kyc_status) VALUES 
    ('550e8400-e29b-41d4-a716-446655440000', 'demo@buyrmbonline.com', 'Demo User', 'user', 'verified')
    ON CONFLICT (id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        role = EXCLUDED.role,
        kyc_status = EXCLUDED.kyc_status;
    
    demo_user_id := '550e8400-e29b-41d4-a716-446655440000';
    
    -- Sample completed transaction
    INSERT INTO transactions (
        user_id, reference_id, amount, from_currency, to_currency, 
        exchange_rate, status, payment_method, paystack_reference,
        recipient_details, transfer_method, platform_fee, exchange_fee, processing_fee,
        metadata, notes
    ) VALUES (
        demo_user_id,
        'TXN202509260001',
        1000.00,
        'GHS',
        'RMB',
        1.2500,
        'completed',
        'mobile_money',
        'paystack_ref_' || extract(epoch from now())::text,
        jsonb_build_object(
            'name', 'Zhang Wei',
            'phone', '+86 138 0013 8000',
            'id_number', '110101199001011234',
            'bank_name', 'Industrial and Commercial Bank of China',
            'account_number', '6222 0234 5678 9012'
        ),
        'wechat',
        25.00,
        12.50,
        5.00,
        jsonb_build_object(
            'user_agent', 'Mozilla/5.0 Demo Browser',
            'ip_address', '192.168.1.100',
            'device_id', 'demo_device_123'
        ),
        'Demo transaction for testing'
    );
    
    -- Sample pending transaction
    INSERT INTO transactions (
        user_id, reference_id, amount, from_currency, to_currency,
        exchange_rate, status, payment_method,
        recipient_details, transfer_method, platform_fee, exchange_fee, processing_fee
    ) VALUES (
        demo_user_id,
        'TXN202509260002', 
        500.00,
        'GHS',
        'RMB',
        1.2500,
        'pending_verification',
        'card',
        jsonb_build_object(
            'name', 'Li Ming',
            'phone', '+86 139 0013 9000',
            'alipay_account', 'li.ming@example.com'
        ),
        'alipay',
        12.50,
        6.25,
        5.00
    );

EXCEPTION WHEN OTHERS THEN
    -- Handle any errors (e.g., if demo user doesn't exist)
    RAISE NOTICE 'Sample data insertion failed: %', SQLERRM;
END $$;

-- =====================================================
-- SAMPLE NOTIFICATIONS
-- =====================================================

-- Create welcome notification for demo user
INSERT INTO notifications (user_id, type, title, message, data) VALUES 
(
    '550e8400-e29b-41d4-a716-446655440000',
    'welcome',
    'Welcome to BuyRMBOnline!',
    'Thank you for joining BuyRMBOnline. Your account has been verified and you can now start exchanging currencies.',
    jsonb_build_object(
        'action_url', '/dashboard',
        'action_text', 'Go to Dashboard'
    )
) ON CONFLICT DO NOTHING;

-- =====================================================
-- SAMPLE PAYSTACK CUSTOMER
-- =====================================================

INSERT INTO paystack_customers (
    user_id, paystack_customer_id, customer_code, email, first_name, last_name, phone
) VALUES (
    '550e8400-e29b-41d4-a716-446655440000',
    'cust_demo123456',
    'CUS_demo789012',
    'demo@buyrmbonline.com',
    'Demo',
    'User', 
    '+233501234567'
) ON CONFLICT (user_id) DO UPDATE SET
    email = EXCLUDED.email,
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    phone = EXCLUDED.phone;