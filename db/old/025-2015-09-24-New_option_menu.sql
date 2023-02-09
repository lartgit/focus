BEGIN;
insert into public.menu_options (id,name,controller,action,parent_id,menu_icon) VALUES(41,'Layers','layers','index',18,'<i class="fa fa-stack-exchange"></i>');
insert into public.groups_by_options (user_group_id,menu_option_id) VALUES(1,41);
COMMIT;
