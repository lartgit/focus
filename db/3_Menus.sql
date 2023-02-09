--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.10
-- Dumped by pg_dump version 9.6.24

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: menu_options; Type: TABLE DATA; Schema: public; Owner: r2
--

COPY public.menu_options (id, name, controller, action, description, ts, created_at, parent_id, menu_icon, "order") FROM stdin;
49	Calculos	none	none		2016-02-02 11:12:51.51286	2016-02-02 11:12:51.51286	\N	<i class="fa fa-calculator"></i>	1000
36	Resultado de Asignacion Pixels	results	index		2015-10-05 16:46:37.22283	2015-10-05 16:46:37.22283	49	<i class="fa fa-share-square-o"></i>	371
37	Proceso de Asignacion Pixels	process_results	index		2015-10-05 16:46:41.822539	2015-10-05 16:46:41.822539	49	<i class="fa fa-cogs"></i>	3700
48	Tipos de Imagen	imagen_types	index		2016-02-02 10:53:24.110928	2016-02-02 10:53:24.110928	77	<i class="fa fa-file-image-o"></i>	4800
3	Datos de Cliente	none	none		2015-08-24 16:46:16.335325	2015-08-24 16:46:16.335325	\N	<i class="fa fa-user "></i>	300
4	Cliente	clients	index		2015-08-24 16:48:10.095566	2015-08-24 16:48:10.095566	3	<i class="fa fa-user"></i>	400
5	Proyecto	projects	index		2015-08-24 16:49:16.158121	2015-08-24 16:49:16.158121	3	<i class="fa fa-tag"></i>	500
7	Grilla	none	none		2015-08-24 16:52:31.885139	2015-08-24 16:52:31.885139	\N	<i class="fa fa-globe"></i>	700
9	Carga Grilla	process_pixels	index		2015-08-24 16:55:16.700718	2015-08-24 16:55:16.700718	7	<i class="fa fa-th"></i>	900
10	Carga Shp	process_fields	index		2015-08-24 16:55:48.236215	2015-08-24 16:55:48.236215	12	<i class="fa fa-file"></i>	1000
12	Lotes	controller	index		2015-08-24 16:57:57.115832	2015-08-24 16:57:57.115832	\N	<i class="fa fa-file"></i>	1200
13	Descargar Grilla	Pixels	index		2015-08-24 16:58:33.965238	2015-08-24 16:58:33.965238	7	<i class="fa fa-download"></i>	1300
15	Descargar Shp	fields	index		2015-08-24 16:59:21.467474	2015-08-24 16:59:21.467474	12	<i class="fa fa-download"></i>	1500
17	Administracion	none	none		2015-08-24 17:02:24.555211	2015-08-24 17:02:24.555211	\N	<i class="fa fa-wrench fa-fw"></i>	41
18	Usuarios	users	index		2015-08-24 17:03:20.906361	2015-08-24 17:03:20.906361	17	<i class="fa fa-user"></i>	1800
19	Grupos	user_groups	index		2015-08-24 17:03:37.771776	2015-08-24 17:03:37.771776	17	<i class="fa fa-group"></i>	1900
22	Escenas	pixel_sets	index		2015-08-24 17:03:51.899899	2015-08-24 17:03:51.899899	7	<i class="fa fa-table"></i>	220
24	Reglas de Expansion Temporal	temporal_expansion_rules	index		2015-08-24 17:04:33.306013	2015-08-24 17:04:33.306013	75	<i class="fa fa-calendar-times-o"></i>	99
27	Usos Declarados	use_declareds	index		2015-08-24 17:05:15.19334	2015-08-24 17:05:15.19334	75	<i class="fa fa-list-ol"></i>	2700
31	Version	versions	index		2015-08-24 17:18:29.174088	2015-08-24 17:18:29.174088	3	<i class="fa fa-cubes"></i>	3100
32	Establecimiento	farms	index		2015-08-24 17:19:20.67954	2015-08-24 17:19:20.67954	3	<i class="fa fa-picture-o"></i>	3200
34	Log de Acciones de Usuarios y Descarga	actions_log	index		2015-08-25 13:47:42.330004	2015-08-25 13:47:42.330004	17	<i class="fa fa-file-text-o"></i>	3400
35	Usos Concretos	use_concretes	index		2015-10-05 16:46:28.808733	2015-10-05 16:46:28.808733	75	<i class="fa fa-bullseye"></i>	3500
45	Traducciones	business_objects_translations	index		2016-02-02 10:52:35.549519	2016-02-02 10:52:35.549519	17	<i class="fa fa-language"></i>	4500
55	Parametros Regionales	none	none		2016-11-08 16:47:37.918952	2016-11-08 16:47:37.918952	\N	<i class="fa fa-plus-square-o"></i>	118
75	Usos	none	index		2017-01-06 18:00:03.12403	2017-01-06 18:00:03.12403	\N	<i class="fa fa-crop"></i>	119
76	Resultados Focus 2	none	index		2017-01-06 18:00:03.12403	2017-01-06 18:00:03.12403	\N	<i class="fa fa-sort-numeric-desc"></i>	760
77	Configuracion	none	index		2017-01-06 18:00:03.12403	2017-01-06 18:00:03.12403	\N	<i class="fa fa-wrench"></i>	770
62	Mapa Regiones	maps	index		2016-11-08 16:54:56.885231	2016-11-08 16:54:56.885231	55	<i class="fa fa-object-ungroup"></i>	6200
63	Regiones	regions	index		2016-11-09 16:45:05.980419	2016-11-09 16:45:05.980419	55	<i class="fa fa-puzzle-piece"></i>	6300
65	Parametros	parameters	index		2016-11-11 17:19:49.814347	2016-11-11 17:19:49.814347	55	<i class="fa fa-sliders"></i>	6500
73	Capas de Raster	raster_layers	index		2016-11-21 16:26:44.382713	2016-11-21 16:26:44.382713	66	<i class="fa fa-database"></i>	7300
70	Tipo de capa	layer_types	index		2016-11-14 18:15:42.27275	2016-11-14 18:15:42.27275	77	<i class="fa fa-database"></i>	7000
78	Resultados de Procesos de Funciones	process_functions_results	index		2017-01-06 18:00:03.12403	2017-01-06 18:00:03.12403	76	<i class="fa fa-share-square-o"></i>	780
66	Administración de rasters	none	none		2016-11-14 18:09:40.231724	2016-11-14 18:09:40.231724	\N	<i class="fa fa-object-group"></i>	6600
67	Tipo de variables	variable_types	index		2016-11-14 18:10:01.639686	2016-11-14 18:10:01.639686	77	<i class="fa fa-book"></i>	6700
68	Archivos rasters	raster_files	index		2016-11-14 18:10:14.515286	2016-11-14 18:10:14.515286	66	<i class="fa fa-file-image-o"></i>	6800
71	Funciones	functions	index		2016-11-21 13:46:26.341174	2016-11-21 13:46:26.341174	76	<i class="fa fa-file-code-o"></i>	7100
74	Procesar Funciones	process_functions	index		2017-01-06 17:58:33.738736	2017-01-06 17:58:33.738736	76	<i class="fa fa-cogs"></i>	7400
79	Organizaciones	organizations	index		2017-01-13 11:59:03.169751	2017-01-13 11:59:03.169751	17	<i class="fa fa-suitcase"></i>	2000
58	Importacion de Usos	uses_asigns	index	\N	2017-03-30 19:40:58.857011	2017-03-30 19:40:58.857011	12	\N	1800
59	Reglas de Seleccion de Pixeles	pixel_selection_rules	index		2017-11-15 16:23:23.737972	2017-11-15 16:23:23.737972	77	\N	7500
60	Consultar Resultados	process_query_functions	index		2020-07-07 14:57:44.816756	2020-07-07 14:57:44.816756	76	<i class="fa fa-magnifer"></i>	780
64	Descarga de Usos	fields	use_download	Descarga de Uso de Lotes	2022-03-21 11:23:30.062937	2022-03-21 11:23:30.062937	12	\N	1900
\.


--
-- Name: menu_options_id_seq; Type: SEQUENCE SET; Schema: public; Owner: r2
--

SELECT pg_catalog.setval('public.menu_options_id_seq', 64, true);


--
-- PostgreSQL database dump complete
--

