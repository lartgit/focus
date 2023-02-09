
BEGIN;

--Controller de descarga de resultados
UPDATE public.menu_options
   SET controller = 'results'
 WHERE id = '36';

COMMIT;

