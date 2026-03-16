-- SQL for DCEP Calendar System
-- Includes shifts and bookings tables with RLS

-- 1. Create Shifts Table
CREATE TABLE IF NOT EXISTS public.shifts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    max_players INTEGER NOT NULL DEFAULT 4,
    court_number INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT now(),
    created_by UUID REFERENCES auth.users(id)
);

-- 2. Create Bookings Table
CREATE TABLE IF NOT EXISTS public.bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shift_id UUID NOT NULL REFERENCES public.shifts(id) ON DELETE CASCADE,
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(shift_id, profile_id) -- Prevent duplicate bookings
);

-- 3. RLS Policies for Shifts
ALTER TABLE public.shifts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public shifts are viewable by everyone" 
ON public.shifts FOR SELECT USING (true);

CREATE POLICY "Admins can manage shifts" 
ON public.shifts FOR ALL TO authenticated 
USING (public.check_is_admin());

-- 4. RLS Policies for Bookings
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Bookings are viewable by authenticated users" 
ON public.bookings FOR SELECT TO authenticated USING (true);

CREATE POLICY "Users can manage their own bookings" 
ON public.bookings FOR ALL TO authenticated 
USING (profile_id = auth.uid()) 
WITH CHECK (profile_id = auth.uid());

CREATE POLICY "Admins can view and manage all bookings"
ON public.bookings FOR ALL TO authenticated
USING (public.check_is_admin());
