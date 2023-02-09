
BEGIN;

DROP INDEX public.pixel_values_pixel_id_raster_layer_id_idx;

CREATE UNIQUE INDEX pixel_values_pixel_id_raster_layer_id_idx
  ON public.pixel_values USING btree (pixel_id, raster_layer_id);

ALTER TABLE public.raster_layers ALTER COLUMN raster_file_id DROP NOT NULL;

CREATE SCHEMA tmp;

COMMIT;
