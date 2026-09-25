-- SISTEMA DE CRÉDITOS PARA TURNOS
-- Run this in Supabase SQL Editor (después de setup_calendar.sql)
--
-- Reglas:
--   - Cada reserva consume 1 crédito (también si la carga el admin).
--   - Los créditos se cargan en "lotes"; cada lote vence X días después de la recarga.
--     Se consume primero el lote que vence antes.
--   - Un atleta puede tener cupo libre (unlimited): reserva sin consumir créditos.
--   - El atleta puede bajarse hasta app_settings.cancel_hours antes del turno y recupera
--     el crédito. Pasado ese límite solo el admin puede sacarlo.
--   - El cupo del turno (max_players) y que el turno no haya empezado se validan acá,
--     no en el navegador.

-- 1. Configuración general (una sola fila)
CREATE TABLE IF NOT EXISTS public.app_settings (
    id INTEGER PRIMARY KEY DEFAULT 1 CHECK (id = 1),
    cancel_hours INTEGER NOT NULL DEFAULT 12 CHECK (cancel_hours >= 0),
    credit_validity_days INTEGER NOT NULL DEFAULT 30 CHECK (credit_validity_days > 0)
);
INSERT INTO public.app_settings (id) VALUES (1) ON CONFLICT (id) DO NOTHING;

-- 2. Cuenta de créditos por atleta (cupo libre)
CREATE TABLE IF NOT EXISTS public.credit_accounts (
    profile_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    unlimited BOOLEAN NOT NULL DEFAULT false,
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Lotes de créditos (cada recarga es un lote con su vencimiento)
CREATE TABLE IF NOT EXISTS public.credit_lots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    amount INTEGER NOT NULL CHECK (amount > 0),
    remaining INTEGER NOT NULL CHECK (remaining >= 0),
    expires_at TIMESTAMPTZ NOT NULL,
    note TEXT,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT now(),
    CHECK (remaining <= amount)
);
CREATE INDEX IF NOT EXISTS credit_lots_profile_idx ON public.credit_lots (profile_id, expires_at);

-- 4. Bookings: de qué lote salió el crédito y cuándo empieza el turno
--    (shift_start se guarda para poder devolver el crédito aunque se borre el turno)
ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS credit_lot_id UUID REFERENCES public.credit_lots(id) ON DELETE SET NULL;
ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS shift_start TIMESTAMPTZ;
UPDATE public.bookings b SET shift_start = s.start_time
FROM public.shifts s WHERE b.shift_id = s.id AND b.shift_start IS NULL;

-- 5. Saldo por atleta (respeta RLS de quien consulta: cada uno ve el suyo, el admin todos)
CREATE OR REPLACE VIEW public.credit_balances WITH (security_invoker = true) AS
SELECT
    p.id AS profile_id,
    COALESCE(ca.unlimited, false) AS unlimited,
    COALESCE(SUM(cl.remaining) FILTER (WHERE cl.expires_at > now()), 0)::INTEGER AS available,
    MIN(cl.expires_at) FILTER (WHERE cl.remaining > 0 AND cl.expires_at > now()) AS next_expiry
FROM public.profiles p
LEFT JOIN public.credit_accounts ca ON ca.profile_id = p.id
LEFT JOIN public.credit_lots cl ON cl.profile_id = p.id
GROUP BY p.id, ca.unlimited;

-- 6. RLS
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.credit_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.credit_lots ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Settings readable by authenticated" ON public.app_settings;
CREATE POLICY "Settings readable by authenticated" ON public.app_settings
    FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "Admins manage settings" ON public.app_settings;
CREATE POLICY "Admins manage settings" ON public.app_settings
    FOR ALL TO authenticated USING (public.check_is_admin()) WITH CHECK (public.check_is_admin());

DROP POLICY IF EXISTS "Users view own credit account" ON public.credit_accounts;
CREATE POLICY "Users view own credit account" ON public.credit_accounts
    FOR SELECT TO authenticated USING (profile_id = auth.uid());
DROP POLICY IF EXISTS "Admins manage credit accounts" ON public.credit_accounts;
CREATE POLICY "Admins manage credit accounts" ON public.credit_accounts
    FOR ALL TO authenticated USING (public.check_is_admin()) WITH CHECK (public.check_is_admin());

DROP POLICY IF EXISTS "Users view own credit lots" ON public.credit_lots;
CREATE POLICY "Users view own credit lots" ON public.credit_lots
    FOR SELECT TO authenticated USING (profile_id = auth.uid());
DROP POLICY IF EXISTS "Admins manage credit lots" ON public.credit_lots;
CREATE POLICY "Admins manage credit lots" ON public.credit_lots
    FOR ALL TO authenticated USING (public.check_is_admin()) WITH CHECK (public.check_is_admin());

-- Bookings: el atleta solo puede crear y borrar las suyas (no modificarlas)
DROP POLICY IF EXISTS "Users can manage their own bookings" ON public.bookings;
DROP POLICY IF EXISTS "Users can create own bookings" ON public.bookings;
CREATE POLICY "Users can create own bookings" ON public.bookings
    FOR INSERT TO authenticated WITH CHECK (profile_id = auth.uid());
DROP POLICY IF EXISTS "Users can delete own bookings" ON public.bookings;
CREATE POLICY "Users can delete own bookings" ON public.bookings
    FOR DELETE TO authenticated USING (profile_id = auth.uid());

-- 7. Reserva: valida turno y cupo, y consume un crédito
CREATE OR REPLACE FUNCTION public.booking_before_insert()
RETURNS trigger AS $$
DECLARE
    v_shift RECORD;
    v_booked INTEGER;
    v_unlimited BOOLEAN;
    v_lot_id UUID;
