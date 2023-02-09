
BEGIN;

ALTER TABLE public.process_regions DROP COLUMN set_id;
ALTER TABLE public.regions DROP COLUMN set_id;

COMMIT;
