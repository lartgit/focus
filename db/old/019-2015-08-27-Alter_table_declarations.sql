
BEGIN;

ALTER TABLE declarations
   ALTER COLUMN date DROP NOT NULL;

ALTER TABLE declarations
   ADD COLUMN date_from date;   

ALTER TABLE declarations
   ADD COLUMN date_to date;   

COMMIT;
