BEGIN;

CREATE INDEX pixel_values_raster_layer_idx
   ON public.pixel_values (raster_layer_id ASC NULLS LAST);

COMMIT;