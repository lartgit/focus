
BEGIN;

ALTER TABLE public.process_pixels ADD COLUMN user_id integer NOT NULL DEFAULT -1;
ALTER TABLE public.process_pixels ALTER COLUMN user_id DROP DEFAULT;
ALTER TABLE public.process_pixels ADD CONSTRAINT process_pixels_to_users_fk FOREIGN KEY (user_id) REFERENCES public.users(id)
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

ALTER TABLE public.process_fields ADD COLUMN user_id integer NOT NULL DEFAULT -1;
ALTER TABLE public.process_fields ALTER COLUMN user_id DROP DEFAULT;
ALTER TABLE public.process_fields ADD CONSTRAINT process_fields_to_users_fk FOREIGN KEY (user_id) REFERENCES public.users(id)
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

ALTER TABLE public.process_results ADD COLUMN user_id integer NOT NULL DEFAULT -1;
ALTER TABLE public.process_results ALTER COLUMN user_id DROP DEFAULT;
ALTER TABLE public.process_results ADD CONSTRAINT process_results_to_users_fk FOREIGN KEY (user_id) REFERENCES public.users(id)
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

COMMIT;
