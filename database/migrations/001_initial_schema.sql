-- NFC Attendance Gamification Database Schema
-- 16 tables with proper relationships and RLS policies

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Profiles table (extended user profiles)
CREATE TABLE IF NOT EXISTS profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT,
    full_name TEXT,
    role TEXT NOT NULL CHECK (role IN ('student', 'admin', 'owner')),
    student_id TEXT UNIQUE,
    program TEXT,
    batch INTEGER,
    total_points INTEGER DEFAULT 0,
    current_level INTEGER DEFAULT 1,
    attendance_streak INTEGER DEFAULT 0,
    avatar_url TEXT,
    phone_number TEXT,
    is_email_verified BOOLEAN DEFAULT false,
    is_profile_complete BOOLEAN DEFAULT false,
    achievements TEXT[] DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. NFC Cards table
CREATE TABLE IF NOT EXISTS nfc_cards (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    uid TEXT NOT NULL UNIQUE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    card_type TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    registered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_used TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    usage_count INTEGER DEFAULT 0,
    notes TEXT,
    registered_by UUID REFERENCES profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Classes table
CREATE TABLE IF NOT EXISTS classes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    course_name TEXT NOT NULL,
    course_code TEXT NOT NULL,
    lecturer_name TEXT NOT NULL,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    room TEXT NOT NULL,
    points INTEGER DEFAULT 10,
    is_active BOOLEAN DEFAULT false,
    attendee_ids TEXT[] DEFAULT '{}',
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Attendance table
CREATE TABLE IF NOT EXISTS attendance (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    class_id UUID REFERENCES classes(id) ON DELETE SET NULL,
    check_in_time TIMESTAMP WITH TIME ZONE NOT NULL,
    points_earned INTEGER DEFAULT 10,
    check_in_method TEXT NOT NULL CHECK (check_in_method IN ('nfc', 'manual', 'qr')),
    was_late BOOLEAN DEFAULT false,
    nfc_card_id TEXT REFERENCES nfc_cards(uid),
    admin_id UUID REFERENCES profiles(id),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Points Transactions table
CREATE TABLE IF NOT EXISTS points_transactions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('attendance', 'event', 'redemption', 'bonus', 'penalty')),
    points INTEGER NOT NULL,
    description TEXT NOT NULL,
    reference_id UUID,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Achievements table
CREATE TABLE IF NOT EXISTS achievements (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('attendance', 'points', 'streak', 'event')),
    threshold INTEGER NOT NULL,
    icon TEXT NOT NULL,
    points_reward INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. User Achievements table (junction table)
CREATE TABLE IF NOT EXISTS user_achievements (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    achievement_id TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    icon TEXT NOT NULL,
    earned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_viewed BOOLEAN DEFAULT false,
    UNIQUE(user_id, achievement_id)
);

-- 8. Events table
CREATE TABLE IF NOT EXISTS events (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    type TEXT NOT NULL CHECK (type IN ('seminar', 'workshop', 'competition', 'other')),
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    location TEXT NOT NULL,
    points INTEGER DEFAULT 5,
    organizer_id UUID REFERENCES profiles(id),
    max_participants INTEGER,
    current_participants INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    check_in_method TEXT NOT NULL CHECK (check_in_method IN ('nfc', 'qr', 'manual')),
    qr_code_data TEXT,
    tags TEXT[] DEFAULT '{}',
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 9. Event Participation table
CREATE TABLE IF NOT EXISTS event_participation (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    event_id UUID REFERENCES events(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    check_in_time TIMESTAMP WITH TIME ZONE NOT NULL,
    points_earned INTEGER NOT NULL,
    check_in_method TEXT NOT NULL,
    notes TEXT,
    verified_by UUID REFERENCES profiles(id),
    UNIQUE(event_id, user_id)
);

-- 10. Merchandise table
CREATE TABLE IF NOT EXISTS merchandise (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL CHECK (category IN ('physical', 'voucher', 'privilege')),
    points_cost INTEGER NOT NULL,
    image_url TEXT,
    stock_quantity INTEGER,
    is_active BOOLEAN DEFAULT true,
    tags TEXT[] DEFAULT '{}',
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 11. Merchandise Orders table
CREATE TABLE IF NOT EXISTS merchandise_orders (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    merchandise_id UUID REFERENCES merchandise(id) ON DELETE CASCADE,
    points_cost INTEGER NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('pending', 'approved', 'fulfilled', 'cancelled')),
    ordered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    approved_at TIMESTAMP WITH TIME ZONE,
    fulfilled_at TIMESTAMP WITH TIME ZONE,
    cancelled_at TIMESTAMP WITH TIME ZONE,
    processed_by UUID REFERENCES profiles(id),
    notes TEXT,
    fulfillment_details JSONB
);

-- 12. Levels table
CREATE TABLE IF NOT EXISTS levels (
    level INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    min_points INTEGER NOT NULL,
    max_points INTEGER NOT NULL,
    badge TEXT NOT NULL,
    privileges TEXT[] DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 13. Notifications table
CREATE TABLE IF NOT EXISTS notifications (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('achievement', 'points', 'order', 'event', 'general')),
    is_read BOOLEAN DEFAULT false,
    image_url TEXT,
    data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 14. System Settings table
CREATE TABLE IF NOT EXISTS system_settings (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    key TEXT NOT NULL UNIQUE,
    value TEXT,
    description TEXT,
    data_type TEXT NOT NULL DEFAULT 'string' CHECK (data_type IN ('string', 'integer', 'boolean', 'json')),
    is_public BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 15. Audit Logs table
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    action TEXT NOT NULL,
    table_name TEXT,
    record_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address TEXT,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 16. App Sessions table (for tracking active sessions)
CREATE TABLE IF NOT EXISTS app_sessions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    session_token TEXT NOT NULL,
    device_info JSONB,
    ip_address TEXT,
    is_active BOOLEAN DEFAULT true,
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_student_id ON profiles(student_id);
CREATE INDEX IF NOT EXISTS idx_nfc_cards_uid ON nfc_cards(uid);
CREATE INDEX IF NOT EXISTS idx_nfc_cards_user_id ON nfc_cards(user_id);
CREATE INDEX IF NOT EXISTS idx_attendance_user_id ON attendance(user_id);
CREATE INDEX IF NOT EXISTS idx_attendance_check_in_time ON attendance(check_in_time);
CREATE INDEX IF NOT EXISTS idx_points_transactions_user_id ON points_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_points_transactions_type ON points_transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_events_start_time ON events(start_time);
CREATE INDEX IF NOT EXISTS idx_event_participation_user_id ON event_participation(user_id);
CREATE INDEX IF NOT EXISTS idx_merchandise_orders_user_id ON merchandise_orders(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at);

-- Insert default levels
INSERT INTO levels (level, name, min_points, max_points, badge, privileges) VALUES
(1, 'Beginner', 0, 99, '🌟', '{view_profile}'),
(2, 'Bronze', 100, 299, '🥉', '{view_profile, view_leaderboard}'),
(3, 'Silver', 300, 699, '🥈', '{view_profile, view_leaderboard, early_event_access}'),
(4, 'Gold', 700, 1499, '🥇', '{view_profile, view_leaderboard, early_event_access, premium_merchandise}'),
(5, 'Platinum', 1500, 2999, '💎', '{view_profile, view_leaderboard, early_event_access, premium_merchandise, priority_registration}'),
(6, 'Diamond', 3000, 999999999, '👑', '{view_profile, view_leaderboard, early_event_access, premium_merchandise, priority_registration, exclusive_events}')
ON CONFLICT (level) DO NOTHING;

-- Insert default achievements
INSERT INTO achievements (name, description, category, threshold, icon, points_reward) VALUES
('First Check-in', 'Complete your first attendance check-in', 'attendance', 1, '✅', 5),
('Week Warrior', 'Maintain a 7-day attendance streak', 'streak', 7, '🔥', 20),
('Monthly Champion', 'Maintain a 30-day attendance streak', 'streak', 30, '🏆', 50),
('Century Club', 'Earn 100 total points', 'points', 100, '💯', 25),
('Point Master', 'Earn 500 total points', 'points', 500, '🎯', 50),
('Point Legend', 'Earn 1000 total points', 'points', 1000, '👑', 100),
('Event Goer', 'Attend your first event', 'event', 1, '🎪', 10),
('Social Butterfly', 'Attend 10 events', 'event', 10, '🦋', 30),
('Perfect Attendance', 'Attend all classes in a month', 'attendance', 100, '📅', 75),
('Century Streak', 'Maintain a 100-day attendance streak', 'streak', 100, '💎', 200)
ON CONFLICT DO NOTHING;

-- Insert default system settings
INSERT INTO system_settings (key, value, description, data_type, is_public) VALUES
('app_version', '1.0.0', 'Current application version', 'string', true),
('default_attendance_points', '10', 'Default points awarded for attendance', 'integer', false),
('streak_bonus_multiplier', '2', 'Multiplier for streak bonuses', 'integer', false),
('perfect_attendance_bonus', '50', 'Bonus points for perfect attendance', 'integer', false),
('max_redemptions_per_month', '10', 'Maximum merchandise redemptions per user per month', 'integer', false),
('auto_approve_orders', 'false', 'Automatically approve merchandise orders below threshold', 'boolean', false)
ON CONFLICT (key) DO NOTHING;

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add triggers for updated_at columns
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_nfc_cards_updated_at BEFORE UPDATE ON nfc_cards FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_classes_updated_at BEFORE UPDATE ON classes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_events_updated_at BEFORE UPDATE ON events FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_merchandise_updated_at BEFORE UPDATE ON merchandise FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_system_settings_updated_at BEFORE UPDATE ON system_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Row Level Security (RLS) Policies
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE nfc_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE points_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_participation ENABLE ROW LEVEL SECURITY;
ALTER TABLE merchandise_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_sessions ENABLE ROW LEVEL SECURITY;

-- Profiles RLS Policies
CREATE POLICY "Users can view their own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Admins can view all student profiles" ON profiles FOR SELECT USING (auth.jwt() ->> 'role' = 'admin' AND role = 'student');
CREATE POLICY "Owners can view all profiles" ON profiles FOR SELECT USING (auth.jwt() ->> 'role' = 'owner');
CREATE POLICY "Users can update their own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Admins can update student profiles" ON profiles FOR UPDATE USING (auth.jwt() ->> 'role' = 'admin' AND role = 'student');
CREATE POLICY "Owners can update all profiles" ON profiles FOR UPDATE USING (auth.jwt() ->> 'role' = 'owner');

-- NFC Cards RLS Policies
CREATE POLICY "Users can view their own NFC cards" ON nfc_cards FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Admins can view all NFC cards" ON nfc_cards FOR SELECT USING (auth.jwt() ->> 'role' IN ('admin', 'owner'));
CREATE POLICY "Admins can manage NFC cards" ON nfc_cards FOR ALL USING (auth.jwt() ->> 'role' IN ('admin', 'owner'));

-- Attendance RLS Policies
CREATE POLICY "Users can view their own attendance" ON attendance FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Admins can view all attendance" ON attendance FOR SELECT USING (auth.jwt() ->> 'role' IN ('admin', 'owner'));
CREATE POLICY "Admins can manage attendance" ON attendance FOR ALL USING (auth.jwt() ->> 'role' IN ('admin', 'owner'));

-- Points Transactions RLS Policies
CREATE POLICY "Users can view their own transactions" ON points_transactions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Admins can view all transactions" ON points_transactions FOR SELECT USING (auth.jwt() ->> 'role' IN ('admin', 'owner'));
CREATE POLICY "System can create transactions" ON points_transactions FOR INSERT WITH CHECK (true);

-- User Achievements RLS Policies
CREATE POLICY "Users can view their own achievements" ON user_achievements FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Admins can view all achievements" ON user_achievements FOR SELECT USING (auth.jwt() ->> 'role' IN ('admin', 'owner'));
CREATE POLICY "System can create achievements" ON user_achievements FOR INSERT WITH CHECK (true);

-- Event Participation RLS Policies
CREATE POLICY "Users can view their own event participation" ON event_participation FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Admins can view all event participation" ON event_participation FOR SELECT USING (auth.jwt() ->> 'role' IN ('admin', 'owner'));
CREATE POLICY "Admins can manage event participation" ON event_participation FOR ALL USING (auth.jwt() ->> 'role' IN ('admin', 'owner'));

-- Merchandise Orders RLS Policies
CREATE POLICY "Users can view their own orders" ON merchandise_orders FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Admins can view all orders" ON merchandise_orders FOR SELECT USING (auth.jwt() ->> 'role' IN ('admin', 'owner'));
CREATE POLICY "Admins can manage orders" ON merchandise_orders FOR UPDATE USING (auth.jwt() ->> 'role' IN ('admin', 'owner'));
CREATE POLICY "System can create orders" ON merchandise_orders FOR INSERT WITH CHECK (true);

-- Notifications RLS Policies
CREATE POLICY "Users can view their own notifications" ON notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update their own notifications" ON notifications FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "System can create notifications" ON notifications FOR INSERT WITH CHECK (true);

-- Audit Logs RLS Policies
CREATE POLICY "Users can view their own audit logs" ON audit_logs FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Admins can view all audit logs" ON audit_logs FOR SELECT USING (auth.jwt() ->> 'role' IN ('admin', 'owner'));
CREATE POLICY "System can create audit logs" ON audit_logs FOR INSERT WITH CHECK (true);

-- App Sessions RLS Policies
CREATE POLICY "Users can view their own sessions" ON app_sessions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "System can manage sessions" ON app_sessions FOR ALL USING (true);

-- Public tables (no RLS needed)
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Everyone can view active achievements" ON achievements FOR SELECT USING (is_active = true);

ALTER TABLE levels ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Everyone can view levels" ON levels FOR SELECT USING (true);

ALTER TABLE classes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Everyone can view active classes" ON classes FOR SELECT USING (is_active = true);

ALTER TABLE events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Everyone can view active events" ON events FOR SELECT USING (is_active = true);

ALTER TABLE merchandise ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Everyone can view active merchandise" ON merchandise FOR SELECT USING (is_active = true);

ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Everyone can view public settings" ON system_settings FOR SELECT USING (is_public = true);
CREATE POLICY "Admins can view all settings" ON system_settings FOR SELECT USING (auth.jwt() ->> 'role' IN ('admin', 'owner'));
CREATE POLICY "Owners can manage settings" ON system_settings FOR ALL USING (auth.jwt() ->> 'role' = 'owner');