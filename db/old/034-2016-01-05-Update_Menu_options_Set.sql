
BEGIN;

--Modificacion de la denominacion de los pixel_sets set=escena
--solicitado por lart 05-01-2016
--Aramirez
UPDATE public.menu_options
   SET name = 'Escenas'
 WHERE id = '22';

COMMIT;

