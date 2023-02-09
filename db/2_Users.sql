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
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: r2
--

COPY public.users (id, name, password, email, active, is_admin, last_login, last_ip, inactive_reason, activation_code, failed_login_count, ts, created_at, password_sent_at, organization_id) FROM stdin;
13	r2usertest	\\x	yuri-dl@hotmail.com	f	f	2020-06-04 12:06:19	\N	12	\N	0	2020-06-04 00:46:19	2018-10-29 16:12:49.746856	\N	-1
15	Martin Oesterheld	\\x35326362306664623064306338336338636461663035643531613861383266663133303334353231	oesterhe@agro.uba.ar	t	t	2018-11-26 09:05:37	10.1.34.24	\N		0	2018-11-21 05:11:56	2018-11-21 10:36:43.067597	2018-11-21 10:36:50	1
24	Luca	\\x36353338653166316165303931346461316463393635313037353530313030383038323865306166	luca.scenna@hotmail.com	t	f	2021-10-18 19:03:55	200.127.199.208	\N		0	2021-07-15 19:08:59	2020-09-14 10:55:59.967393	2021-07-15 16:08:39	18
27	LART	\\x36396461343464376165373764663564393435353734393530613037373361303331386263333463	lart@agro.uba.ar	t	t	2021-02-02 07:12:31	179.30.15.147	\N		0	2021-02-02 10:10:58	2021-02-01 16:20:01.573217	2021-02-01 16:20:22	18
9	Axel	\\x	axel.bayerl@gmail.com	t	t	2017-11-08 05:11:03	\N	\N	iwdzWFuY	0	2017-11-08 05:11:03	2017-11-08 14:33:03.185602	2022-02-15 13:37:43	-1
23	Mariano Oyarzabal	\\x62363865663035353462333530626638633562613037353834366337323965623562376263633538	oyarzaba@agro.uba.ar	t	t	2021-07-15 06:07:31	181.44.116.77	\N		0	2021-07-15 18:41:31	2020-07-23 11:13:56.336592	2020-07-28 12:00:21	1
22	Mercedes Lanati	\\x	mlanati@agro.uba.ar	t	f	2020-09-14 01:09:59	\N	\N	5knfKPbI	0	2020-09-14 13:54:59	2020-02-20 10:40:39.231019	2020-02-20 10:40:48	20
31	Martín Menéndez Coccoz	\\x34386136343462353661616638396235376362666566663633313934323931656638323937336337	mamenendez@agro.uba.ar	t	t	2022-01-13 15:57:20	10.1.1.13	\N		0	2021-10-28 10:56:30	2021-10-15 09:53:54.714112	2021-10-20 06:56:22	1
4	aaa	\\x37393333343538393061616438333635656161353032653639623936393862633639393231663638	ariel.ramirez+1@r2software.net	t	t	2017-11-21 10:11:18	181.90.59.74	\N	UiJbpaXA	0	2017-11-21 10:11:18	2017-09-08 15:53:25.558303	2018-11-13 12:46:28	-1
19	Natalia Cadaviz	\\x36353338653166316165303931346461316463393635313037353530313030383038323865306166	cadaviz@agro.uba.ar	t	f	2020-11-24 12:00:44	181.230.255.33	\N		0	2019-08-09 15:12:44	2019-08-09 10:35:49.064154	2019-08-09 12:11:27	1
7	Lucas Suad	\\x32616530343564363638366564353334356366323765343261336238633034396231653236653835	suadsierra@agro.uba.ar	t	f	2020-05-20 03:05:49	10.1.34.5	\N	\N	0	2020-05-20 15:20:49	2017-09-12 14:15:43.699126	2017-11-17 12:15:08	1
8	Paula Galansino	\\x37376535383139646563393663373534323962643339396339373661643032383561613163373136	pgalansino@agro.uba.ar	t	f	2020-05-20 03:05:54	10.1.118.10	\N	\N	0	2020-05-20 15:20:54	2017-10-11 10:02:53.21594	2018-03-19 12:23:06	1
14	Luca Scenna	\\x36353338653166316165303931346461316463393635313037353530313030383038323865306166	lscenna@agro.uba.ar	t	t	2022-03-11 11:56:04	201.212.247.94	\N	\N	0	2018-11-15 03:11:36	2018-11-12 14:48:22.871791	2018-11-13 13:24:40	1
11	Gonzalo Irisarri	\\x61306262343363323639346236376435363534633861306163356638616363316163316536613237	irisarri@agro.uba.ar	t	t	2022-03-29 11:28:24	149.155.10.167	\N		0	2018-08-21 12:08:16	2018-02-23 12:09:18.613618	2018-08-21 08:59:46	1
20	Lara	\\x34373638646363316435333633383361313533356633323231623635316239303664373539306133	lbotham@crea.org.ar	t	t	2022-03-16 20:37:39	186.96.195.183	\N		0	2019-09-27 14:39:23	2019-09-18 14:37:01.975965	2019-09-27 11:33:09	18
12	Mercedes	\\x32636633643531363138386634343339386232653661313661333364613362653738666665656461	mvassallo@crea.org.ar	t	t	2023-01-26 09:17:49	190.14.147.1	\N		0	2019-04-09 15:25:02	2018-07-12 14:19:52.981214	2018-07-12 14:20:07	18
-1	admin	\\x37393333343538393061616438333635656161353032653639623936393862633639393231663638	soporte@r2software.net	t	t	2022-12-16 10:56:24	170.51.101.153	\N	qv9kgyJO	0	2018-10-29 08:10:24	2015-08-25 00:00:00	2020-09-15 11:10:21	-1
21	Micaela Abrigo	\\x32376266323930653061643262373234656339346566353462626664633662303164393138333939	mabrigo@agro.uba.ar	t	f	2022-11-10 11:00:55	186.39.54.178	\N		0	2019-10-31 14:28:25	2019-10-31 11:18:10.010935	2019-10-31 11:18:17	1
30	Evelyn Schibber	\\x65313665373866643265313537306364383431373036636636646331326466366162626532626663	eschibber@agro.uba.ar	t	t	2023-01-31 10:18:34	157.92.96.250	\N		0	2021-07-15 19:16:00	2021-07-15 15:41:20.009627	2021-07-15 15:41:56	1
29	Sebastian Nullo	\\x62306139343561303964326633383138333437323536643331363538313835386463643038636432	snullo@agro.uba.ar	t	t	2022-04-27 13:40:09	10.1.18.24	\N	\N	0	2021-03-17 17:06:18	2021-03-17 08:45:36.564639	2021-03-17 08:45:47	1
32	Lorena Ospino Cano	\\x64336161376234643331383265326165363964373737303261646430383739643733336461386438	lospino@agro.uba.ar	t	t	2023-02-06 12:42:37	186.136.209.146	\N		0	2022-02-17 11:48:29	2022-02-14 08:37:44.813348	2022-02-15 13:54:58	1
18	Matias Curcio	\\x63653036333165633562393765636664303665623630656261353133326563633964383438326237	mcurcio@agro.uba.ar	t	f	2022-08-26 09:30:11	190.216.64.214	\N		0	2019-07-11 14:27:02	2019-07-11 11:25:53.312749	2019-07-11 11:25:59	1
25	Hernan Torres	\\x36383837613132666131663337383330386163613231613932333036366362373233653238663861	htorres@agro.uba.ar	t	t	2022-04-21 12:47:03	190.194.153.13	\N	\N	0	2020-11-24 16:50:13	2020-10-14 08:19:34.846593	2020-10-14 08:20:42	1
5	Facundo Della Nave	\\x39373266626137303832306338396132626239623734653036373239356330366362643536396266	dellanave@agro.uba.ar	t	f	2023-01-17 17:07:28	190.244.77.194	\N	\N	0	2018-12-05 04:12:32	2015-08-25 00:00:00	2017-11-29 10:09:58	1
-2	Dolores Arocena	\\x63356161353835323465333634316161653764646533353864643463666366653066373663643036	arocena@agro.uba.ar	t	t	2022-07-24 10:07:07	190.133.182.63	\N	\N	1	2017-12-26 05:12:42	2017-09-07 17:25:30.598891	\N	1
17	Mercedes IPA	\\x32636633643531363138386634343339386232653661313661333364613362653738666665656461	mvassall@agro.uba.ar	t	t	2023-01-06 14:27:24	181.1.40.80	\N		0	2019-06-27 17:37:06	2019-05-23 11:53:05.714164	2019-06-27 14:36:23	1
26	Gonzalo Dieguez	\\x65333739633762376339646266386666663538353839343135636538343864626239616637643137	gdieguez@agro.uba.ar	t	t	2022-05-04 11:32:07	186.136.167.100	\N	\N	0	2020-11-24 16:50:09	2020-10-14 08:20:07.677737	2020-10-14 08:20:31	1
28	Eugenia Alzueta	\\x30373431316334346261393735663933643666326131393436336639643836363635663138316137	alzueta@agro.uba.ar	t	t	2023-02-02 08:34:01	10.1.105.58	\N	\N	0	2021-03-03 22:10:27	2021-02-11 10:19:02.065365	2021-02-11 10:19:12	1
33	Alejandro Biffis	\\x38303535636530336437643865646436643465363065376134393331316534323562343131353533	abiffis@agro.uba.ar	t	t	2023-02-02 12:54:25	10.1.34.5	\N		0	2022-02-17 11:48:21	2022-02-14 08:38:31.049609	2022-02-15 13:54:53	1
10	Magdalena	\\x39643437356339643466323336633163306535343263313430363966613332366539373038656337	mfernandez@crea.org.ar	t	t	2023-02-03 09:54:28	10.1.1.13	\N		0	2018-07-12 05:07:32	2017-12-26 09:34:28.670209	2018-07-12 14:21:53	18
\.


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: r2
--

SELECT pg_catalog.setval('public.users_id_seq', 33, true);


--
-- PostgreSQL database dump complete
--
