
BEGIN;


--Controller de Administracion de lotes
UPDATE public.menu_options
   SET controller = 'fields'
 WHERE id = '15';

COMMIT;

