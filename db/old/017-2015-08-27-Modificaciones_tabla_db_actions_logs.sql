
BEGIN;

ALTER TABLE public.db_actions_logs DROP COLUMN full_query;
ALTER TABLE public.db_actions_logs DROP COLUMN affected_entity;
ALTER TABLE public.db_actions_logs RENAME COLUMN "action" TO event;

ALTER TABLE public.db_actions_logs ADD COLUMN object_class varchar(30) NOT NULL DEFAULT '';
ALTER TABLE public.db_actions_logs ADD COLUMN object_id varchar(30) NOT NULL DEFAULT '';
ALTER TABLE public.db_actions_logs ADD COLUMN "object" varchar;

ALTER TABLE public.db_actions_logs ALTER COLUMN object_class DROP DEFAULT;
ALTER TABLE public.db_actions_logs ALTER COLUMN object_id DROP DEFAULT;

COMMIT;
