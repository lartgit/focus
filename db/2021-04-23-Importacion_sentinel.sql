ALTER TABLE public.process_pixels ALTER COLUMN set_id DROP NOT NULL;

ALTER TABLE public.raster_files ALTER COLUMN pixel_set_id DROP NOT NULL;

ALTER TABLE public.raster_files RENAME COLUMN group_id TO image_type_id;

--UPDATE raster_files SET image_type_id = (
--    SELECT it.id 
--    FROM raster_files rf 
--    JOIN raster_groups rg ON rg.id = rf.image_type_id
--    LEFT JOIN imagen_types it ON it.name = rg.name
--    WHERE rf.id = raster_files.id
--)

ALTER TABLE public.raster_files ADD CONSTRAINT raster_files_image_type_id_fk FOREIGN KEY (image_type_id) REFERENCES public.imagen_types(id) ON DELETE CASCADE;

ALTER TABLE public.pixel_sets ADD width int4 NULL;
ALTER TABLE public.pixel_sets ADD height int4 NULL;

UPDATE pixel_sets SET width=4800, height=4800 WHERE "name"='h13v12';
UPDATE pixel_sets SET width=4800, height=4800 WHERE "name"='h12v12';
UPDATE pixel_sets SET width=4800, height=4800 WHERE "name"='h12v13';
UPDATE pixel_sets SET width=4800, height=4800 WHERE "name"='h12v11';
UPDATE pixel_sets SET width=4800, height=4800 WHERE "name"='h13v13';
UPDATE pixel_sets SET width=4800, height=4800 WHERE "name"='h13v14';
UPDATE pixel_sets SET width=4800, height=4800 WHERE "name"='h13v11';
UPDATE pixel_sets SET width=4800, height=4800 WHERE "name"='h11v11';
UPDATE pixel_sets SET width=4800, height=4800 WHERE "name"='h14v14';
UPDATE pixel_sets SET width=2030, height=1991 WHERE "name"='inpe';
UPDATE pixel_sets SET width=10980, height=10980 WHERE "name"='21HTC';

CREATE UNIQUE INDEX results_f2_process_result_id_process_focus_id_key_date_idx ON public.results_f2 USING btree (process_result_id, process_focus_id, key, date)
