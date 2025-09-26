-- BuyRMBOnline Initial Database Schema
-- Created: 2025-09-26
-- Description: Complete database schema supporting authentication, transactions, and Paystack integration

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- USER PROFILES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL UNIQUE,
    full_name VARCHAR(255),
    phone_number VARCHAR(20),
    address TEXT,
    role VARCHAR(20) DEFAULT 'user' CHECK (role IN ('user', 'admin', 'super_admin')),
    kyc_status VARCHAR(20) DEFAULT 'pending' CHECK (kyc_status IN ('pending', 'in_review', 'verified', 'rejected')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for profiles
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_kyc_status ON profiles(kyc_status);

-- =====================================================
-- EXCHANGE RATES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS exchange_rates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    from_currency VARCHAR(10) NOT NULL,
    to_currency VARCHAR(10) NOT NULL DEFAULT 'RMB',
    rate DECIMAL(10, 6) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(from_currency, to_currency)
);

-- Create indexes for exchange rates
CREATE INDEX IF NOT EXISTS idx_exchange_rates_currencies ON exchange_rates(from_currency, to_currency);
CREATE INDEX IF NOT EXISTS idx_exchange_rates_active ON exchange_rates(is_active);

-- =====================================================
-- TRANSACTIONS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    reference_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- Transaction Details
    amount DECIMAL(15, 2) NOT NULL,
    from_currency VARCHAR(10) NOT NULL,
    to_currency VARCHAR(10) NOT NULL DEFAULT 'RMB',
    exchange_rate DECIMAL(10, 6) NOT NULL,
    converted_amount DECIMAL(15, 2) GENERATED ALWAYS AS (amount * exchange_rate) STORED,
    
    -- Transaction Status and Processing
    status VARCHAR(30) DEFAULT 'pending' CHECK (status IN (
        'pending', 'pending_verification', 'processing', 
        'completed', 'failed', 'cancelled', 'refunded'
    )),
    payment_method VARCHAR(50),
    
    -- Paystack Integration
    paystack_reference VARCHAR(100),
    paystack_status VARCHAR(30),
    paystack_channel VARCHAR(30),
    paystack_paid_at TIMESTAMP WITH TIME ZONE,
    
    -- Recipient Details (JSON for flexibility)
    recipient_details JSONB,
    
    -- Transfer Details
    transfer_method VARCHAR(50), -- 'wechat', 'alipay', 'bank_transfer'
    transfer_reference VARCHAR(100),
    transfer_status VARCHAR(30),
    
    -- Fees and Charges
    platform_fee DECIMAL(10, 2) DEFAULT 0,
    exchange_fee DECIMAL(10, 2) DEFAULT 0,
    processing_fee DECIMAL(10, 2) DEFAULT 0,
    total_fees DECIMAL(10, 2) GENERATED ALWAYS AS (platform_fee + exchange_fee + processing_fee) STORED,
    
    -- Metadata and Notes
    metadata JSONB,
    notes TEXT,
    admin_notes TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Constraints
    CHECK (amount > 0),
    CHECK (exchange_rate > 0)
);

-- Create indexes for transactions
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_reference_id ON transactions(reference_id);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON transactions(status);
CREATE INDEX IF NOT EXISTS idx_transactions_paystack_reference ON transactions(paystack_reference);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_user_status ON transactions(user_id, status);

-- =====================================================
-- PAYMENT METHODS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS payment_methods (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    type VARCHAR(30) NOT NULL CHECK (type IN ('card', 'mobile_money', 'bank_account')),
    provider VARCHAR(50) NOT NULL, -- 'mtn_momo', 'vodafone_cash', 'visa', 'mastercard', etc.
    
    -- Encrypted payment details (stored as JSON)
    details JSONB NOT NULL,
    
    -- Display information
    display_name VARCHAR(100) NOT NULL,
    last_four VARCHAR(10),
    is_default BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for payment methods
CREATE INDEX IF NOT EXISTS idx_payment_methods_user_id ON payment_methods(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_methods_type ON payment_methods(type);
CREATE INDEX IF NOT EXISTS idx_payment_methods_default ON payment_methods(user_id, is_default) WHERE is_default = true;

-- =====================================================
-- NOTIFICATIONS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    data JSONB,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for notifications
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications(user_id, is_read) WHERE is_read = false;
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);

-- =====================================================
-- SYSTEM SETTINGS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS system_settings (
    key VARCHAR(100) PRIMARY KEY,
    value JSONB NOT NULL,
    description TEXT,
    updated_by UUID REFERENCES profiles(id),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- AUDIT LOG TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id),
    action VARCHAR(100) NOT NULL,
    table_name VARCHAR(50),
    record_id VARCHAR(100),
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for audit logs
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_logs_table_name ON audit_logs(table_name);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at DESC);

-- =====================================================
-- FUNCTIONS AND TRIGGERS
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at triggers to relevant tables
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_exchange_rates_updated_at
    BEFORE UPDATE ON exchange_rates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_transactions_updated_at
    BEFORE UPDATE ON transactions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payment_methods_updated_at
    BEFORE UPDATE ON payment_methods
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to automatically create user profile
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO profiles (id, email, full_name)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email)
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile when user signs up
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- =====================================================
-- INSERT INITIAL DATA
-- =====================================================

-- Insert default exchange rates
INSERT INTO exchange_rates (from_currency, to_currency, rate) VALUES
    ('GHS', 'RMB', 1.2500),
    ('USD', 'RMB', 7.2000),
    ('EUR', 'RMB', 7.8500),
    ('GBP', 'RMB', 9.1200),
    ('JPY', 'RMB', 0.0480)
ON CONFLICT (from_currency, to_currency) DO UPDATE SET
    rate = EXCLUDED.rate,
    updated_at = NOW();

-- Insert system settings
INSERT INTO system_settings (key, value, description) VALUES
    ('min_transaction_amount', '{"GHS": 50, "USD": 10, "EUR": 10, "GBP": 8, "JPY": 500}', 'Minimum transaction amounts by currency'),
    ('max_transaction_amount', '{"GHS": 500000, "USD": 100000, "EUR": 100000, "GBP": 80000, "JPY": 10000000}', 'Maximum transaction amounts by currency'),
    ('platform_fee_percentage', '2.5', 'Platform fee percentage'),
    ('exchange_fee_percentage', '1.0', 'Exchange rate fee percentage'),
    ('processing_fee_fixed', '{"GHS": 5, "USD": 1, "EUR": 1, "GBP": 1, "JPY": 100}', 'Fixed processing fees by currency'),
    ('rate_negotiation_threshold', '{"GHS": 50000, "USD": 10000, "EUR": 10000, "GBP": 8000, "JPY": 1000000}', 'Amounts above which rate negotiation is available'),
    ('supported_payment_methods', '["card", "mobile_money", "bank_transfer"]', 'Supported payment methods'),
    ('supported_transfer_methods', '["wechat", "alipay", "bank_transfer"]', 'Supported transfer methods to China'),
    ('business_hours', '{"start": "06:00", "end": "16:00", "timezone": "GMT"}', 'Business hours for customer support'),
    ('maintenance_mode', 'false', 'Whether the system is in maintenance mode')
ON CONFLICT (key) DO UPDATE SET
    value = EXCLUDED.value,
    updated_at = NOW();