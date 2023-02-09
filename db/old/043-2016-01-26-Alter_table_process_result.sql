BEGIN;


--Aramirez
ALTER TABLE public.process_results
  ADD COLUMN client_id integer NOT NULL;

ALTER TABLE public.process_results
  ADD CONSTRAINT process_results_to_clients_id_fkey FOREIGN KEY (client_id) REFERENCES clients (id) ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE public.process_results
  ADD COLUMN imagen_type_id integer NOT NULL;
ALTER TABLE process_results
  ADD CONSTRAINT process_results_to_imagen_types_id_fkey FOREIGN KEY (imagen_type_id) REFERENCES imagen_types (id) ON UPDATE NO ACTION ON DELETE NO ACTION;


COMMIT;
