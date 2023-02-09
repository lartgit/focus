CREATE FUNCTION public.focus_abs_diff(image_date date, query_date date) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
var_new_date date;
BEGIN
	var_new_date := query_date;
	IF EXTRACT('YEAR' FROM image_date) = 1970
	THEN
		var_new_date := query_date - ((EXTRACT('YEAR' FROM query_date) - 1970) || ' years')::INTERVAL;
	END IF;

	IF ((image_date - var_new_date) < 0)
	THEN
		RETURN (var_new_date - image_date);
	ELSE
		RETURN (image_date - var_new_date);
	END IF;
END;
$$;

ALTER TABLE public.pixel_sets ADD COLUMN width integer;
ALTER TABLE public.pixel_sets ADD COLUMN height integer;

DROP VIEW public.processes_vw;

ALTER TABLE process_images ALTER COLUMN procces_run RENAME TO process_run;

ALTER TABLE public.process_pixels ALTER COLUMN set_id DROP NOT NULL;

ALTER TABLE process_results DROP COLUMN set_id;

ALTER TABLE public.process_results ALTER COLUMN "name" TYPE varchar(100) USING "name"::varchar;

CREATE VIEW public.processes_vw AS
 SELECT 'process_fields'::text AS process_class,
    process_fields.id,
    process_fields.ts,
    date_trunc('seconds'::text, process_fields.created_at) AS created_at,
    process_fields.start_process_at,
    process_fields.end_process_at,
    process_fields.description,
    process_fields.user_id,
    process_fields.procces_run
   FROM public.process_fields
UNION
 SELECT 'process_functions'::text AS process_class,
    process_functions.id,
    process_functions.ts,
    date_trunc('seconds'::text, process_functions.created_at) AS created_at,
    process_functions.start_process_at,
    process_functions.end_process_at,
    process_functions.description,
    process_functions.user_id,
    process_functions.procces_run
   FROM public.process_functions
UNION
 SELECT 'process_images'::text AS process_class,
    process_images.id,
    process_images.ts,
    date_trunc('seconds'::text, process_images.created_at) AS created_at,
    process_images.start_process_at,
    process_images.end_process_at,
    process_images.description,
    process_images.user_id,
    process_images.process_run AS procces_run
   FROM public.process_images
UNION
 SELECT 'process_pixels'::text AS process_class,
    process_pixels.id,
    process_pixels.ts,
    date_trunc('seconds'::text, process_pixels.created_at) AS created_at,
    process_pixels.start_process_at,
    process_pixels.end_process_at,
    process_pixels.description,
    process_pixels.user_id,
    process_pixels.procces_run
   FROM public.process_pixels
UNION
 SELECT 'process_regions'::text AS process_class,
    process_regions.id,
    process_regions.ts,
    date_trunc('seconds'::text, process_regions.created_at) AS created_at,
    process_regions.start_process_at,
    process_regions.end_process_at,
    process_regions.description,
    process_regions.user_id,
    process_regions.procces_run
   FROM public.process_regions
UNION
 SELECT 'process_results'::text AS process_class,
    process_results.id,
    process_results.ts,
    date_trunc('seconds'::text, process_results.created_at) AS created_at,
    process_results.start_process_at,
    process_results.end_process_at,
    process_results.description,
    process_results.user_id,
    process_results.procces_run
   FROM public.process_results;

ALTER TABLE raster_files ALTER COLUMN group_id RENAME TO image_type_id;
ALTER TABLE raster_files ALTER COLUMN image_type_id SET NOT NULL;
ALTER TABLE raster_files ALTER COLUMN image_type_id RENAME TO pixel_set_id;
ALTER TABLE ONLY public.raster_files ADD CONSTRAINT raster_files_pixel_set_id_fk FOREIGN KEY (pixel_set_id) REFERENCES public.pixel_sets(id) ON DELETE CASCADE;

ALTER TABLE raster_layers ADD COLUMN layer_path text NOT NULL;

CREATE INDEX pixel_sets_imagen_type_id_idx ON public.pixel_sets USING btree (imagen_type_id);
CREATE UNIQUE INDEX results_f2_process_result_id_process_focus_id_key_date_idx ON public.results_f2 USING btree (process_result_id, process_focus_id, key, date);
