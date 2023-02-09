BEGIN;
insert into public.menu_options (id,name,controller,action,parent_id,menu_icon) values (42,'Traducciones','business_objects_translations','index',17,'<i class="fa fa-language"></i>');
insert into public.groups_by_options(user_group_id,menu_option_id) values (1,42);
COMMIT;