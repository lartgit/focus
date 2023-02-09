BEGIN;
ALTER TABLE public.regions
   ADD COLUMN set_id integer NOT NULL;
ALTER TABLE public.regions
  ADD CONSTRAINT "Regions_to_pixel_sets" FOREIGN KEY (set_id)
      REFERENCES pixel_sets (id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE;
COMMIT;