BEGIN;
ALTER TABLE pixel_selection_rules ADD COLUMN name character varying(50) NOT NULL;
ALTER TABLE pixel_selection_rules ADD COLUMN tolerance integer NOT NULL;
COMMIT;