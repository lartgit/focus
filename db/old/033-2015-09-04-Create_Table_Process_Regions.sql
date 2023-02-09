BEGIN;
CREATE TABLE public.process_regions
(
  id serial NOT NULL,
  ts timestamp without time zone NOT NULL DEFAULT now(),
  created_at timestamp without time zone NOT NULL DEFAULT now(),
  start_process_at timestamp without time zone,
  end_process_at timestamp without time zone,
  path character varying(100),
  description character varying,
  set_id integer NOT NULL,
  CONSTRAINT process_regions_pkey PRIMARY KEY (id),
  CONSTRAINT process_regions_to_pixel_sets_fk FOREIGN KEY (set_id)
      REFERENCES pixel_sets (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.process_regions
  OWNER TO msoft;
COMMIT;