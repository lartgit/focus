BEGIN;
-- Table: parameters
CREATE TABLE public.parameter_types
(
   id serial, 
   ts timestamp without time zone NOT NULL DEFAULT NOW(), 
   created_at timestamp without time zone NOT NULL DEFAULT now(), 
   name character varying(50),
   unit character varying(50),
   description character varying(250),
   quantity integer,
   CONSTRAINT parameter_types_pk PRIMARY KEY (id)
);

CREATE TABLE parameters
(
  id serial NOT NULL,
  ts timestamp without time zone NOT NULL DEFAULT now(),
  created_at timestamp without time zone NOT NULL DEFAULT now(),
  use_id integer,
  month integer,
  parameter_type_id integer NOT NULL,
  value character varying(50),
  map_id integer NOT NULL,
  region_id integer NOT NULL,
  priority integer NOT NULL,
  CONSTRAINT parameters_pk PRIMARY KEY (id),
  CONSTRAINT parameters_map_id_fk FOREIGN KEY (map_id)
      REFERENCES maps (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT parameters_parameter_type_id_fk FOREIGN KEY (parameter_type_id)
      REFERENCES parameter_types (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT parameters_region_id_fk FOREIGN KEY (region_id)
      REFERENCES regions (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT parameters_use_id_fk FOREIGN KEY (use_id)
      REFERENCES use_concretes (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE
);


CREATE TABLE layer_types
(
  id serial NOT NULL,
  name character varying(250) NOT NULL,
  image_type_id integer NOT NULL,
  parameter_type_id integer NOT NULL,
  ts timestamp without time zone NOT NULL DEFAULT now(),
  created_at timestamp without time zone NOT NULL DEFAULT now(),
  CONSTRAINT layer_type_pk PRIMARY KEY (id),
  CONSTRAINT layer_types_to_image_types_id_fkey FOREIGN KEY (image_type_id)
      REFERENCES imagen_types (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT layer_types_to_parameter_types_id_fkey FOREIGN KEY (parameter_type_id)
      REFERENCES parameter_types (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE
);
  
COMMIT;
