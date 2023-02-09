BEGIN;

DELETE FROM groups_by_options WHERE menu_option_id = 52;
DELETE FROM menu_options WHERE id = 52;

INSERT INTO menu_options (id, name, controller, action, description, parent_id, menu_icon) VALUES
(49, 'Calculos', 'none', 'none', '',NULL,'<i class="fa fa-calculator"></i>'),
(48, 'Tipos de Imagen','imagen_types','index','',46,'<i class="fa fa-picture-o"></i>'),
(47, 'Productos', 'data_types','index','',46,'<i class="fa fa-circle"></i>'),
(46, 'Funcionalidades Extras', 'none', 'none', '',NULL, '<i class="fa fa-circle-o"></i>'),
(45, 'Traducciones', 'business_objects_translations', 'index', '', 17, '<i class="fa fa-language"></i>'),
(37, 'Proceso de Asignacion Pixels', 'process_results', 'index', '', 49, '<i class="fa fa-cogs"></i>'),
(36, 'Resultado de Asignacion Pixels', 'results', 'index', '', 49, '<i class="fa fa-share-square-o"></i>'),
(35, 'Usos Concretos', 'use_concretes', 'index', '', 17, '<i class="fa fa-bullseye"></i>');

insert into groups_by_options (user_group_id, menu_option_id) VALUES (1, 49), (1, 48), (1, 47), (1, 46), (1, 45), (1, 37), (1, 36), (1, 35);

delete from groups_by_options where menu_option_id = 11;
delete from groups_by_options where menu_option_id = 16;

COMMIT;
