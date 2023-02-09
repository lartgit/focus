INSERT INTO menu_options (name, controller, "action", description, parent_id, "order") VALUES
	('Descarga de Usos', 'fields', 'use_download', 'Descarga de Uso de Lotes', (SELECT id FROM menu_options WHERE name = 'Lotes'), 1900);

INSERT INTO groups_by_options (user_group_id, menu_option_id) VALUES(1, (SELECT id FROM menu_options WHERE name = 'Descarga de Usos'));

