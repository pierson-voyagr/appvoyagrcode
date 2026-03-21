-- Voyagr Database Schema for Supabase
-- Run this in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table (extends Supabase auth.users)
CREATE TABLE public.users (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  birthday TIMESTAMPTZ,
  bio TEXT,
  interests TEXT[] DEFAULT '{}',
  tags TEXT[] DEFAULT '{}',

  -- Preferences
  min_age INTEGER DEFAULT 18,
  max_age INTEGER DEFAULT 80,
  gender_preference TEXT DEFAULT 'No Pref',

  -- Verification data (ComplyCube)
  complycube_client_id TEXT,
  complycube_document_ids TEXT[] DEFAULT '{}',
  complycube_live_photo_ids TEXT[] DEFAULT '{}',
  liveness_verified BOOLEAN DEFAULT FALSE,
  liveness_verified_at TIMESTAMPTZ,
  is_verified BOOLEAN DEFAULT FALSE,
  verification_status TEXT, -- 'pending', 'approved', 'rejected'
  verification_started_at TIMESTAMPTZ,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- RLS Policies for users table
-- Users can read their own data
CREATE POLICY "Users can read own data"
  ON public.users
  FOR SELECT
  USING (auth.uid() = id);

-- Users can update their own data
CREATE POLICY "Users can update own data"
  ON public.users
  FOR UPDATE
  USING (auth.uid() = id);

-- Users can insert their own data
CREATE POLICY "Users can insert own data"
  ON public.users
  FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add trigger to automatically update updated_at
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trips table (if needed for future use)
CREATE TABLE public.trips (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  country TEXT NOT NULL,
  city TEXT NOT NULL,
  date_type TEXT NOT NULL, -- 'unknown', 'month', 'specific'
  month TEXT,
  year INTEGER,
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  reason_for_trip TEXT, -- 'Study Abroad', 'Work', 'Vacation'
  requested_location TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for trips
ALTER TABLE public.trips ENABLE ROW LEVEL SECURITY;

-- RLS Policies for trips table
CREATE POLICY "Users can read own trips"
  ON public.trips
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own trips"
  ON public.trips
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own trips"
  ON public.trips
  FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own trips"
  ON public.trips
  FOR DELETE
  USING (auth.uid() = user_id);

-- Add trigger for trips updated_at
CREATE TRIGGER update_trips_updated_at
  BEFORE UPDATE ON public.trips
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Create indexes for better query performance
CREATE INDEX idx_users_email ON public.users(email);
CREATE INDEX idx_users_verification_status ON public.users(verification_status);
CREATE INDEX idx_trips_user_id ON public.trips(user_id);
CREATE INDEX idx_trips_country_city ON public.trips(country, city);
