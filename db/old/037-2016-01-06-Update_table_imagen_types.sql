
BEGIN;


--solicitado por lart 05-01-2016
--Aramirez
ALTER TABLE public.imagen_types
   ADD COLUMN pixel_size integer;


COMMIT;

