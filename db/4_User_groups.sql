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
-- Data for Name: user_groups; Type: TABLE DATA; Schema: public; Owner: r2
--

COPY public.user_groups (id, name, active, ts, created_at, description) FROM stdin;
1	Admin	t	2018-07-12 05:07:25	2015-08-24 14:22:40.64215	\N
4	Forrajes	t	2020-09-15 15:59:44	2020-09-15 12:59:44.894653	\N
2	Cargador_datos	t	2020-10-21 18:33:38	2015-10-11 16:57:07.143122	\N
\.


--
-- Name: user_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: r2
--

SELECT pg_catalog.setval('public.user_groups_id_seq', 4, true);


--
-- PostgreSQL database dump complete
--

