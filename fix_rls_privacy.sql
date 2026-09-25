-- FIX RLS PRIVACY: cada atleta solo ve sus propios datos
-- Run this in Supabase SQL Editor
--
-- Problema: setup_database.sql creó "Allow public read" (using true) en athletes y
-- evaluations, y setup_roles.sql agregó "Public read athletes". Como las políticas RLS
-- se combinan con OR, cualquiera (incluso sin login, con la anon key) podía leer
-- todas las evaluaciones y todos los atletas.
--
-- Después de este script:
--   - Admin: lee/gestiona todo ("Admins can manage all athletes", "Admin manage evaluations")
--   - Atleta: solo su fila de athletes y sus propias evaluaciones
--   - Anónimo: nada

-- 1. Quitar lectura pública de athletes y evaluations
DROP POLICY IF EXISTS "Allow public read" ON public.evaluations;
DROP POLICY IF EXISTS "Allow public read" ON public.athletes;
DROP POLICY IF EXISTS "Public read athletes" ON public.athletes;

-- 1b. Política temporal de desarrollo: permitía leer/crear/editar/borrar a cualquiera (anon incluido)
DROP POLICY IF EXISTS "Enable all for all for now" ON public.evaluations;
DROP POLICY IF EXISTS "Enable all for all for now" ON public.athletes;

-- 1c. Redundantes con "Admins can manage all athletes" (quedaron creadas desde el panel)
DROP POLICY IF EXISTS "Admins can insert athletes" ON public.athletes;
DROP POLICY IF EXISTS "Admins can update athletes" ON public.athletes;

-- 2. Fijar search_path en la función SECURITY DEFINER (recomendación de Supabase)
CREATE OR REPLACE FUNCTION public.check_is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND is_admin = true
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 3. Verificación: listar las políticas que quedan activas
SELECT tablename, policyname, cmd, roles, qual, with_check
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
