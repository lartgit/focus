
BEGIN;


--solicitado: http://issues.monkeysoft.com.ar/issues/1855
--Aramirez

ALTER TABLE public.process_results
  ADD COLUMN procces_run boolean DEFAULT false;

ALTER TABLE public.process_fields
  ADD COLUMN procces_run boolean DEFAULT false;

ALTER TABLE public.process_pixels
  ADD COLUMN procces_run boolean DEFAULT false;  

ALTER TABLE public.process_regions
  ADD COLUMN procces_run boolean DEFAULT false;    

COMMIT;

