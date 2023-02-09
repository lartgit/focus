BEGIN;
-- Table: process_results

DROP TABLE process_types;

CREATE TABLE process_results
(
  set_id integer NOT NULL,
  id serial NOT NULL,
  pixel_selection_rules_id integer NOT NULL,
  user_id integer NOT NULL,
  version_id integer NOT NULL,
  date_id integer NOT NULL,
  name character varying(30) NOT NULL,
  ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  created_at timestamp(6) without time zone NOT NULL DEFAULT now(),
  active boolean NOT NULL DEFAULT true,
  start_process_at timestamp without time zone,
  end_process_at timestamp without time zone,
  description character varying(200),
  CONSTRAINT process_results_id_pk PRIMARY KEY (id),
  CONSTRAINT process_results_to_pixel_sets_id FOREIGN KEY (set_id)
      REFERENCES pixel_sets (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT process_results_to_pixel_selection_rules_id_fkey FOREIGN KEY (pixel_selection_rules_id)
      REFERENCES pixel_selection_rules (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT process_results_to_user_id_fkey FOREIGN KEY (user_id)
      REFERENCES users (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT process_results_to_versions_id_fkey FOREIGN KEY (version_id)
      REFERENCES versions (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT process_results_to_dates_id_fkey FOREIGN KEY (date_id)
      REFERENCES dates (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);

COMMIT;