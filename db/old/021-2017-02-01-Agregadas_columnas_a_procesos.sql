
BEGIN;

ALTER TABLE process_regions ADD COLUMN user_id integer;
ALTER TABLE process_functions ADD COLUMN procces_run boolean DEFAULT false;

CREATE OR REPLACE VIEW public.processes_vw AS
SELECT 'process_fields'    AS process_class, id, ts, date_trunc('seconds', created_at) as created_at, start_process_at, end_process_at, description, user_id, procces_run FROM process_fields    UNION
SELECT 'process_functions' AS process_class, id, ts, date_trunc('seconds', created_at) as created_at, start_process_at, end_process_at, description, user_id, procces_run FROM process_functions UNION
SELECT 'process_images'    AS process_class, id, ts, date_trunc('seconds', created_at) as created_at, start_process_at, end_process_at, description, user_id, procces_run FROM process_images    UNION
SELECT 'process_pixels'    AS process_class, id, ts, date_trunc('seconds', created_at) as created_at, start_process_at, end_process_at, description, user_id, procces_run FROM process_pixels    UNION
SELECT 'process_regions'   AS process_class, id, ts, date_trunc('seconds', created_at) as created_at, start_process_at, end_process_at, description, user_id, procces_run FROM process_regions   UNION
SELECT 'process_results'   AS process_class, id, ts, date_trunc('seconds', created_at) as created_at, start_process_at, end_process_at, description, user_id, procces_run FROM process_results;

COMMIT;
