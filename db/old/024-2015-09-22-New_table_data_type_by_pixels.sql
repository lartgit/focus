BEGIN;
CREATE TABLE public.data_types_by_pixels
(
  id serial NOT NULL,
  data_type_id integer NOT NULL,
  pixel_id integer NOT NULL,
  value double precision NOT NULL,
  ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  created_at timestamp(6) without time zone NOT NULL DEFAULT now(),
  CONSTRAINT data_by_pixels PRIMARY KEY (id),
  CONSTRAINT data_by_pixels_to_data_type_id_fkey FOREIGN KEY (data_type_id)
      REFERENCES data_types (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT data_by_pixels_to_pixeles_id_fkey FOREIGN KEY (pixel_id)
      REFERENCES pixel (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE
);
COMMIT;
