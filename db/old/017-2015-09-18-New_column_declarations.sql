
BEGIN;

ALTER TABLE public.declarations ADD COLUMN use_concrete_id integer;

ALTER TABLE public.declarations ADD CONSTRAINT declarations_to_use_concrete_id_fkey
 FOREIGN KEY (use_concrete_id) REFERENCES public.use_concretes(id)
 ON DELETE CASCADE ON UPDATE NO ACTION;

ALTER TABLE public.declarations ALTER COLUMN use_declared_id DROP NOT NULL;
ALTER TABLE public.declarations DROP COLUMN active;

COMMIT;
