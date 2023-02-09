BEGIN;

ALTER TABLE users
   ADD COLUMN password_sent_at timestamp without time zone;

COMMIT;