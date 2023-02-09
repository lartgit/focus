-- ALTER TABLE public.process_results DROP COLUMN set_id;

TRUNCATE TABLE public.raster_files RESTART IDENTITY CASCADE;
ALTER TABLE public.raster_files ADD pixel_set_id int4 NULL;
ALTER TABLE public.raster_files ADD CONSTRAINT raster_files_pixel_set_id_fk FOREIGN KEY (pixel_set_id) REFERENCES pixel_sets(id) ON DELETE CASCADE;
ALTER TABLE public.raster_files DROP COLUMN image_type_id;

ALTER TABLE public.raster_files ALTER COLUMN pixel_set_id SET NOT NULL;
ALTER TABLE public.raster_files ALTER COLUMN group_id SET NOT NULL;

ALTER TABLE public.raster_layers ADD layer_path text NOT NULL;

ALTER TABLE public.process_images RENAME COLUMN procces_run TO process_run;

CREATE INDEX pixel_sets_imagen_type_id_idx ON public.pixel_sets (imagen_type_id);

ALTER TABLE public.process_results ALTER COLUMN "name" TYPE varchar(100) USING "name"::varchar;

UPDATE raster_layers SET image_date = image_date - INTERVAL '30 years' WHERE layer_type_id = (SELECT id FROM layer_types WHERE "name" = 'INPE_Mes_Promedio');

CREATE OR REPLACE FUNCTION focus_abs_diff(image_date date, query_date date)
 RETURNS int
 LANGUAGE plpgsql
AS $function$
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
$function$;
