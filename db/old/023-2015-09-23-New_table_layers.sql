BEGIN;
DROP TABLE public.data_type_by_imagen_type;

CREATE TABLE public.layers
(
  id serial NOT NULL,
  name character varying(50) NOT NULL,
  imagen_type_id integer NOT NULL,
  data_type_id integer NOT NULL,
  ts timestamp without time zone NOT NULL DEFAULT now(),
  created_at timestamp without time zone NOT NULL DEFAULT now(), 
  CONSTRAINT data_type_by_imagen_type_pk PRIMARY KEY (id),
  CONSTRAINT data_type_by_imagen_type_to_data_types_id_fkey FOREIGN KEY (data_type_id)
      REFERENCES data_types (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT data_type_by_imagen_type_to_imagen_types_id_fkey FOREIGN KEY (imagen_type_id)
      REFERENCES imagen_types (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE
);
COMMIT;

