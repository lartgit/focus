BEGIN;


--solicitado por marcos 12-01-2016
--Aramirez
--Primero se deberia correr este script y tomar ese id para los demás insert
insert into public.menu_options (id,name,controller,action,menu_icon) VALUES(52,'Calculos','none','none','<i class="fa fa-calculator"></i>');


--Se necesita el id de calculos
UPDATE public.menu_options
   SET parent_id = '52',
   name = 'Resultado de Asignacion Pixels'
 WHERE id = '36';

 UPDATE public.menu_options
   SET parent_id = '52',
   name = 'Proceso de Asignacion Pixels'
 WHERE id = '37';


insert into public.groups_by_options (user_group_id,menu_option_id) VALUES(1,52);

COMMIT;
