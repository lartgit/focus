
BEGIN;

ALTER TABLE public.pixel_sets ALTER COLUMN active SET DEFAULT TRUE;
ALTER TABLE public.pixel_sets ALTER COLUMN active SET NOT NULL;

COMMIT;
