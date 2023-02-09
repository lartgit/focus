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
-- Data for Name: users_by_groups; Type: TABLE DATA; Schema: public; Owner: r2
--

COPY public.users_by_groups (id, user_id, user_group_id) FROM stdin;
17	9	1
13	-2	1
15	5	2
22	11	1
23	10	1
25	12	1
2	-1	1
28	14	2
29	12	2
30	10	2
31	11	2
32	14	1
33	15	1
35	15	2
36	-2	2
37	17	1
38	18	2
39	19	2
42	20	1
43	20	2
44	21	2
46	23	2
47	17	2
49	24	4
51	26	2
52	25	2
53	26	1
54	25	1
55	27	1
56	28	1
57	29	1
58	30	1
59	23	1
60	31	1
61	33	1
62	32	1
\.


--
-- Name: users_by_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: r2
--

SELECT pg_catalog.setval('public.users_by_groups_id_seq', 62, true);


--
-- PostgreSQL database dump complete
--

