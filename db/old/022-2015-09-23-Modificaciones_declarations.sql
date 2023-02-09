BEGIN;

ALTER TABLE public.declarations DROP COLUMN date_from;
ALTER TABLE public.declarations DROP COLUMN date_to;
ALTER TABLE public.declarations DROP COLUMN use_concrete_id;

CREATE TABLE public.declarations_concrete (
  id               serial NOT NULL PRIMARY KEY,
  ts               timestamp WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_at       timestamp WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  date_from        timestamp WITHOUT TIME ZONE,
  date_to          timestamp WITHOUT TIME ZONE,
  use_concrete_id  integer,
  declaration_id   integer NOT NULL,
  /* Foreign keys */
  CONSTRAINT declarations_concrete_to_use_concretes_fk
    FOREIGN KEY (use_concrete_id)
    REFERENCES public.use_concretes(id)
    ON DELETE CASCADE
    ON UPDATE NO ACTION
    DEFERRABLE
    INITIALLY IMMEDIATE,
  CONSTRAINT declarations_concrete_to_declarations_fk
    FOREIGN KEY (declaration_id)
    REFERENCES public.declarations(id)
    ON DELETE CASCADE
    ON UPDATE NO ACTION
) WITH (
    OIDS = FALSE
);



COMMIT;