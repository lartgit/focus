
BEGIN;

CREATE TABLE public.regions
(
  id serial NOT NULL,
  name character varying(50) NOT NULL,
  the_geom polygon,
  ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  created_at timestamp(6) without time zone NOT NULL DEFAULT now(),
  CONSTRAINT regions_pk PRIMARY KEY (id)
);

COMMIT;
