
BEGIN;

ALTER TABLE public.pixel_selection_rules DROP COLUMN region_id;

COMMIT;
