
BEGIN;

--por si se quiere restaurar
-- menu_options
-- id name                   controller   action description parent_id menu_icon
-- 38 Funcionalidades Extras none         none                         <i class="fa fa-circle-o"></i>
-- 39 Tipos de Datos         data_types   index              38        <i class="fa fa-circle"></i>
-- 40 Tipos de Imagen        imagen_types index              38        <i class="fa fa-picture-o"></i>
-- 41 Layers                 layers       index              38        <i class="fa fa-stack-exchange"></i>

-- groups_by_options
-- id user_group_id menu_option_id
-- 53 1             38
-- 54 1             39
-- 55 1             40
-- 56 1             41

DELETE FROM menu_options WHERE id IN (38, 39, 40, 41);

COMMIT;
