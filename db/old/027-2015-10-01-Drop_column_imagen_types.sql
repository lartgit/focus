BEGIN;
ALTER TABLE public.imagen_types DROP COLUMN layer_name;
COMMIT;