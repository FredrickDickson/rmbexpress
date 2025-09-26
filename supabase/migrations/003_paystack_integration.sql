-- BuyRMBOnline Paystack Integration Enhancements
-- Created: 2025-09-26
-- Description: Additional tables and functions specifically for Paystack payment processing

-- =====================================================
-- PAYSTACK WEBHOOKS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS paystack_webhooks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_type VARCHAR(100) NOT NULL,
    paystack_id VARCHAR(100) NOT NULL,
    reference VARCHAR(100),
    status VARCHAR(50),
    amount DECIMAL(15, 2),
    currency VARCHAR(10),
    customer_email VARCHAR(255),
    channel VARCHAR(50),
    paid_at TIMESTAMP WITH TIME ZONE,
    
    -- Raw webhook data
    raw_data JSONB NOT NULL,
    
    -- Processing status
    processed BOOLEAN DEFAULT false,
    processed_at TIMESTAMP WITH TIME ZONE,
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    
    -- Metadata
    ip_address INET,
    signature_verified BOOLEAN DEFAULT false,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for paystack webhooks
CREATE INDEX IF NOT EXISTS idx_paystack_webhooks_reference ON paystack_webhooks(reference);
CREATE INDEX IF NOT EXISTS idx_paystack_webhooks_paystack_id ON paystack_webhooks(paystack_id);
CREATE INDEX IF NOT EXISTS idx_paystack_webhooks_event_type ON paystack_webhooks(event_type);
CREATE INDEX IF NOT EXISTS idx_paystack_webhooks_processed ON paystack_webhooks(processed);
CREATE INDEX IF NOT EXISTS idx_paystack_webhooks_created_at ON paystack_webhooks(created_at DESC);

-- =====================================================
-- PAYSTACK CUSTOMERS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS paystack_customers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    paystack_customer_id VARCHAR(100) NOT NULL UNIQUE,
    customer_code VARCHAR(100) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    
    -- Customer metadata from Paystack
    metadata JSONB,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    UNIQUE(user_id)
);

-- Create indexes for paystack customers
CREATE INDEX IF NOT EXISTS idx_paystack_customers_user_id ON paystack_customers(user_id);
CREATE INDEX IF NOT EXISTS idx_paystack_customers_email ON paystack_customers(email);
CREATE INDEX IF NOT EXISTS idx_paystack_customers_customer_code ON paystack_customers(customer_code);

-- =====================================================
-- PAYSTACK PAYMENT ATTEMPTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS paystack_payment_attempts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_id UUID NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
    paystack_reference VARCHAR(100) NOT NULL,
    
    -- Payment details
    amount DECIMAL(15, 2) NOT NULL,
    currency VARCHAR(10) NOT NULL,
    channel VARCHAR(50), -- card, bank, ussd, qr, mobile_money, bank_transfer, etc.
    status VARCHAR(50) NOT NULL, -- pending, success, failed, abandoned, etc.
    
    -- Paystack response data
    gateway_response TEXT,
    paystack_response JSONB,
    
    -- Customer information
    customer_email VARCHAR(255),
    customer_name VARCHAR(255),
    
    -- Authorization details (for card payments)
    authorization_code VARCHAR(100),
    card_type VARCHAR(50),
    last4 VARCHAR(10),
    exp_month VARCHAR(5),
    exp_year VARCHAR(10),
    bin VARCHAR(10),
    bank VARCHAR(100),
    
    -- Fees
    paystack_fee DECIMAL(10, 2),
    
    -- Timestamps
    initiated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    paid_at TIMESTAMP WITH TIME ZONE,
    failed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for payment attempts
CREATE INDEX IF NOT EXISTS idx_payment_attempts_transaction_id ON paystack_payment_attempts(transaction_id);
CREATE INDEX IF NOT EXISTS idx_payment_attempts_reference ON paystack_payment_attempts(paystack_reference);
CREATE INDEX IF NOT EXISTS idx_payment_attempts_status ON paystack_payment_attempts(status);
CREATE INDEX IF NOT EXISTS idx_payment_attempts_created_at ON paystack_payment_attempts(created_at DESC);

-- =====================================================
-- ENHANCED TRANSACTION TRIGGERS
-- =====================================================

