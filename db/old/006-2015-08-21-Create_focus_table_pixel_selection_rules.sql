
BEGIN;

CREATE TABLE public.pixel_selection_rules
(
  id serial NOT NULL,
  region_id integer NOT NULL,
  ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  created_at timestamp(6) without time zone NOT NULL DEFAULT now(),
  CONSTRAINT pixel_selection_rules_pk PRIMARY KEY (id),
    CONSTRAINT pixel_selection_rules_to_region_id_fkey FOREIGN KEY (region_id)
      REFERENCES regions (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE
);

COMMIT;
