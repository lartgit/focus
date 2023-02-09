
BEGIN;

ALTER TABLE public.regions DROP COLUMN the_geom;
ALTER TABLE public.regions ADD  COLUMN the_geom public.geometry;
CREATE INDEX regions_the_geom_idx ON public.regions USING gist (the_geom);

COMMIT;
