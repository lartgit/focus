
BEGIN;


--solicitado: http://issues.monkeysoft.com.ar/issues/1855
--Aramirez

ALTER TABLE public.process_results
  DROP CONSTRAINT process_results_to_versions_id_fkey;
ALTER TABLE public.process_results
  ADD CONSTRAINT process_results_to_versions_id_fkey FOREIGN KEY (version_id) REFERENCES versions (id) ON UPDATE NO ACTION ON DELETE CASCADE;

COMMIT;

