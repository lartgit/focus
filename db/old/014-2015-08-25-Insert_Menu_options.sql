BEGIN;

ALTER TABLE menu_options ADD COLUMN parent_id integer;
ALTER TABLE menu_options ADD COLUMN menu_icon character varying(50);

--
-- Data for Name: user_groups; Type: TABLE DATA; Schema: public; Owner: msoft
--

INSERT INTO user_groups VALUES (1, 'admin', true, '2015-08-24 14:22:40.64215', '2015-08-24 14:22:40.64215');
INSERT INTO user_groups VALUES (2, 'test1', true, '2015-08-25 16:16:16.016471', '2015-08-25 16:16:16.016471');

--
-- Data for Name: menu_options; Type: TABLE DATA; Schema: public; Owner: msoft
--

INSERT INTO menu_options VALUES (34, 'Log de Acciones de Usuarios y Descarga', 'controller', 'index', NULL, '2015-08-25 13:47:42.330004', '2015-08-25 13:47:42.330004', 16, '<i class="fa fa-circle"></i>');
INSERT INTO menu_options VALUES (16, 'Descargar Imagen Satelital', 'controller', 'index', NULL, '2015-08-24 16:59:48.763192', '2015-08-24 16:59:48.763192', 12, '<i class="fa fa-camera"></i>');
INSERT INTO menu_options VALUES (15, 'Descargar Shp', 'controller', 'index', NULL, '2015-08-24 16:59:21.467474', '2015-08-24 16:59:21.467474', 12, '<i class="fa fa-file"></i>');
INSERT INTO menu_options VALUES (3, 'Datos de Cliente', 'none', 'none', NULL, '2015-08-24 16:46:16.335325', '2015-08-24 16:46:16.335325', NULL, '<i class="fa fa-user "></i>');
INSERT INTO menu_options VALUES (5, 'Proyecto', 'projects', 'index', NULL, '2015-08-24 16:49:16.158121', '2015-08-24 16:49:16.158121', 3, '<i class="fa fa-tag"></i>');
INSERT INTO menu_options VALUES (4, 'Cliente', 'clients', 'index', NULL, '2015-08-24 16:48:10.095566', '2015-08-24 16:48:10.095566', 3, '<i class="fa fa-user"></i>');
INSERT INTO menu_options VALUES (7, 'Carga de Datos Espaciales', 'none', 'none', NULL, '2015-08-24 16:52:31.885139', '2015-08-24 16:52:31.885139', NULL, '<i class="fa fa-globe"></i>');
INSERT INTO menu_options VALUES (9, 'Carga Grilla', 'controller', 'index', NULL, '2015-08-24 16:55:16.700718', '2015-08-24 16:55:16.700718', 7, '<i class="fa fa-th"></i>');
INSERT INTO menu_options VALUES (10, 'Carga Shp', 'controller', 'index', NULL, '2015-08-24 16:55:48.236215', '2015-08-24 16:55:48.236215', 7, '<i class="fa fa-file"></i>');
INSERT INTO menu_options VALUES (12, 'Descargar Datos Espaciales', 'controller', 'index', NULL, '2015-08-24 16:57:57.115832', '2015-08-24 16:57:57.115832', NULL, '<i class="fa fa-download"></i>');
INSERT INTO menu_options VALUES (13, 'Descargar Grilla', 'none', 'none', NULL, '2015-08-24 16:58:33.965238', '2015-08-24 16:58:33.965238', 12, '<i class="fa fa-th"></i>');
INSERT INTO menu_options VALUES (17, 'Administracion', 'none', 'none', NULL, '2015-08-24 17:02:24.555211', '2015-08-24 17:02:24.555211', NULL, '<i class="fa fa-wrench fa-fw"></i>');
INSERT INTO menu_options VALUES (33, 'Log de Procesos', 'controller', 'index', NULL, '2015-08-25 13:44:09.723953', '2015-08-25 13:44:09.723953', 16, '<i class="fa fa-circle"></i>');
INSERT INTO menu_options VALUES (11, 'Cargar Imagen Satelital', 'controller', 'index', NULL, '2015-08-24 16:57:26.155459', '2015-08-24 16:57:26.155459', 7, '<i class="fa fa-camera"></i>');
INSERT INTO menu_options VALUES (18, 'Usuarios', 'controller', 'index', NULL, '2015-08-24 17:03:20.906361', '2015-08-24 17:03:20.906361', 17, '<i class="fa fa-user"></i>');
INSERT INTO menu_options VALUES (19, 'Grupos', 'controller', 'index', NULL, '2015-08-24 17:03:37.771776', '2015-08-24 17:03:37.771776', 17, '<i class="fa fa-group"></i>');
INSERT INTO menu_options VALUES (22, 'Sets', 'controller', 'index', NULL, '2015-08-24 17:03:51.899899', '2015-08-24 17:03:51.899899', 17, '<i class="fa fa-circle"></i>');
INSERT INTO menu_options VALUES (23, 'Fechas', 'controller', 'index', NULL, '2015-08-24 17:04:05.17918', '2015-08-24 17:04:05.17918', 17, '<i class="fa fa-calendar"></i>');
INSERT INTO menu_options VALUES (24, 'Reglas de Expansion Temporal', 'controller', 'index', NULL, '2015-08-24 17:04:33.306013', '2015-08-24 17:04:33.306013', 17, '<i class="fa fa-circle"></i>');
INSERT INTO menu_options VALUES (25, 'Reglas de Seleccion de Pixeles', 'controller', 'index', NULL, '2015-08-24 17:04:55.465713', '2015-08-24 17:04:55.465713', 17, '<i class="fa fa-circle"></i>');
INSERT INTO menu_options VALUES (27, 'Usos Declarados', 'controller', 'index', NULL, '2015-08-24 17:05:15.19334', '2015-08-24 17:05:15.19334', 17, '<i class="fa fa-circle"></i>');
INSERT INTO menu_options VALUES (29, 'Regiones', 'controller', 'index', NULL, '2015-08-24 17:06:35.705207', '2015-08-24 17:06:35.705207', 17, '<i class="fa fa-circle"></i>');
INSERT INTO menu_options VALUES (30, 'Pixeles', 'controller', 'index', NULL, '2015-08-24 17:06:50.615873', '2015-08-24 17:06:50.615873', 17, '<i class="fa fa-circle"></i>');
INSERT INTO menu_options VALUES (32, 'Establecimiento', 'farms', 'index', NULL, '2015-08-24 17:19:20.67954', '2015-08-24 17:19:20.67954', 3, '<i class="fa fa-picture-o"></i>');
INSERT INTO menu_options VALUES (31, 'Version', 'versions', 'index', NULL, '2015-08-24 17:18:29.174088', '2015-08-24 17:18:29.174088', 3, '<i class="fa fa-cubes"></i>');
INSERT INTO menu_options VALUES (6, 'SubProyecto', 'sub_projects', 'index', NULL, '2015-08-24 16:49:56.749999', '2015-08-24 16:49:56.749999', 3, '<i class="fa fa-tags"></i>');


