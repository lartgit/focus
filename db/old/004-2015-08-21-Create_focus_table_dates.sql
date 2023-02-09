
BEGIN;

CREATE TABLE public.dates
(
  id serial NOT NULL,
  set_id integer NOT NULL,
  date date NOT NULL,
  ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  created_at timestamp(6) without time zone NOT NULL DEFAULT now(),
  CONSTRAINT dates_pk PRIMARY KEY (id),
  CONSTRAINT dates_to_set_id_fkey FOREIGN KEY (set_id)
      REFERENCES pixel_sets (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE
);

COMMIT;
