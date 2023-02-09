BEGIN;

CREATE TABLE public.format_types
(
  id serial,
  ts timestamp without time zone NOT NULL DEFAULT now(),
  created_at timestamp without time zone NOT NULL DEFAULT now(),
  name character varying(50),
  CONSTRAINT format_types_pk PRIMARY KEY (id)
);

INSERT INTO format_types (id, name) VALUES (1, 'String'), (2, 'Numeric');

ALTER TABLE public.parameter_types ADD COLUMN format_type_id integer NOT NULL DEFAULT 1;

ALTER TABLE public.parameter_types
  ADD CONSTRAINT parameter_types_to_format_types_fk FOREIGN KEY (format_type_id)
      REFERENCES public.format_types (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE;

COMMIT;