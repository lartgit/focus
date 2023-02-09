    
BEGIN;

-- Table: maps

CREATE TABLE maps
(
  id serial,
  name character varying(20) NOT NULL,
  quantity integer,
  ts timestamp without time zone NOT NULL DEFAULT now(),
  created_at timestamp without time zone NOT NULL DEFAULT now(),
  organization_id integer NOT NULL,
  path character varying,
  CONSTRAINT map_pk PRIMARY KEY (id)
);


COMMIT;