BEGIN
    -- Bloquea el turno para que dos reservas simultáneas no superen el cupo
    SELECT start_time, max_players INTO v_shift
    FROM public.shifts WHERE id = NEW.shift_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'El turno no existe.';
    END IF;

    IF v_shift.start_time <= now() AND NOT public.check_is_admin() THEN
        RAISE EXCEPTION 'Este turno ya comenzó.';
    END IF;

    SELECT count(*) INTO v_booked FROM public.bookings WHERE shift_id = NEW.shift_id;
    IF v_booked >= v_shift.max_players THEN
        RAISE EXCEPTION 'El turno está completo.';
    END IF;

    NEW.shift_start := v_shift.start_time;
    NEW.credit_lot_id := NULL;

    SELECT unlimited INTO v_unlimited FROM public.credit_accounts WHERE profile_id = NEW.profile_id;
    IF COALESCE(v_unlimited, false) THEN
        RETURN NEW;
    END IF;

    SELECT id INTO v_lot_id
    FROM public.credit_lots
    WHERE profile_id = NEW.profile_id AND remaining > 0 AND expires_at > now()
    ORDER BY expires_at, created_at
    LIMIT 1
    FOR UPDATE;

    IF v_lot_id IS NULL THEN
        RAISE EXCEPTION 'No hay créditos disponibles. Consultá con el coach para recargar.';
    END IF;

    UPDATE public.credit_lots SET remaining = remaining - 1 WHERE id = v_lot_id;
    NEW.credit_lot_id := v_lot_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS booking_before_insert ON public.bookings;
CREATE TRIGGER booking_before_insert
    BEFORE INSERT ON public.bookings
    FOR EACH ROW EXECUTE FUNCTION public.booking_before_insert();

-- 8. Cancelación: controla el límite de horas y devuelve el crédito
CREATE OR REPLACE FUNCTION public.booking_before_delete()
RETURNS trigger AS $$
DECLARE
    v_privileged BOOLEAN;
    v_cancel_hours INTEGER;
BEGIN
    -- Admin, o borrado del sistema (auth.uid() nulo: panel de Supabase, borrado de usuario)
    v_privileged := auth.uid() IS NULL OR public.check_is_admin();

    IF NOT v_privileged THEN
        SELECT cancel_hours INTO v_cancel_hours FROM public.app_settings WHERE id = 1;
        v_cancel_hours := COALESCE(v_cancel_hours, 12);
        IF OLD.shift_start IS NOT NULL
           AND OLD.shift_start <= now() + make_interval(hours => v_cancel_hours) THEN
            RAISE EXCEPTION 'Solo podés bajarte hasta % h antes del turno. Consultá con el coach.', v_cancel_hours;
        END IF;
    END IF;

    -- Devolver el crédito si el turno todavía no empezó
    IF OLD.credit_lot_id IS NOT NULL AND OLD.shift_start > now() THEN
        UPDATE public.credit_lots
        SET remaining = LEAST(remaining + 1, amount)
        WHERE id = OLD.credit_lot_id;
    END IF;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS booking_before_delete ON public.bookings;
CREATE TRIGGER booking_before_delete
    BEFORE DELETE ON public.bookings
    FOR EACH ROW EXECUTE FUNCTION public.booking_before_delete();

-- 9. Funciones para el admin (se llaman desde la app con supabase.rpc)
CREATE OR REPLACE FUNCTION public.admin_add_credits(
    p_profile_id UUID,
    p_amount INTEGER,
    p_valid_days INTEGER DEFAULT NULL,
    p_note TEXT DEFAULT NULL
)
RETURNS public.credit_lots AS $$
DECLARE
    v_days INTEGER;
    v_lot public.credit_lots;
BEGIN
    IF NOT public.check_is_admin() THEN
        RAISE EXCEPTION 'Solo el administrador puede cargar créditos.';
    END IF;
    IF p_amount IS NULL OR p_amount <= 0 THEN
        RAISE EXCEPTION 'La cantidad de créditos debe ser mayor a 0.';
    END IF;

    v_days := COALESCE(p_valid_days, (SELECT credit_validity_days FROM public.app_settings WHERE id = 1), 30);
    IF v_days <= 0 THEN
        RAISE EXCEPTION 'Los días de validez deben ser mayores a 0.';
    END IF;

    INSERT INTO public.credit_lots (profile_id, amount, remaining, expires_at, note, created_by)
    VALUES (p_profile_id, p_amount, p_amount, now() + make_interval(days => v_days), p_note, auth.uid())
    RETURNING * INTO v_lot;
    RETURN v_lot;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.admin_set_unlimited(p_profile_id UUID, p_unlimited BOOLEAN)
RETURNS void AS $$
BEGIN
    IF NOT public.check_is_admin() THEN
        RAISE EXCEPTION 'Solo el administrador puede modificar el cupo libre.';
    END IF;

    INSERT INTO public.credit_accounts (profile_id, unlimited, updated_at)
    VALUES (p_profile_id, p_unlimited, now())
    ON CONFLICT (profile_id) DO UPDATE SET unlimited = EXCLUDED.unlimited, updated_at = now();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE EXECUTE ON FUNCTION public.admin_add_credits(UUID, INTEGER, INTEGER, TEXT) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.admin_set_unlimited(UUID, BOOLEAN) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_add_credits(UUID, INTEGER, INTEGER, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_set_unlimited(UUID, BOOLEAN) TO authenticated;
