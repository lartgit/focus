BEGIN;

ALTER TABLE user_groups
   ADD COLUMN description character varying(200);

COMMIT;
