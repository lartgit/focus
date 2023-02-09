BEGIN;

ALTER TABLE public.projects ADD COLUMN parent_id integer;

ALTER TABLE public.projects
  ADD CONSTRAINT projects_to_projects_fk FOREIGN KEY (parent_id) REFERENCES projects (id)
   ON UPDATE NO ACTION ON DELETE CASCADE;
CREATE INDEX fki_projects_to_projects_fk
  ON projects(parent_id);


TRUNCATE public.versions CASCADE;

ALTER TABLE public.versions DROP CONSTRAINT versions_to_sub_project_id_fkey;

ALTER TABLE public.versions DROP COLUMN sub_project_id;


ALTER TABLE public.versions ADD COLUMN project_id integer NOT NULL;


ALTER TABLE public.versions
  ADD CONSTRAINT version_to_projecs_fk FOREIGN KEY (project_id) REFERENCES projects (id)
   ON UPDATE NO ACTION ON DELETE CASCADE;
CREATE INDEX fki_version_to_projecs_fk
  ON versions(project_id);


COMMIT;
