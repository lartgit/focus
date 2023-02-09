BEGIN;

ALTER TABLE r2_rest_sessions ADD COLUMN last_communication timestamp without time zone;
ALTER TABLE r2_rest_sessions ADD COLUMN gcm_id varchar;

COMMIT;