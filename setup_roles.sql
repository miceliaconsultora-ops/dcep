-- FIXING RLS RECURSION AND ADDING PLAYER FIELDS
-- Run this in Supabase SQL Editor

-- 1. Create a security definer function to check admin status without recursion
CREATE OR REPLACE FUNCTION public.check_is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() AND is_admin = true
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Update Athletes Table Schema with Player Fields
DO $$ 
BEGIN 
  IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name='athletes' AND column_name='last_name') THEN
    ALTER TABLE public.athletes ADD COLUMN last_name text;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name='athletes' AND column_name='nickname') THEN
    ALTER TABLE public.athletes ADD COLUMN nickname text;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name='athletes' AND column_name='age') THEN
    ALTER TABLE public.athletes ADD COLUMN age integer;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name='athletes' AND column_name='height') THEN
    ALTER TABLE public.athletes ADD COLUMN height numeric;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name='athletes' AND column_name='weight') THEN
    ALTER TABLE public.athletes ADD COLUMN weight numeric;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name='athletes' AND column_name='position') THEN
    ALTER TABLE public.athletes ADD COLUMN position text; -- e.g. 'Drive', 'Revés'
  END IF;

  IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name='athletes' AND column_name='dominant_hand') THEN
    ALTER TABLE public.athletes ADD COLUMN dominant_hand text; -- e.g. 'Diestro', 'Zurdo'
  END IF;
END $$;

-- 3. Reset Policies to avoid recursion
DO $$
BEGIN
  -- PROFILES
  DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
  CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
  
  DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
  CREATE POLICY "Admins can view all profiles" ON public.profiles FOR SELECT USING (public.check_is_admin());

  -- ATHLETES
  DROP POLICY IF EXISTS "Public read athletes" ON public.athletes;
  CREATE POLICY "Public read athletes" ON public.athletes FOR SELECT USING (true);

  DROP POLICY IF EXISTS "Athletes can manage own profile" ON public.athletes;
  CREATE POLICY "Athletes can manage own profile" ON public.athletes FOR ALL TO authenticated 
    USING (profile_id = auth.uid()) 
    WITH CHECK (profile_id = auth.uid());

  DROP POLICY IF EXISTS "Admins can manage all athletes" ON public.athletes;
  CREATE POLICY "Admins can manage all athletes" ON public.athletes FOR ALL TO authenticated
    USING (public.check_is_admin());

  -- EVALUATIONS
  DROP POLICY IF EXISTS "Admin manage evaluations" ON public.evaluations;
  CREATE POLICY "Admin manage evaluations" ON public.evaluations FOR ALL TO authenticated
    USING (public.check_is_admin());

  DROP POLICY IF EXISTS "Athletes can view own evaluations" ON public.evaluations;
  CREATE POLICY "Athletes can view own evaluations" ON public.evaluations FOR SELECT TO authenticated
    USING (athlete_id IN (SELECT id FROM public.athletes WHERE profile_id = auth.uid()));

END
$$;
