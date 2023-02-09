
DROP VIEW processes_vw;

ALTER TABLE process_functions ALTER COLUMN description TYPE character varying;

CREATE OR REPLACE VIEW processes_vw AS 
 SELECT 'process_fields'::text AS process_class,
    process_fields.id,
    process_fields.ts,
    date_trunc('seconds'::text, process_fields.created_at) AS created_at,
    process_fields.start_process_at,
    process_fields.end_process_at,
    process_fields.description,
    process_fields.user_id,
    process_fields.procces_run
   FROM process_fields
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
   FROM process_functions
UNION
 SELECT 'process_images'::text AS process_class,
    process_images.id,
    process_images.ts,
    date_trunc('seconds'::text, process_images.created_at) AS created_at,
    process_images.start_process_at,
    process_images.end_process_at,
    process_images.description,
    process_images.user_id,
    process_images.procces_run
   FROM process_images
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
   FROM process_pixels
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
   FROM process_regions
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
   FROM process_results;

ALTER TABLE results_f2 ADD COLUMN date timestamp without time zone;

DROP FUNCTION focus_upsert_result2(character varying, integer, integer, character varying);

CREATE OR REPLACE FUNCTION focus_upsert_result2(
    param_key character varying,
    param_process_result_id integer,
    param_process_focus_2_id integer,
    param_value character varying,
    param_date timestamp)
  RETURNS character varying AS
$BODY$
DECLARE
varId integer;
-- Esta funcion tiene como objetivo realizar el update o el insert de un resultado en focus 2
-- Si bien no es posible actualmente reiniar un proceso de resultado focus 2 lo podriamos utilzar para debug o en un futuro podriamos permitirlo.
BEGIN

    SELECT id into varId FROM results_f2 WHERE key = param_key AND process_result_id = param_process_result_id AND process_focus_id = param_process_focus_2_id AND "date" = param_date; 

    IF varId IS NULL THEN 
        INSERT INTO results_f2 (key, value, process_result_id, process_focus_id, "date") VALUES (param_key, param_value, param_process_result_id, param_process_focus_2_id, param_date );
        return 'Inserted';
    ELSE
        UPDATE results_f2 SET value = param_value WHERE id =  varId;
        return 'Updated';
    END IF;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;