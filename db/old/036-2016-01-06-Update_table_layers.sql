
BEGIN;


--solicitado por lart 05-01-2016
--Aramirez
ALTER TABLE public.data_types
   ADD COLUMN duration integer;


COMMIT;

