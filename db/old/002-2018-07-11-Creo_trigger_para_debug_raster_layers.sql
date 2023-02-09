BEGIN;

CREATE SCHEMA log;

 CREATE TABLE log.trigger_logs(
	id serial PRIMARY KEY,
	ts TIMESTAMP NOT NULL DEFAULT 'NOW()',
	activity text,
	tg_name text,
	new_data text,
	old_data text
);


CREATE OR REPLACE FUNCTION log.debug()
RETURNS trigger AS
$$
    BEGIN
        INSERT INTO log.trigger_logs (
				activity,
				tg_name,
				new_data,
				old_data
			) VALUES (
				(SELECT to_json(json_agg(pg_stat_activity)) FROM pg_stat_activity),
				TG_NAME,
				row_to_json(NEW),
				row_to_json(OLD)
			);
		RETURN NEW;
    END;
$$
LANGUAGE plpgsql;


 CREATE TRIGGER focus_raster_layers_debug_tg
 BEFORE UPDATE ON public.raster_layers
 FOR EACH ROW EXECUTE PROCEDURE log.debug();

COMMIT;
