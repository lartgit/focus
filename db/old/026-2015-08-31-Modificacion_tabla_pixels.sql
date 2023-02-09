
BEGIN;

ALTER TABLE public.pixel DROP COLUMN the_geom;

ALTER TABLE public.pixel ADD COLUMN the_geom public.geometry;

COMMIT;
