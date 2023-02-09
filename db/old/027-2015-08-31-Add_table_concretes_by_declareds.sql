BEGIN;

CREATE TABLE public.concretes_by_declareds
(
   id serial NOT NULL, 
   declared_id integer NOT NULL, 
   concrete_id integer NOT NULL, 
   CONSTRAINT concretes_by_declareds_pk PRIMARY KEY (id), 
   CONSTRAINT concretes_by_declareds_to_use_declareds_id_fkey FOREIGN KEY (declared_id) REFERENCES use_declareds (id) ON UPDATE NO ACTION ON DELETE CASCADE, 
   CONSTRAINT concretes_by_declareds_to_use_concretes_id_fkey FOREIGN KEY (concrete_id) REFERENCES use_concretes (id) ON UPDATE NO ACTION ON DELETE CASCADE
) 
WITH (
  OIDS = FALSE
)
;

COMMIT;