
BEGIN;

ALTER TABLE public.fields DROP COLUMN the_geom;
ALTER TABLE public.fields ADD COLUMN the_geom public.geometry;

COMMIT;
