BEGIN;

INSERT INTO public.menu_options ("name","controller","action","parent_id","menu_icon")
VALUES ('Resultados','process_results','index',17,'<i class="fa fa-circle"></i>');
 
INSERT INTO public.groups_by_options ("user_group_id","menu_option_id")
VALUES (1,36);

COMMIT;
