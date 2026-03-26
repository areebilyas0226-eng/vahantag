BEGIN;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS admin_users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(100) NOT NULL,
  phone VARCHAR(15) UNIQUE NOT NULL,
  phone_verified BOOLEAN DEFAULT FALSE,
  email VARCHAR(255),
  is_active BOOLEAN DEFAULT TRUE,
  last_login TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS agents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(100) NOT NULL,
  phone VARCHAR(15) UNIQUE NOT NULL,
  phone_verified BOOLEAN DEFAULT FALSE,
  email VARCHAR(255),
  city VARCHAR(100),
  state VARCHAR(100),
  address TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  is_approved BOOLEAN DEFAULT FALSE,
  total_tags_sold INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  phone VARCHAR(15) UNIQUE NOT NULL,
  phone_verified BOOLEAN DEFAULT FALSE,
  name VARCHAR(100),
  email VARCHAR(255),
  blood_group VARCHAR(5),
  medical_notes TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  referred_by_agent UUID,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS asset_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(100) NOT NULL,
  icon VARCHAR(10) NOT NULL,
  slug VARCHAR(50) UNIQUE NOT NULL,
  description TEXT,
  yearly_price_paisa INTEGER NOT NULL DEFAULT 49900,
  renewal_price_paisa INTEGER NOT NULL DEFAULT 29900,
  is_active BOOLEAN DEFAULT TRUE,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS qr_tags (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tag_code VARCHAR(20) UNIQUE NOT NULL,
  status VARCHAR(20) DEFAULT 'unactivated',
  batch_id VARCHAR(50),
  assigned_to_agent UUID,
  sold_to_user UUID,
  activated_at TIMESTAMP,
  expires_at TIMESTAMP,
  last_scanned_at TIMESTAMP,
  scan_count INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS assets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  tag_id UUID REFERENCES qr_tags(id),
  category_id UUID NOT NULL REFERENCES asset_categories(id),
  name VARCHAR(200) NOT NULL,
  description TEXT,
  photo_url TEXT,
  registration_number VARCHAR(20),
  make VARCHAR(100),
  model VARCHAR(100),
  year INTEGER,
  color VARCHAR(50),
  vehicle_type VARCHAR(30),
  pet_breed VARCHAR(100),
  serial_number VARCHAR(100),
  brand VARCHAR(100),
  additional_info JSONB DEFAULT '{}',
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS emergency_contacts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  asset_id UUID REFERENCES assets(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  phone VARCHAR(15) NOT NULL,
  relation VARCHAR(50),
  is_primary BOOLEAN DEFAULT FALSE,
  priority INTEGER DEFAULT 1,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id),
  tag_id UUID NOT NULL REFERENCES qr_tags(id),
  asset_id UUID REFERENCES assets(id),
  category_id UUID REFERENCES asset_categories(id),
  status VARCHAR(20) DEFAULT 'inactive',
  price_paisa INTEGER NOT NULL,
  starts_at TIMESTAMP,
  expires_at TIMESTAMP,
  is_renewal BOOLEAN DEFAULT FALSE,
  razorpay_order_id VARCHAR(100),
  razorpay_payment_id VARCHAR(100),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS payment_orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id),
  agent_id UUID REFERENCES agents(id),
  razorpay_order_id VARCHAR(100) UNIQUE,
  razorpay_payment_id VARCHAR(100),
  razorpay_signature VARCHAR(255),
  amount_paisa INTEGER NOT NULL,
  status VARCHAR(20) DEFAULT 'created',
  order_type VARCHAR(30) DEFAULT 'subscription',
  metadata JSONB DEFAULT '{}',
  paid_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS agent_inventory (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  agent_id UUID NOT NULL REFERENCES agents(id),
  tag_id UUID NOT NULL REFERENCES qr_tags(id),
  purchase_price_paisa INTEGER NOT NULL,
  status VARCHAR(20) DEFAULT 'in_stock',
  sold_at TIMESTAMP,
  sold_to_user UUID REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS scan_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tag_id UUID NOT NULL REFERENCES qr_tags(id),
  scanner_ip VARCHAR(45),
  scanner_user_agent TEXT,
  action_taken VARCHAR(50),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS call_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tag_id UUID REFERENCES qr_tags(id),
  caller_phone VARCHAR(15),
  twilio_call_sid VARCHAR(100),
  status VARCHAR(30),
  duration_seconds INTEGER,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION update_updated_at() RETURNS TRIGGER AS $func$ BEGIN NEW.updated_at = NOW(); RETURN NEW; END; $func$ language plpgsql;
CREATE TRIGGER t_agents BEFORE UPDATE ON agents FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER t_users BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER t_assets BEFORE UPDATE ON assets FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER t_tags BEFORE UPDATE ON qr_tags FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER t_subs BEFORE UPDATE ON subscriptions FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER t_cats BEFORE UPDATE ON asset_categories FOR EACH ROW EXECUTE FUNCTION update_updated_at();

COMMIT;
