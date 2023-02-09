
BEGIN;

CREATE TABLE public.r2_rest_sessions (
  id           serial NOT NULL,
  user_id      integer NOT NULL,
  session_id   varchar(75) NOT NULL,
  ts           timestamp WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "timestamp"  bigint NOT NULL DEFAULT 0,
  /* Keys */
  CONSTRAINT r2_rest_sessions_pkey
    PRIMARY KEY (id),
  /* Foreign keys */
  CONSTRAINT r2_rest_session_to_users_fk
    FOREIGN KEY (user_id)
    REFERENCES public.users(id)
    ON DELETE CASCADE
    ON UPDATE NO ACTION
);

COMMIT;

