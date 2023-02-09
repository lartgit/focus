BEGIN;


CREATE TABLE public.functions
(
   id serial NOT NULL, 
   name character varying(50) NOT NULL, 
   ts timestamp without time zone NOT NULL DEFAULT now(), 
   created_at timestamp without time zone NOT NULL DEFAULT now(), 
   user_id integer NOT NULL,
   path text NOT NULL,
   description  character varying(200),
   fx_saved_name character varying(200),
   column_name character varying(80),
   CONSTRAINT fk_functions_to_users FOREIGN KEY (user_id) REFERENCES users (id) ON UPDATE NO ACTION ON DELETE NO ACTION
);

ALTER TABLE functions
  ADD CONSTRAINT functions_id_pk PRIMARY KEY (id);
   
COMMIT;
