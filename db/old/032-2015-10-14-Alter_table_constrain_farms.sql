BEGIN;

ALTER TABLE public.farms DROP CONSTRAINT farms_code;

ALTER TABLE public.farms
  ADD CONSTRAINT farms_code UNIQUE(code,version_id);

COMMIT;
