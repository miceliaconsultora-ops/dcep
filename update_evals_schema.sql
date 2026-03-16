-- UPDATE EVALUATIONS SCHEMA
-- Run this in Supabase SQL Editor

DO $$ 
BEGIN 
  IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name='evaluations' AND column_name='attack_score') THEN
    ALTER TABLE public.evaluations ADD COLUMN attack_score integer;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name='evaluations' AND column_name='defense_score') THEN
    ALTER TABLE public.evaluations ADD COLUMN defense_score integer;
  END IF;
END $$;
