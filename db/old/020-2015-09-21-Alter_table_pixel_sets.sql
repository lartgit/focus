
BEGIN;

INSERT INTO public.imagen_types (id, "name") VALUES (-1, 'Invalid');
ALTER TABLE pixel_sets ADD COLUMN imagen_type_id integer NOT NULL DEFAULT -1;
ALTER TABLE pixel_sets ADD CONSTRAINT pixel_sets_to_imagen_types_id FOREIGN KEY (imagen_type_id) REFERENCES imagen_types (id)
   ON UPDATE NO ACTION ON DELETE CASCADE;

COMMIT;
