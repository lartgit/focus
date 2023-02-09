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
-- Data for Name: groups_by_options; Type: TABLE DATA; Schema: public; Owner: r2
--

COPY public.groups_by_options (id, user_group_id, menu_option_id) FROM stdin;
218	1	59
114	1	5
115	1	3
14	1	12
15	1	13
18	1	15
21	1	18
22	1	19
27	1	22
29	1	24
35	1	27
49	1	34
50	1	35
126	1	45
132	1	7
136	1	32
144	1	77
149	1	71
150	1	79
151	1	62
152	1	55
153	1	65
154	1	63
155	1	74
156	1	76
157	1	78
158	1	67
159	1	70
160	1	75
163	1	37
164	1	36
165	1	48
168	1	58
170	1	17
171	1	66
172	1	68
173	1	49
174	1	73
175	1	9
177	1	10
180	1	4
185	2	49
189	2	10
193	2	15
200	2	12
205	2	74
206	2	37
209	2	36
212	2	78
217	2	75
220	1	31
227	2	31
230	2	59
232	2	3
233	2	58
234	1	60
238	2	17
240	2	76
241	4	49
242	4	10
243	4	3
244	4	15
245	4	58
246	4	12
247	4	74
248	4	37
249	4	59
250	4	36
251	4	78
252	4	76
253	4	75
254	4	31
255	4	55
256	4	62
257	4	63
258	4	65
260	2	60
261	4	17
262	4	71
263	2	66
264	2	68
265	2	73
271	1	64
\.


--
-- Name: groups_by_options_id_seq; Type: SEQUENCE SET; Schema: public; Owner: r2
--

SELECT pg_catalog.setval('public.groups_by_options_id_seq', 271, true);


--
-- PostgreSQL database dump complete
--

