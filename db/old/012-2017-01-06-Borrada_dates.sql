BEGIN;
DELETE FROM dates;

DROP TABLE dates;

DELETE FROM menu_options WHERE controller = 'dates';

COMMIT;