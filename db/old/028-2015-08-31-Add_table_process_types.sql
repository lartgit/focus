BEGIN;

CREATE TABLE public.process_types
(
   pixel_sets_id integer NOT NULL, 
   id serial NOT NULL, 
   pixel_selection_rules_id integer NOT NULL, 
   user_id integer NOT NULL, 
   version_id integer NOT NULL, 
   date timestamp without time zone NOT NULL, 
   name character varying(30), 
   ts timestamp(6) without time zone NOT NULL DEFAULT now(),
   created_at timestamp(6) without time zone NOT NULL DEFAULT now(),
   active boolean NOT NULL DEFAULT true,
   CONSTRAINT process_types_id_pk PRIMARY KEY (id), 
   CONSTRAINT process_types_to_user_id_fkey FOREIGN KEY (user_id) REFERENCES users (id) ON UPDATE NO ACTION ON DELETE NO ACTION, 
   CONSTRAINT process_types_to_pixel_sets_id_fkey FOREIGN KEY (pixel_sets_id) REFERENCES pixel_sets (id) ON UPDATE NO ACTION ON DELETE NO ACTION, 
   CONSTRAINT process_types_to_pixel_selection_rules_id_fkey FOREIGN KEY (pixel_selection_rules_id) REFERENCES pixel_selection_rules (id) ON UPDATE NO ACTION ON DELETE NO ACTION, 
   CONSTRAINT process_types_to_versions_id_fkey FOREIGN KEY (version_id) REFERENCES versions (id) ON UPDATE NO ACTION ON DELETE NO ACTION
) 
WITH (
  OIDS = FALSE
)
;

COMMIT;