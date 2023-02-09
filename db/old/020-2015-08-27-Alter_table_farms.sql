
BEGIN;

ALTER TABLE farms
   ADD COLUMN code character varying(50) NOT NULL;

ALTER TABLE farms
  ADD CONSTRAINT farms_code UNIQUE (code);

COMMIT;
