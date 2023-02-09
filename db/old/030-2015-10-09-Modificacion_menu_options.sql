
BEGIN;

UPDATE public.menu_options SET menu_icon = '<i class="fa fa-cogs"></i>' WHERE name = 'Proceso Exportacion';
UPDATE public.menu_options SET menu_icon = '<i class="fa fa-object-group"></i>' WHERE name = 'Regiones';
UPDATE public.menu_options SET menu_icon = '<i class="fa fa-share-square-o"></i>' WHERE name = 'Resultados';
UPDATE public.menu_options SET menu_icon = '<i class="fa fa-file-text-o"></i>' WHERE name = 'Log de Acciones de Usuarios y Descarga';
UPDATE public.menu_options SET menu_icon = '<i class="fa fa-file-text-o"></i>' WHERE name = 'Log de Procesos';
UPDATE public.menu_options SET menu_icon = '<i class="fa fa-plus-square-o"></i>' WHERE name = 'Pixeles';
UPDATE public.menu_options SET menu_icon = '<i class="fa fa-table"></i>' WHERE name = 'Sets';
UPDATE public.menu_options SET menu_icon = '<i class="fa fa-calendar-times-o"></i>' WHERE name = 'Reglas de Expansion Temporal';
UPDATE public.menu_options SET menu_icon = '<i class="fa fa-crosshairs"></i>' WHERE name = 'Reglas de Seleccion de Pixeles';
UPDATE public.menu_options SET menu_icon = '<i class="fa fa-list-ol"></i>' WHERE name = 'Usos Declarados';
UPDATE public.menu_options SET menu_icon = '<i class="fa fa-bullseye"></i>' WHERE name = 'Usos Concretos';

COMMIT;
