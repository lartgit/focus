BEGIN;

CREATE TABLE public.data_types
(
  id serial NOT NULL,
  name character varying(50) NOT NULL,
  unity character varying(50) NOT NULL,
  ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  created_at timestamp(6) without time zone NOT NULL DEFAULT now(),
  CONSTRAINT data_types_pk PRIMARY KEY (id)
);

COMMIT;
