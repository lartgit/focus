
BEGIN;


--solicitado por lart 05-01-2016
--Aramirez
ALTER TABLE public.process_results
  DROP COLUMN date_id;

ALTER TABLE public.process_results
  ADD COLUMN data date;

COMMIT;

