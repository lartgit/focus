
BEGIN;

ALTER TABLE public.raster_layers DROP CONSTRAINT raster_layers_raster_file_id_fkey;

ALTER TABLE public.raster_layers
  ADD CONSTRAINT raster_layers_raster_file_id_fkey FOREIGN KEY (raster_file_id)
      REFERENCES public.raster_files (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE SET NULL;

-- No, pero deberia ser asi
-- CREATE UNIQUE INDEX 
--     ON public.raster_layers (layer_type_id ASC NULLS LAST, image_date ASC NULLS LAST);

COMMIT;
