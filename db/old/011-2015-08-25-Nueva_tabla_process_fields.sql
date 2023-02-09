
BEGIN;

CREATE TABLE process_fields
(
  id serial NOT NULL,
  ts timestamp without time zone NOT NULL DEFAULT now(),
  created_at timestamp without time zone NOT NULL DEFAULT now(),
  start_process_at timestamp without time zone,
  end_process_at timestamp without time zone,
  description character varying,
  path character varying(100),
  client_id integer NOT NULL,
  project_id integer NOT NULL,
  subproject_id integer NOT NULL,
  version_id integer NOT NULL,
  CONSTRAINT process_fields_pkey PRIMARY KEY (id),
  CONSTRAINT process_fields_to_clients_fk FOREIGN KEY (client_id)
      REFERENCES clients (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT process_fields_to_projects_fk FOREIGN KEY (project_id)
      REFERENCES projects (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE DEFERRABLE INITIALLY IMMEDIATE,
  CONSTRAINT process_fields_to_subprojects_fk FOREIGN KEY (subproject_id)
      REFERENCES sub_projects (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT process_fields_to_versions_fk FOREIGN KEY (version_id)
      REFERENCES versions (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE
);

COMMIT;
