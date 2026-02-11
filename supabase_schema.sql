-- SUPABASE SCHEMA - CHALLENGE SYSTEM

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Profiles table to store XP and level
-- This table should be synced with auth.users
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  username TEXT UNIQUE,
  first_name TEXT,
  last_name TEXT,
  gender TEXT,
  phone TEXT,
  university TEXT DEFAULT 'Université de Labé',
  license TEXT,
  department TEXT,
  avatar_url TEXT,
  xp INTEGER DEFAULT 0,
  level INTEGER DEFAULT 1,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Challenges table
CREATE TABLE IF NOT EXISTS public.challenges (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  instructions TEXT,
  difficulty TEXT CHECK (difficulty IN ('Easy', 'Medium', 'Hard', 'Expert')),
  xp_reward INTEGER DEFAULT 100,
  initial_code TEXT,
  test_cases JSONB NOT NULL, -- Array of {input: string, output: string}
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Challenge attempts / completions
CREATE TABLE IF NOT EXISTS public.challenge_attempts (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  challenge_id UUID REFERENCES public.challenges(id) ON DELETE CASCADE,
  code TEXT NOT NULL,
  status TEXT CHECK (status IN ('success', 'failed')),
  time_taken_ms INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS (Row Level Security) - Basic setup
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenge_attempts ENABLE ROW LEVEL SECURITY;

-- Profiles: Anyone can view, only owner can update
DROP POLICY IF EXISTS "Public profiles are viewable by everyone." ON public.profiles;
CREATE POLICY "Public profiles are viewable by everyone." ON public.profiles
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can update own profile." ON public.profiles;
CREATE POLICY "Users can update own profile." ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- Challenges: Anyone can view
DROP POLICY IF EXISTS "Challenges are viewable by everyone." ON public.challenges;
CREATE POLICY "Challenges are viewable by everyone." ON public.challenges
  FOR SELECT USING (true);

-- Challenge attempts: Users can only see their own attempts
DROP POLICY IF EXISTS "Users can view own attempts." ON public.challenge_attempts;
CREATE POLICY "Users can view own attempts." ON public.challenge_attempts
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own attempts." ON public.challenge_attempts;
CREATE POLICY "Users can insert own attempts." ON public.challenge_attempts
  FOR INSERT WITH CHECK (auth.uid() = user_id);