--
-- Data for Name: groups_by_options; Type: TABLE DATA; Schema: public; Owner: msoft
--

INSERT INTO groups_by_options VALUES (2, 1, 3);
INSERT INTO groups_by_options VALUES (3, 1, 4);
INSERT INTO groups_by_options VALUES (4, 1, 5);
INSERT INTO groups_by_options VALUES (5, 1, 6);
INSERT INTO groups_by_options VALUES (6, 1, 7);
INSERT INTO groups_by_options VALUES (11, 1, 9);
INSERT INTO groups_by_options VALUES (12, 1, 10);
INSERT INTO groups_by_options VALUES (13, 1, 11);
INSERT INTO groups_by_options VALUES (14, 1, 12);
INSERT INTO groups_by_options VALUES (15, 1, 13);
INSERT INTO groups_by_options VALUES (18, 1, 15);
INSERT INTO groups_by_options VALUES (19, 1, 16);
INSERT INTO groups_by_options VALUES (20, 1, 17);
INSERT INTO groups_by_options VALUES (21, 1, 18);
INSERT INTO groups_by_options VALUES (22, 1, 19);
INSERT INTO groups_by_options VALUES (27, 1, 22);
INSERT INTO groups_by_options VALUES (28, 1, 23);
INSERT INTO groups_by_options VALUES (29, 1, 24);
INSERT INTO groups_by_options VALUES (30, 1, 25);
INSERT INTO groups_by_options VALUES (35, 1, 27);
INSERT INTO groups_by_options VALUES (38, 1, 29);
INSERT INTO groups_by_options VALUES (39, 1, 30);
INSERT INTO groups_by_options VALUES (40, 1, 31);
INSERT INTO groups_by_options VALUES (41, 1, 32);
INSERT INTO groups_by_options VALUES (45, 2, 3);
INSERT INTO groups_by_options VALUES (46, 2, 4);
INSERT INTO groups_by_options VALUES (47, 2, 5);
INSERT INTO groups_by_options VALUES (48, 2, 6);



--
-- Data for Name: users_by_groups; Type: TABLE DATA; Schema: public; Owner: msoft
--

INSERT INTO users_by_groups VALUES (1, -1, 1);


COMMIT;
