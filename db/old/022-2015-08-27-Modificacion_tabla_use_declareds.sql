BEGIN;

ALTER TABLE use_declareds
   ADD COLUMN description character varying(200);

COMMIT;
