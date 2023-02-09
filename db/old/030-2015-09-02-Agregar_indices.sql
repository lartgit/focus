
BEGIN;

CREATE INDEX fields_the_geom_idx ON public.fields USING GIST (the_geom);

CREATE INDEX pixel_the_geom_idx ON public.pixel USING GIST (the_geom);

COMMIT;
