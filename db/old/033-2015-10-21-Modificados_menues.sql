
BEGIN;

UPDATE menu_options SET "controller" = 'Pixels', "action" = 'index' WHERE "name" = 'Descargar Grilla';
DELETE FROM menu_options WHERE "name" = 'Pixeles';

COMMIT;
