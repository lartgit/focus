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
-- Data for Name: parameter_types; Type: TABLE DATA; Schema: public; Owner: r2
--

COPY public.parameter_types (id, ts, created_at, name, unit, description, quantity, format_type_id) FROM stdin;
1	2017-09-18 02:09:45	2017-09-18 11:58:45.187104	NDVI	\N	\N	\N	1
2	2017-09-18 02:09:30	2017-09-18 11:59:30.282525	EVI	\N	\N	\N	1
3	2017-09-18 03:09:57	2017-09-18 12:00:57.751296	Quality	\N	\N	\N	1
11	2017-12-26 07:12:58	2017-12-26 16:40:58.958667	ordenada_eur	\N	\N	\N	1
12	2017-12-26 07:12:59	2017-12-26 16:40:59.053889	pendiente_eur	\N	\N	\N	1
6	2018-04-20 05:04:00	2017-11-30 12:46:49.126869	Radiacion	W/m2	\N	\N	1
13	2018-08-30 03:08:23	2018-08-30 00:18:23.909936	modland_qa	\N	\N	\N	1
15	2018-11-14 06:11:24	2018-11-14 15:39:24.087553	aerosol_quantity	\N	\N	\N	1
16	2018-11-14 06:11:33	2018-11-14 15:39:33.970239	mixed_clouds	\N	\N	\N	1
17	2018-11-14 06:11:51	2018-11-14 15:39:51.505632	land_water	\N	\N	\N	1
18	2018-11-14 06:11:00	2018-11-14 15:40:00.06374	shadow	\N	\N	\N	1
19	2018-11-14 06:11:09	2018-11-14 15:40:09.188754	snow	\N	\N	\N	1
610	2022-03-22 13:56:10	2022-03-22 10:56:10.540872	B08	\N	\N	\N	2
611	2022-03-22 13:56:18	2022-03-22 10:56:18.356941	B04	\N	\N	\N	2
612	2022-03-22 13:56:22	2022-03-22 10:56:22.911286	B02	\N	\N	\N	2
613	2022-03-22 13:56:31	2022-03-22 10:56:31.227413	B03	\N	\N	\N	2
609	2022-03-22 13:57:58	2022-03-22 10:55:56.877187	Scene Classification	\N	Clasificacion de escena para SENTINEL	\N	2
\.


--
-- Name: parameter_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: r2
--

SELECT pg_catalog.setval('public.parameter_types_id_seq', 613, true);


--
-- PostgreSQL database dump complete
--

