BEGIN;


ALTER TABLE public.db_actions_logs
   ALTER COLUMN user_id DROP NOT NULL;

COMMIT;
