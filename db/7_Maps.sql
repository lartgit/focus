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
-- Data for Name: maps; Type: TABLE DATA; Schema: public; Owner: r2
--

COPY public.maps (id, name, quantity, ts, created_at, organization_id, path) FROM stdin;
39	Unidades_Geomorfologicas_ROU	\N	2017-12-14 02:12:17	2017-12-14 11:18:17.700225	1	/focus/ftp/Shapes/Unidades_Geomorfologicas_ROU.shp
40	Unidades_Vegetacion_RA	\N	2017-12-14 02:12:33	2017-12-14 11:18:33.577947	1	/focus/ftp/Shapes/Unidades_Vegetacion_RA.shp
42	Paraguay_contorno	\N	2018-12-07 03:12:43	2018-12-07 12:39:43.856295	1	/home/ftp/Shapes/Paraguay-Contorno.shp
44	Unidades Vegetacion RA	\N	2019-06-10 17:22:28	2019-06-10 14:22:28.271641	18	/home/ftp/Shapes/Luca Scenna-5cfe91b35db20.shp
45	Regiones Paraguay	\N	2019-09-30 13:11:10	2019-09-30 10:11:10.774353	18	/home/ftp/CREA/Paraguay FOCUS2_wgs84.shp
67	Unidades Vegetacion RA_Forrajes	\N	2020-09-17 02:00:08	2020-09-16 23:00:08.587418	20	/home/ftp/Shapes/Mapa_Argentina_Forrajes.shp
\.


--
-- Name: maps_id_seq; Type: SEQUENCE SET; Schema: public; Owner: r2
--

SELECT pg_catalog.setval('public.maps_id_seq', 67, true);


--
-- PostgreSQL database dump complete
--

