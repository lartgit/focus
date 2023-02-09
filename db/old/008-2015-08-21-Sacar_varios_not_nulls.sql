
BEGIN;

ALTER TABLE public.db_actions_logs ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.users ALTER COLUMN "password" DROP NOT NULL;

COMMIT;
