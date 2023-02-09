
BEGIN;


-- Table: raster_groups

CREATE TABLE raster_groups
(
  id serial NOT NULL,
  name character varying(50) NOT NULL,
  files_quantity integer,
  layers_quantity integer,
  created_at timestamp without time zone NOT NULL DEFAULT now(),
  ts timestamp without time zone NOT NULL DEFAULT now(),
  CONSTRAINT raster_groups_pk PRIMARY KEY (id)
);

CREATE TABLE public.raster_files
(
    id serial NOT NULL,
    ts timestamp without time zone DEFAULT now(),
    created_at timestamp without time zone DEFAULT now(),
    path character varying(250) NOT NULL,
    group_id integer,
    image_date date,
    image_type_id integer NOT NULL,
    CONSTRAINT raster_files_pk PRIMARY KEY (id),
    CONSTRAINT raster_files_image_type_id_fk FOREIGN KEY (image_type_id)
        REFERENCES imagen_types (id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION
);


CREATE TABLE public.raster_layers
(
  id serial NOT NULL,
  ts timestamp without time zone NOT NULL DEFAULT now(),
  created_at timestamp without time zone NOT NULL DEFAULT now(),
  layer_type_id integer NOT NULL,
  raster_file_id integer NOT NULL,
  image_date date,
  CONSTRAINT raster_layers_pk PRIMARY KEY (id),
  CONSTRAINT raster_layers_layer_type_id_fkey FOREIGN KEY (layer_type_id)
      REFERENCES layer_types (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT raster_layers_raster_file_id_fkey FOREIGN KEY (raster_file_id)
      REFERENCES raster_files (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE
);

CREATE TABLE public.process_images
(
  id serial NOT NULL,
  ts timestamp without time zone NOT NULL DEFAULT now(),
  created_at timestamp without time zone NOT NULL DEFAULT now(),
  start_process_at timestamp without time zone,
  end_process_at timestamp without time zone,
  description character varying,
  procces_run boolean DEFAULT false,
  raster_file_id integer,
  user_id integer,
  status character varying(20) NOT NULL DEFAULT 'pending',
  CONSTRAINT process_images_pkey PRIMARY KEY (id),
  CONSTRAINT process_images_raster_file_id_fk FOREIGN KEY (raster_file_id)
      REFERENCES raster_files (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT process_pixels_to_users_fk FOREIGN KEY (user_id)
      REFERENCES users (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE
);

COMMIT;
