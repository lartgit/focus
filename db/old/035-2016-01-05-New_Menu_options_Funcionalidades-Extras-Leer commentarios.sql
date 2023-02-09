
BEGIN;


--solicitado por lart 05-01-2016
--Aramirez
--Primero se deberia correr este script y tomar ese id para los demás insert
--Se llamara funcionalidades extras ????? (°-°)
insert into public.menu_options (id,name,controller,action,menu_icon) VALUES(49,'Funcionalidades Extras','none','none','<i class="fa fa-circle-o"></i>');


--Se necesita el id de funcionalidades Extras
insert into public.menu_options (id,name,controller,action,parent_id,menu_icon) VALUES(50,'Productos','data_types','index',49,'<i class="fa fa-circle"></i>');
insert into public.menu_options (id,name,controller,action,parent_id,menu_icon) VALUES(51,'Tipos de Imagen','imagen_types','index',49,'<i class="fa fa-picture-o"></i>');


insert into public.groups_by_options (user_group_id,menu_option_id) VALUES(1,49);
insert into public.groups_by_options (user_group_id,menu_option_id) VALUES(1,50);
insert into public.groups_by_options (user_group_id,menu_option_id) VALUES(1,51);

COMMIT;

