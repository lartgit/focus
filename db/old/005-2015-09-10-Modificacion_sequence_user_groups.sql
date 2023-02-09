BEGIN;

ALTER SEQUENCE user_groups_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 2
  CACHE 1;
ALTER TABLE user_groups_id_seq
  OWNER TO msoft;

ALTER SEQUENCE user_groups_id_seq restart;

ALTER SEQUENCE groups_by_options_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 51
  CACHE 1;
ALTER TABLE groups_by_options_id_seq
  OWNER TO msoft;

ALTER SEQUENCE groups_by_options_id_seq restart;

ALTER SEQUENCE users_by_groups_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 2
  CACHE 1;
ALTER TABLE users_by_groups_id_seq
  OWNER TO msoft;

ALTER SEQUENCE users_by_groups_id_seq restart;

COMMIT;
