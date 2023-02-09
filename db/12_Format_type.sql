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
-- Data for Name: format_types; Type: TABLE DATA; Schema: public; Owner: r2
--

COPY public.format_types (id, ts, created_at, name) FROM stdin;
1	2019-06-18 12:17:05.721219	2019-06-18 12:17:05.721219	String
2	2019-06-18 12:17:05.721219	2019-06-18 12:17:05.721219	Numeric
\.


--
-- Name: format_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: r2
--

SELECT pg_catalog.setval('public.format_types_id_seq', 1, false);


--
-- PostgreSQL database dump complete
--

