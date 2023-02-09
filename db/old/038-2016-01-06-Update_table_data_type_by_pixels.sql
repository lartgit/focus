
BEGIN;


--solicitado por lart 05-01-2016
--Aramirez
ALTER TABLE public.data_types_by_pixels
   ADD COLUMN date date;


COMMIT;

