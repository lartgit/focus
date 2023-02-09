
BEGIN;

ALTER TABLE public.users DROP CONSTRAINT users_to_organizations_fk;
ALTER TABLE public.users ADD CONSTRAINT users_to_organizations_fk FOREIGN KEY (organization_id) REFERENCES public.organizations (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE public.raster_files DROP CONSTRAINT raster_files_image_type_id_fk;
ALTER TABLE public.raster_files ADD CONSTRAINT raster_files_image_type_id_fk FOREIGN KEY (image_type_id) REFERENCES public.imagen_types (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE public.process_results DROP CONSTRAINT process_results_to_user_id_fkey;
ALTER TABLE public.process_results ADD CONSTRAINT process_results_to_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE public.process_results DROP CONSTRAINT process_results_to_pixel_sets_id;
ALTER TABLE public.process_results ADD CONSTRAINT process_results_to_pixel_sets_id FOREIGN KEY (set_id) REFERENCES public.pixel_sets (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE public.process_results DROP CONSTRAINT process_results_to_imagen_types_id_fkey;
ALTER TABLE public.process_results ADD CONSTRAINT process_results_to_imagen_types_id_fkey FOREIGN KEY (imagen_type_id) REFERENCES public.imagen_types (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE public.process_results DROP CONSTRAINT process_results_to_clients_id_fkey;
ALTER TABLE public.process_results ADD CONSTRAINT process_results_to_clients_id_fkey FOREIGN KEY (client_id) REFERENCES public.clients (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE public.process_regions DROP CONSTRAINT process_regions_to_maps_fk;
ALTER TABLE public.process_regions ADD CONSTRAINT process_regions_to_maps_fk FOREIGN KEY (map_id) REFERENCES public.maps (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE public.process_functions DROP CONSTRAINT process_functions_to_user_id_fkey;
ALTER TABLE public.process_functions ADD CONSTRAINT process_functions_to_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE public.process_functions DROP CONSTRAINT process_functions_to_process_results_fkey;
ALTER TABLE public.process_functions ADD CONSTRAINT process_functions_to_process_results_fkey FOREIGN KEY (process_result_id) REFERENCES public.process_results (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE public.process_functions DROP CONSTRAINT process_functions_map_id_to_maps;
ALTER TABLE public.process_functions ADD CONSTRAINT process_functions_map_id_to_maps FOREIGN KEY (map_id) REFERENCES public.maps (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE public.functions DROP CONSTRAINT fk_functions_to_users;
ALTER TABLE public.functions ADD CONSTRAINT fk_functions_to_users FOREIGN KEY (user_id) REFERENCES public.users (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE public.clients DROP CONSTRAINT clients_to_organizations_fk;
ALTER TABLE public.clients ADD CONSTRAINT clients_to_organizations_fk FOREIGN KEY (organization_id) REFERENCES public.organizations (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE public.process_functions DROP CONSTRAINT process_functions_to_user_id_fkey;
ALTER TABLE public.process_functions ADD CONSTRAINT process_functions_to_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;
ALTER TABLE public.process_functions DROP CONSTRAINT process_functions_to_user_id_fkey;
ALTER TABLE public.process_functions ADD CONSTRAINT process_functions_to_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE;

COMMIT;
