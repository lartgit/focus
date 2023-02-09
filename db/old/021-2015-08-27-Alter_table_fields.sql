BEGIN;

ALTER TABLE fields
   ADD COLUMN code character varying(50) NOT NULL;

ALTER TABLE fields
  ADD CONSTRAINT farm_field_code UNIQUE(farm_id, code);

COMMIT;