-- Function to handle transaction status updates
CREATE OR REPLACE FUNCTION handle_transaction_status_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Log the status change
    PERFORM log_user_action(
        'transaction_status_changed',
        'transactions',
        NEW.id::TEXT,
        jsonb_build_object('status', OLD.status),
        jsonb_build_object('status', NEW.status)
    );
    
    -- Update completed_at timestamp when transaction is completed
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        NEW.completed_at = NOW();
    END IF;
    
    -- Create notification for user on status change
    IF NEW.status != OLD.status THEN
        INSERT INTO notifications (user_id, type, title, message, data)
        VALUES (
            NEW.user_id,
            'transaction_status_update',
            'Transaction Status Updated',
            format('Your transaction %s is now %s', NEW.reference_id, NEW.status),
            jsonb_build_object(
                'transaction_id', NEW.id,
                'old_status', OLD.status,
                'new_status', NEW.status,
                'amount', NEW.amount,
                'currency', NEW.from_currency
            )
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for transaction status changes
CREATE TRIGGER transaction_status_change_trigger
    BEFORE UPDATE ON transactions
    FOR EACH ROW
    WHEN (OLD.status IS DISTINCT FROM NEW.status)
    EXECUTE FUNCTION handle_transaction_status_change();

-- =====================================================
-- PAYSTACK WEBHOOK PROCESSING FUNCTIONS
-- =====================================================

-- Function to process paystack webhook
CREATE OR REPLACE FUNCTION process_paystack_webhook(
    webhook_data JSONB,
    webhook_signature TEXT DEFAULT NULL,
    source_ip INET DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    webhook_id UUID;
    event_type TEXT;
    paystack_reference TEXT;
    transaction_record RECORD;
    payment_data JSONB;
BEGIN
    -- Extract event data
    event_type := webhook_data->>'event';
    
    -- Handle different event types
    CASE event_type
        WHEN 'charge.success' THEN
            payment_data := webhook_data->'data';
            paystack_reference := payment_data->>'reference';
            
            -- Insert webhook record
            INSERT INTO paystack_webhooks (
                event_type, paystack_id, reference, status, amount, currency,
                customer_email, channel, paid_at, raw_data, ip_address, signature_verified
            ) VALUES (
                event_type,
                payment_data->>'id',
                paystack_reference,
                payment_data->>'status',
                (payment_data->>'amount')::DECIMAL / 100, -- Convert from kobo
                payment_data->>'currency',
                payment_data->'customer'->>'email',
                payment_data->>'channel',
                to_timestamp((payment_data->>'paid_at')::BIGINT),
                webhook_data,
                source_ip,
                webhook_signature IS NOT NULL
            ) RETURNING id INTO webhook_id;
            
            -- Update transaction status
            UPDATE transactions 
            SET 
                status = 'completed',
                paystack_status = payment_data->>'status',
                paystack_channel = payment_data->>'channel',
                paystack_paid_at = to_timestamp((payment_data->>'paid_at')::BIGINT),
                updated_at = NOW()
            WHERE paystack_reference = paystack_reference;
            
            -- Record payment attempt
            INSERT INTO paystack_payment_attempts (
                transaction_id, paystack_reference, amount, currency, channel, status,
                gateway_response, paystack_response, customer_email, paystack_fee, paid_at
            ) 
            SELECT 
                t.id, paystack_reference, 
                (payment_data->>'amount')::DECIMAL / 100,
                payment_data->>'currency',
                payment_data->>'channel',
                payment_data->>'status',
                payment_data->>'gateway_response',
                payment_data,
                payment_data->'customer'->>'email',
                COALESCE((payment_data->'fees'->0->>'amount')::DECIMAL / 100, 0),
                to_timestamp((payment_data->>'paid_at')::BIGINT)
            FROM transactions t 
            WHERE t.paystack_reference = paystack_reference;
            
        WHEN 'charge.failed' THEN
            payment_data := webhook_data->'data';
            paystack_reference := payment_data->>'reference';
            
            -- Insert webhook record
            INSERT INTO paystack_webhooks (
                event_type, paystack_id, reference, status, amount, currency,
                customer_email, channel, raw_data, ip_address, signature_verified
            ) VALUES (
                event_type,
                payment_data->>'id',
                paystack_reference,
                payment_data->>'status',
                (payment_data->>'amount')::DECIMAL / 100,
                payment_data->>'currency',
                payment_data->'customer'->>'email',
                payment_data->>'channel',
                webhook_data,
                source_ip,
                webhook_signature IS NOT NULL
            ) RETURNING id INTO webhook_id;
            
            -- Update transaction status
            UPDATE transactions 
            SET 
                status = 'failed',
                paystack_status = payment_data->>'status',
                paystack_channel = payment_data->>'channel',
                updated_at = NOW()
            WHERE paystack_reference = paystack_reference;
            
            -- Record failed payment attempt
            INSERT INTO paystack_payment_attempts (
                transaction_id, paystack_reference, amount, currency, channel, status,
                gateway_response, paystack_response, customer_email, failed_at
            ) 
            SELECT 
                t.id, paystack_reference,
                (payment_data->>'amount')::DECIMAL / 100,
                payment_data->>'currency',
                payment_data->>'channel',
                payment_data->>'status',
                payment_data->>'gateway_response',
                payment_data,
                payment_data->'customer'->>'email',
                NOW()
            FROM transactions t 
            WHERE t.paystack_reference = paystack_reference;
            
        ELSE
            -- Handle other webhook events
            INSERT INTO paystack_webhooks (
                event_type, raw_data, ip_address, signature_verified
            ) VALUES (
                event_type, webhook_data, source_ip, webhook_signature IS NOT NULL
            ) RETURNING id INTO webhook_id;
    END CASE;
    
    -- Mark webhook as processed
    UPDATE paystack_webhooks 
    SET processed = true, processed_at = NOW() 
    WHERE id = webhook_id;
    
    RETURN webhook_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- PAYSTACK INTEGRATION VIEWS
-- =====================================================

-- View for transaction summary with payment details
CREATE OR REPLACE VIEW transaction_summary AS
SELECT 
    t.*,
    p.full_name as customer_name,
    p.email as customer_email,
    p.phone_number as customer_phone,
    pa.channel as payment_channel,
    pa.card_type,
    pa.last4,
    pa.bank as payment_bank,
    pa.paystack_fee,
    pa.authorization_code
FROM transactions t
LEFT JOIN profiles p ON t.user_id = p.id
LEFT JOIN paystack_payment_attempts pa ON t.id = pa.transaction_id AND pa.status = 'success';

-- View for daily transaction analytics
CREATE OR REPLACE VIEW daily_transaction_analytics AS
SELECT 
    DATE(created_at) as transaction_date,
    COUNT(*) as total_transactions,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_transactions,
    COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed_transactions,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_transactions,
    SUM(CASE WHEN status = 'completed' THEN amount ELSE 0 END) as total_volume,
    SUM(CASE WHEN status = 'completed' THEN total_fees ELSE 0 END) as total_fees,
    AVG(CASE WHEN status = 'completed' THEN amount END) as avg_transaction_amount,
    COUNT(DISTINCT user_id) as unique_customers
FROM transactions
GROUP BY DATE(created_at)
ORDER BY transaction_date DESC;

-- =====================================================
-- ENABLE RLS FOR NEW TABLES
-- =====================================================

ALTER TABLE paystack_webhooks ENABLE ROW LEVEL SECURITY;
ALTER TABLE paystack_customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE paystack_payment_attempts ENABLE ROW LEVEL SECURITY;

-- Policies for paystack tables (admin access only)
CREATE POLICY "Admins can view paystack webhooks" ON paystack_webhooks
    FOR SELECT USING (user_has_any_role(ARRAY['admin', 'super_admin']));

CREATE POLICY "System can insert paystack webhooks" ON paystack_webhooks
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Admins can view paystack customers" ON paystack_customers
    FOR SELECT USING (user_has_any_role(ARRAY['admin', 'super_admin']));

CREATE POLICY "Users can view own paystack customer" ON paystack_customers
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Admins can view payment attempts" ON paystack_payment_attempts
    FOR SELECT USING (user_has_any_role(ARRAY['admin', 'super_admin']));

CREATE POLICY "Users can view own payment attempts" ON paystack_payment_attempts
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM transactions t 
            WHERE t.id = transaction_id AND t.user_id = auth.uid()
        )
    );