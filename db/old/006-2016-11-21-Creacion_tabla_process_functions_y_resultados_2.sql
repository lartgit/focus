BEGIN;

CREATE TABLE public.process_functions
(
	id serial NOT NULL, 
	status character varying(20) NOT NULL, 
	process_result_id integer NOT NULL, 
	function_id integer,
	user_id integer NOT NULL,
	name character varying(30) NOT NULL,
	ts timestamp(6) without time zone NOT NULL DEFAULT now(),
	created_at timestamp(6) without time zone NOT NULL DEFAULT now(),
	active boolean NOT NULL DEFAULT true,
	start_process_at timestamp without time zone,
	end_process_at timestamp without time zone,
	description character varying(200),
	date date,
	CONSTRAINT process_functions_id_pk PRIMARY KEY (id),
    CONSTRAINT process_functions_to_functions_fkey FOREIGN KEY (function_id) REFERENCES functions (id) ON UPDATE NO ACTION ON DELETE SET NULL,
	CONSTRAINT process_functions_to_process_results_fkey FOREIGN KEY (process_result_id) REFERENCES process_results (id) ON UPDATE NO ACTION ON DELETE NO ACTION,
	CONSTRAINT process_functions_to_user_id_fkey FOREIGN KEY (user_id) REFERENCES users (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Index process_functions
CREATE INDEX fki_process_functions_to_functions_fkey
  ON process_functions(function_id);

-- Table: log_process_functions

-- DROP TABLE log_process_functions;

CREATE TABLE log_process_functions
(
  id serial NOT NULL,
  description text,
  process_function_id integer,
  ts timestamp without time zone NOT NULL DEFAULT now(),
  CONSTRAINT log_process_functions_pk PRIMARY KEY (id),
  CONSTRAINT log_to_process_process_function_id FOREIGN KEY (process_function_id)
      REFERENCES process_functions (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE
);



COMMIT;
