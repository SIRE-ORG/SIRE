-- Alinea el enum ReservationStatus a minúsculas (lo que esperan Prisma, la
-- migración inicial 20260511 y el contrato del cliente Flutter).
--
-- Contexto: en la base de Supabase el enum quedó en MAYÚSCULAS
-- (PENDING, CANCELLED, ...) por una construcción fuera de banda respecto a la
-- migración commiteada. Eso hacía fallar TODO INSERT/UPDATE de `status` con
--   ERROR 22P02: invalid input value for enum "ReservationStatus": "pending"
-- y era la causa real del 500 en POST /reservations (H10).
--
-- Idempotente: solo renombra si la etiqueta en MAYÚSCULAS existe. Así es segura
-- tanto en la BD viva (MAYÚSCULAS -> renombra) como en una BD nueva creada desde
-- las migraciones (ya nace en minúsculas -> no hace nada). El DEFAULT de
-- reservations.status se actualiza solo al renombrar el valor.

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_enum e JOIN pg_type t ON t.oid = e.enumtypid
             WHERE t.typname = 'ReservationStatus' AND e.enumlabel = 'PENDING') THEN
    ALTER TYPE "ReservationStatus" RENAME VALUE 'PENDING' TO 'pending';
  END IF;

  IF EXISTS (SELECT 1 FROM pg_enum e JOIN pg_type t ON t.oid = e.enumtypid
             WHERE t.typname = 'ReservationStatus' AND e.enumlabel = 'CANCELLED') THEN
    ALTER TYPE "ReservationStatus" RENAME VALUE 'CANCELLED' TO 'cancelled';
  END IF;

  IF EXISTS (SELECT 1 FROM pg_enum e JOIN pg_type t ON t.oid = e.enumtypid
             WHERE t.typname = 'ReservationStatus' AND e.enumlabel = 'REJECTED') THEN
    ALTER TYPE "ReservationStatus" RENAME VALUE 'REJECTED' TO 'rejected';
  END IF;

  IF EXISTS (SELECT 1 FROM pg_enum e JOIN pg_type t ON t.oid = e.enumtypid
             WHERE t.typname = 'ReservationStatus' AND e.enumlabel = 'COMPLETED') THEN
    ALTER TYPE "ReservationStatus" RENAME VALUE 'COMPLETED' TO 'completed';
  END IF;

  IF EXISTS (SELECT 1 FROM pg_enum e JOIN pg_type t ON t.oid = e.enumtypid
             WHERE t.typname = 'ReservationStatus' AND e.enumlabel = 'FAILED') THEN
    ALTER TYPE "ReservationStatus" RENAME VALUE 'FAILED' TO 'failed';
  END IF;
END $$;
