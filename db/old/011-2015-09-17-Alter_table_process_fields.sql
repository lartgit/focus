BEGIN;

ALTER TABLE public.process_fields DROP CONSTRAINT process_fields_to_subprojects_fk;

ALTER TABLE public.process_fields DROP COLUMN subproject_id;

COMMIT;
