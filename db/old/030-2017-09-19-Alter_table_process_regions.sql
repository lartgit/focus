BEGIN;
ALTER TABLE public.process_regions
  DROP CONSTRAINT process_regions_to_maps_fk;
ALTER TABLE public.process_regions
  ADD CONSTRAINT process_regions_to_maps_fk FOREIGN KEY (map_id) REFERENCES maps (id) ON UPDATE NO ACTION ON DELETE CASCADE;
COMMIT;