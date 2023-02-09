
BEGIN;

CREATE TABLE public.db_actions_logs (
  id               serial NOT NULL PRIMARY KEY,
  ts               timestamp WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "action"         varchar(30) NOT NULL,
  user_id          integer,
  affected_entity  varchar(50) NOT NULL,
  full_query       text NOT NULL,
  description      text,
  /* Foreign keys */
  CONSTRAINT fk_db_actions_logs_to_users
    FOREIGN KEY (user_id)
    REFERENCES public.users(id)
    ON DELETE CASCADE
    ON UPDATE NO ACTION
) WITH (
    OIDS = FALSE
  );

COMMIT;
