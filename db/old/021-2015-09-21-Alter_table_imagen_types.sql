
BEGIN;

ALTER TABLE imagen_types ADD COLUMN layer_name character varying(50) NOT NULL default 'Invalid';
ALTER TABLE imagen_types ALTER COLUMN layer_name DROP DEFAULT;

COMMIT;
