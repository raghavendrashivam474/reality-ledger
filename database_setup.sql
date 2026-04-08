-- 🌌 EXECUTION OS : INFRASTRUCTURE LAYER
-- PASTE THIS INTO YOUR SUPABASE SQL EDITOR

-- 1. TASKS LEDGER
CREATE TABLE IF NOT EXISTS tasks (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) DEFAULT auth.uid(),
  title TEXT NOT NULL,
  estimated_minutes INTEGER DEFAULT 45,
  tag TEXT DEFAULT 'WORK',
  is_completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  difficulty INTEGER DEFAULT 1,
  is_non_negotiable BOOLEAN DEFAULT FALSE
);

-- 2. FOCUS SESSIONS
CREATE TABLE IF NOT EXISTS sessions (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) DEFAULT auth.uid(),
  task_id TEXT REFERENCES tasks(id) ON DELETE CASCADE,
  planned_duration_minutes INTEGER DEFAULT 45,
  actual_focus_minutes INTEGER DEFAULT 0,
  pause_count INTEGER DEFAULT 0,
  date TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  abandon_reason TEXT
);

-- 3. ENABLE ROW LEVEL SECURITY (RLS)
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;

-- 4. POLICIES (Users only see their own data)
CREATE POLICY "Tasks: User can view own tasks" ON tasks FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Tasks: User can insert own tasks" ON tasks FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Tasks: User can update own tasks" ON tasks FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Sessions: User can view own sessions" ON sessions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Sessions: User can insert own sessions" ON sessions FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 5. ANALYTICAL VIEWS (Optional)
-- You can add views here for weekly aggregation
