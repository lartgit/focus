/*paso las regiones y las borro*/
BEGIN;
DELETE FROM maps;
DELETE FROM db_actions_logs;

INSERT INTO maps (id,name,organization_id)
VALUES (1, 'Regiones Focus 1', '1');

INSERT INTO process_regions (id,start_process_at,end_process_at,description,procces_run,path)
VALUES (1,'2014-11-11 16:03:45','2014-11-11 17:03:45','Regiones de Focus 1',True,'/var/www/lart-focus/uploads/Regiones/v62_en_edicion.shp');

ALTER TABLE regions ADD COLUMN map_id integer;
UPDATE regions SET map_id = 1;
ALTER TABLE regions ALTER COLUMN map_id SET NOT NULL;

ALTER TABLE regions ADD COLUMN process_id integer;
UPDATE regions SET process_id = 1;

ALTER TABLE regions
  ADD CONSTRAINT regions_to_maps_id_fkey FOREIGN KEY (map_id) REFERENCES maps (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;
 
ALTER TABLE regions ALTER COLUMN process_id SET NOT NULL;
	  
UPDATE menu_options SET controller = 'regions' WHERE id = 63;
UPDATE menu_options SET name = 'Capas de Raster' WHERE id = 73;

ALTER TABLE regions
  ADD CONSTRAINT regions_to_maps_fk FOREIGN KEY (map_id)
      REFERENCES maps (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE process_regions ADD COLUMN map_id integer;
UPDATE process_regions SET map_id = 1;
ALTER TABLE process_regions ALTER COLUMN map_id SET NOT NULL;

ALTER TABLE process_regions ADD CONSTRAINT process_regions_to_maps_fk FOREIGN KEY (map_id) REFERENCES maps (id) ON UPDATE NO ACTION ON DELETE CASCADE;
CREATE INDEX fki_process_regions_to_maps_fk ON process_regions(map_id);

--Sequence de maps
SELECT nextval('maps_id_seq');

COMMIT;