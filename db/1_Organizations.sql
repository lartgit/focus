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
-- Data for Name: organizations; Type: TABLE DATA; Schema: public; Owner: r2
--

COPY public.organizations (id, ts, created_at, name) FROM stdin;
1	2017-09-07 08:09:12	2017-09-07 17:25:12.491126	LART
18	2017-12-26 12:12:23	2017-12-26 09:33:23.817847	CREA
-1	2018-10-29 07:10:59	2017-08-25 00:00:00	R2
20	2020-09-11 11:41:07	2020-09-11 08:41:07.856063	Forrajes
\.


--
-- Name: organizations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: r2
--

SELECT pg_catalog.setval('public.organizations_id_seq', 20, true);


--
-- PostgreSQL database dump complete
--

