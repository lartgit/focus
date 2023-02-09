
BEGIN;

CREATE TABLE public.process_pixels (
  id                serial NOT NULL,
  ts                timestamp WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_at        timestamp WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  start_process_at  timestamp WITHOUT TIME ZONE,
  end_process_at    timestamp WITHOUT TIME ZONE,
  description       varchar,
  "path"            varchar(100),
  set_id            integer NOT NULL,
  /* Keys */
  CONSTRAINT process_pixels_pkey
    PRIMARY KEY (id),
  /* Foreign keys */
  CONSTRAINT process_pixels_to_pixel_sets_fk
    FOREIGN KEY (set_id)
    REFERENCES public.pixel_sets(id)
    ON DELETE CASCADE
    ON UPDATE NO ACTION
);

COMMIT;
