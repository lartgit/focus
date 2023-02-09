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
-- Data for Name: use_declareds; Type: TABLE DATA; Schema: public; Owner: r2
--

COPY public.use_declareds (id, name, ts, created_at, description) FROM stdin;
47	-	2017-12-26 07:12:54	2017-12-26 16:33:54.783718	No utilizable
48	Alfalfa	2017-12-26 07:12:02	2017-12-26 16:34:02.656534	\N
55	Fina	2017-12-26 07:12:00	2017-12-26 16:36:00.906768	\N
56	Forestacion	2017-12-26 07:12:08	2017-12-26 16:36:08.591189	\N
57	Gruesa	2017-12-26 07:12:16	2017-12-26 16:36:16.033558	\N
60	Rastrojo	2017-12-26 07:12:36	2017-12-26 16:36:36.590686	\N
49	Arroz	2017-12-26 07:12:37	2017-12-26 16:34:28.842856	\N
76	Pastizal	2018-03-01 05:03:29	2018-03-01 14:30:02.680997	\N
78	Estepa	2018-04-13 05:04:17	2018-04-13 14:14:17.851472	\N
79	Mallin	2018-04-13 05:04:38	2018-04-13 14:14:38.689157	\N
80	Bosque	2018-05-17 01:05:03	2018-05-17 10:53:35.820585	\N
89	Cultivos	2018-07-26 06:07:05	2018-07-26 15:32:05.57105	\N
81	Agricultura	2018-07-26 06:07:50	2018-07-26 15:30:36.98335	\N
98	Agropiro	2018-08-14 06:08:29	2018-08-14 15:27:29.873851	\N
85	Avena	2018-07-26 06:07:40	2018-07-26 15:31:28.687036	\N
86	Barbecho	2018-07-26 06:07:51	2018-07-26 15:31:42.655023	\N
90	Festuca	2018-07-26 06:07:41	2018-07-26 15:32:13.177092	\N
91	Maiz	2018-07-26 06:07:14	2018-07-26 15:32:19.094423	\N
92	Pastura +3	2018-07-26 06:07:39	2018-07-26 15:32:26.915091	\N
95	Soja	2018-07-26 06:07:26	2018-07-26 15:32:46.599009	\N
127	Pastura de buffel grass	2019-02-13 03:02:09	2019-02-13 12:39:09.454603	\N
128	Pastura de digitaria	2019-02-13 03:02:19	2019-02-13 12:39:19.725822	\N
61	Pastura polifitica	2018-11-20 11:11:24	2017-12-26 16:36:44.055814	\N
62	Pastura polifitica de 2 anos	2018-11-20 11:11:33	2017-12-26 16:36:56.768136	Pastura de 2 años
63	Pastura polifitica de 3 anos	2018-11-20 11:11:40	2017-12-26 16:37:04.272121	Pastura de 3 años
64	Pastura polifitica de 4 anos	2018-11-20 11:11:47	2017-12-26 16:37:14.271454	Pastura de 4 años
65	Pastura polifitica de 5 anos	2018-11-20 11:11:53	2017-12-26 16:37:52.23615	Pastura de 5 años
66	Pastura polifitica degradada	2018-11-20 11:11:01	2017-12-26 16:38:09.336512	Pastura Degradada
129	Pastura de festuca	2019-02-13 03:02:26	2019-02-13 12:39:26.774546	\N
150	Campo natural alcalino	2019-03-06 06:03:09	2019-03-06 15:07:09.239016	\N
151	Campo natural bajo dulce	2019-03-06 06:03:27	2019-03-06 15:07:27.470186	\N
152	Campo natural loma	2019-03-06 06:03:38	2019-03-06 15:07:38.317288	\N
153	Campo natural media loma	2019-03-06 06:03:48	2019-03-06 15:07:48.447587	\N
154	Sin datos	2019-05-21 19:42:16	2019-05-21 16:42:16.41162	\N
130	Pastura de gatton panic	2019-02-13 03:02:43	2019-02-13 12:39:43.386605	\N
131	Pastura de gatton y buffel	2019-02-13 03:02:26	2019-02-13 12:43:26.549155	\N
67	Pastura polifitica de implantacion	2018-12-06 03:12:07	2017-12-26 16:38:21.298302	\N
106	Nabo	2018-12-06 03:12:14	2018-12-06 12:47:14.095294	\N
107	Trigo	2018-12-06 03:12:31	2018-12-06 12:48:31.581487	\N
132	Pastura de gatton y gramma	2019-02-13 03:02:37	2019-02-13 12:43:37.255695	\N
105	Cebadilla	2019-02-05 01:02:22	2018-12-06 12:47:07.21002	\N
73	Silvopastoril	2019-02-07 06:02:31	2017-12-26 16:42:03.088566	\N
155	Campo natural bajo salino	2019-08-05 20:00:16	2019-08-05 17:00:16.660669	\N
59	Monte nativo	2019-02-13 03:02:18	2017-12-26 16:36:29.881893	\N
103	Pastura de holcus	2019-02-13 03:02:22	2018-11-20 08:42:37.999127	\N
58	Pastura de lotus	2019-02-13 03:02:28	2017-12-26 16:36:21.525249	\N
104	Pastura de trebol rojo	2019-02-13 03:02:38	2018-11-20 08:58:10.124069	\N
72	Siembra en cobertura	2019-02-13 03:02:51	2017-12-26 16:41:51.408681	\N
108	Verdeo de moha	2019-02-13 03:02:00	2018-12-06 12:48:40.67346	\N
70	Verdeo de raigras	2019-02-13 03:02:07	2017-12-26 16:39:47.272062	\N
96	Verdeo de sorgo forrajero	2019-02-13 03:02:17	2018-07-26 15:32:54.223059	\N
109	Verdeo de sudan	2019-02-13 03:02:26	2018-12-06 12:48:48.509455	\N
110	Alpiste grano	2019-02-13 03:02:31	2019-02-13 12:31:31.675671	\N
111	Avena grano	2019-02-13 03:02:14	2019-02-13 12:32:14.561353	\N
50	Campo natural	2019-02-13 03:02:28	2017-12-26 16:34:38.748028	\N
101	Campo natural mejorado	2019-02-13 03:02:35	2018-08-21 11:52:39.289624	\N
156	Pastura de panicum coloratum	2019-10-18 18:32:08	2019-10-18 15:32:08.352956	\N
112	Campo natural con agropiro	2019-02-13 03:02:29	2019-02-13 12:34:29.864091	\N
113	Campo natural con festuca	2019-02-13 03:02:39	2019-02-13 12:34:39.026746	\N
114	Cebada grano	2019-02-13 03:02:47	2019-02-13 12:34:47.811983	\N
115	Centeno grano	2019-02-13 03:02:55	2019-02-13 12:34:55.730451	\N
116	Colza grano	2019-02-13 03:02:20	2019-02-13 12:35:20.491492	\N
87	Cultivo de invierno	2019-02-13 03:02:19	2018-07-26 15:31:52.029117	\N
88	Cultivo de verano	2019-02-13 03:02:22	2018-07-26 15:31:58.166218	\N
117	Girasol	2019-02-13 03:02:07	2019-02-13 12:37:07.782729	\N
118	Lino	2019-02-13 03:02:22	2019-02-13 12:37:22.155444	\N
119	Maiz grano	2019-02-13 03:02:29	2019-02-13 12:37:29.8968	\N
120	Mijo grano	2019-02-13 03:02:39	2019-02-13 12:37:39.446786	\N
121	Monte	2019-02-13 03:02:46	2019-02-13 12:37:46.536585	\N
122	Pastura base alfalfa	2019-02-13 03:02:15	2019-02-13 12:38:15.64879	\N
123	Pastura consociada	2019-02-13 03:02:24	2019-02-13 12:38:24.333685	\N
124	Pastura de agropiro y festuca	2019-02-13 03:02:33	2019-02-13 12:38:33.287052	\N
125	Pastura de alfalfa pura	2019-02-13 03:02:41	2019-02-13 12:38:41.614946	\N
126	Pastura de brachiaria	2019-02-13 03:02:58	2019-02-13 12:38:58.308643	\N
133	Pastura de mijo perenne	2019-02-13 03:02:48	2019-02-13 12:43:48.50059	\N
134	Promocion de raigras	2019-02-13 03:02:00	2019-02-13 12:44:00.852478	\N
136	Soja grano	2019-02-13 03:02:23	2019-02-13 12:44:23.24265	\N
137	Sorgo grano	2019-02-13 03:02:34	2019-02-13 12:44:34.803151	\N
138	Trigo grano	2019-02-13 03:02:41	2019-02-13 12:44:41.697139	\N
139	Verdeo de avena y vicia	2019-02-13 03:02:52	2019-02-13 12:44:52.359777	\N
140	Verdeo de avena	2019-02-13 03:02:29	2019-02-13 12:45:29.292402	\N
141	Verdeo de cebada	2019-02-13 03:02:44	2019-02-13 12:45:44.991585	\N
142	Verdeo de centeno	2019-02-13 03:02:49	2019-02-13 12:45:49.023056	\N
75	Verdeo de invierno	2019-02-13 03:02:06	2017-12-26 16:42:19.860833	\N
74	Verdeo de verano	2019-02-13 03:02:09	2017-12-26 16:42:14.259263	\N
143	Verdeo de maiz	2019-02-13 03:02:41	2019-02-13 12:46:41.311027	\N
144	Verdeo de sorgo	2019-02-13 03:02:55	2019-02-13 12:46:55.214429	\N
145	Verdeo de triticale	2019-02-13 03:02:13	2019-02-13 12:47:13.950897	\N
146	Pastura de gramma	2019-02-13 03:02:32	2019-02-13 12:49:32.152357	\N
147	Pastura de lloron	2019-02-13 03:02:54	2019-02-13 12:49:54.668398	\N
148	Pastura de pensacola	2019-02-13 03:02:22	2019-02-13 12:50:22.386156	\N
149	Pastura de setaria	2019-02-13 03:02:37	2019-02-13 12:50:37.162438	\N
135	Promocion intensiva de raigras	2019-02-13 05:02:42	2019-02-13 12:44:13.273851	\N
157	Matorral	2019-10-18 18:32:44	2019-10-18 15:32:44.238538	\N
158	Campo natural inundable	2020-02-03 18:34:07	2020-02-03 15:34:07.80831	\N
159	T/Moha	2020-03-04 16:23:01	2020-03-04 13:23:01.404063	\N
160	Avena-Vicia	2020-03-04 18:08:08	2020-03-04 15:08:08.471621	\N
161	Mijo	2020-03-04 18:10:39	2020-03-04 15:10:39.431005	\N
162	Cebada/Moha	2020-03-04 18:12:01	2020-03-04 15:12:01.436257	\N
163	Centeno-Vicia	2020-03-04 18:13:10	2020-03-04 15:13:10.256329	\N
164	T/VI	2020-03-04 18:16:42	2020-03-04 15:16:42.175069	\N
165	Semidesierto	2020-03-05 16:17:37	2020-03-05 13:17:37.0368	\N
166	Agua/Nieve permanente	2020-03-05 16:17:50	2020-03-05 13:17:50.274647	\N
167	Estepa arbustiva	2020-03-05 16:18:01	2020-03-05 13:18:01.940016	\N
168	Estepa arbustiva graminosa	2020-03-05 16:18:06	2020-03-05 13:18:06.463008	\N
169	Estepa graminosa arbustiva/estepa graminosa	2020-03-05 16:18:10	2020-03-05 13:18:10.654449	\N
170	Erial	2020-04-29 21:19:55	2020-04-29 18:19:55.360989	\N
171	Estepa graminosa rala	2020-04-29 21:30:07	2020-04-29 18:30:07.121625	\N
174	Arbustal puneño de ladera y bajadas aluviales	2020-06-10 18:45:14	2020-06-10 15:45:14.475317	\N
175	Arbustal puneño de planicie	2020-06-10 18:45:26	2020-06-10 15:45:26.267556	\N
176	Arbustal puneño de quebradas y terrazas fluviales	2020-06-10 18:45:33	2020-06-10 15:45:33.571751	\N
178	Pastizal de neblina	2020-06-10 18:45:49	2020-06-10 15:45:49.473576	\N
179	Pastizal puneño abierto alto	2020-06-10 18:45:54	2020-06-10 15:45:54.656503	\N
180	Pastizal puneño abierto bajo	2020-06-10 18:46:00	2020-06-10 15:46:00.774016	\N
181	Pastizal puneño cerrado	2020-06-10 18:46:06	2020-06-10 15:46:06.96014	\N
182	Vegas de altura	2020-06-10 18:46:14	2020-06-10 15:46:14.945038	\N
177	Arbustal puneño denso de pedemonte	2020-06-10 21:13:11	2020-06-10 15:45:41.942677	\N
172	Arbustal de monte de sierras y bolsones	2020-06-10 21:13:39	2020-06-10 15:44:59.961445	\N
173	Arbustal puneño abierto de pedemonte	2020-06-10 21:16:47	2020-06-10 15:45:06.377312	\N
183	Campo natural restaurado	2020-07-27 18:55:14	2020-07-27 15:55:14.18691	\N
184	Pradera permanente 1er ano	2020-07-27 19:08:31	2020-07-27 16:08:31.135047	\N
185	Pradera permanente 2do ano	2020-07-27 19:08:37	2020-07-27 16:08:37.515374	\N
186	Pradera permanente 3er ano	2020-07-27 19:08:43	2020-07-27 16:08:43.191178	\N
187	Pradera permanente +3 anos	2020-07-27 19:08:49	2020-07-27 16:08:49.742213	\N
188	Arbustal exotico	2020-10-01 14:30:52	2020-10-01 11:12:05.826765	Originalmente Arbus Ex\r\n\r\nObtenido de https://drive.google.com/file/d/1-IAdNy1B7cTGSDAA69w1-Ruw_9APFk98/view?usp=sharing
190	Arbustal nativo	2020-10-01 14:32:08	2020-10-01 11:32:08.828015	Originalmente Arbus Na\r\n\r\nObtenido de https://drive.google.com/file/d/1-IAdNy1B7cTGSDAA69w1-Ruw_9APFk98/view?usp=sharing
192	Cipres	2020-10-01 14:37:09	2020-10-01 11:37:09.342706	Originalmente Ci\r\n\r\nObtenido de https://drive.google.com/file/d/1-IAdNy1B7cTGSDAA69w1-Ruw_9APFk98/view?usp=sharing
193	Cipres-Nire	2020-10-01 14:39:27	2020-10-01 11:39:22.596624	Originalmente Ci-Ñi\r\n\r\nObtenido de https://drive.google.com/file/d/1-IAdNy1B7cTGSDAA69w1-Ruw_9APFk98/view?usp=sharing
194	Cipres-Nire bajo	2020-10-01 14:40:28	2020-10-01 11:40:28.945992	Originalmente Ci-Ñi Baj\r\n\r\nObtenido de https://drive.google.com/file/d/1-IAdNy1B7cTGSDAA69w1-Ruw_9APFk98/view?usp=sharing
195	Coihue	2020-10-01 14:41:17	2020-10-01 11:41:11.448657	Originalmente Co\r\n\r\nObtenido de https://drive.google.com/file/d/1-IAdNy1B7cTGSDAA69w1-Ruw_9APFk98/view?usp=sharing
196	Lenga	2020-10-01 14:43:53	2020-10-01 11:43:53.185367	Originalmente Le\r\n\r\nObtenido de https://drive.google.com/file/d/1-IAdNy1B7cTGSDAA69w1-Ruw_9APFk98/view?usp=sharing
197	Lenga achaparrada	2020-10-01 14:44:57	2020-10-01 11:44:47.836809	Originalmente Le Ach\r\n\r\nObtenido de https://drive.google.com/file/d/1-IAdNy1B7cTGSDAA69w1-Ruw_9APFk98/view?usp=sharing
189	Arboles exoticos	2020-10-01 14:45:14	2020-10-01 11:30:28.194205	Originalmente Arles Ex\r\n\r\nObtenido de https://drive.google.com/file/d/1-IAdNy1B7cTGSDAA69w1-Ruw_9APFk98/view?usp=sharing
198	Matorral mixto	2020-10-01 14:46:19	2020-10-01 11:46:19.329324	Originalmente MMx\r\n\r\nObtenido de https://drive.google.com/file/d/1-IAdNy1B7cTGSDAA69w1-Ruw_9APFk98/view?usp=sharing
199	Nire	2020-10-01 14:47:55	2020-10-01 11:47:55.196722	Originalmente Ñi\r\n\r\nObtenido de https://drive.google.com/file/d/1-IAdNy1B7cTGSDAA69w1-Ruw_9APFk98/view?usp=sharing
200	Nire bajo	2020-10-01 14:49:40	2020-10-01 11:49:40.841298	Originalmente Ñi Baj\r\n\r\nObtenido de https://drive.google.com/file/d/1-IAdNy1B7cTGSDAA69w1-Ruw_9APFk98/view?usp=sharing
201	Nire bajo-Cipres	2020-10-01 14:50:12	2020-10-01 11:50:12.307371	Originalmente Ñi Baj-Ci\r\n\r\nObtenido de https://drive.google.com/file/d/1-IAdNy1B7cTGSDAA69w1-Ruw_9APFk98/view?usp=sharing
202	Nire-Cipres	2020-10-01 14:50:48	2020-10-01 11:50:48.492362	Originalmente Ñi-Ci\r\n\r\nObtenido de https://drive.google.com/file/d/1-IAdNy1B7cTGSDAA69w1-Ruw_9APFk98/view?usp=sharing
203	CN	2020-10-14 11:57:03	2020-10-14 08:57:03.987168	\N
204	Avena sobre girasol	2020-11-24 17:20:43	2020-11-24 14:20:43.692311	\N
205	Rastrojo girasol + maiz	2020-11-24 17:36:56	2020-11-24 14:36:56.923533	\N
206	Rastrojo soja	2020-11-24 17:43:48	2020-11-24 14:43:48.177284	\N
207	Pastura consociada	2020-11-24 18:03:21	2020-11-24 15:03:21.98833	\N
208	Siembra raigras	2020-11-24 18:19:36	2020-11-24 15:19:36.243687	\N
191	Caña	2020-11-25 10:14:43	2020-10-01 11:35:33.283843	Originalmente Caña\r\n\r\nObtenido de https://drive.google.com/file/d/1-IAdNy1B7cTGSDAA69w1-Ruw_9APFk98/view?usp=sharing
209	Cultivo cobertura	2020-12-18 19:54:03	2020-12-18 16:40:11.920695	\N
210	Maiz diferido	2020-12-18 19:54:41	2020-12-18 16:54:41.012824	\N
211	Mani	2020-12-18 19:59:34	2020-12-18 16:59:34.304055	\N
212	Sorgo diferido	2020-12-18 20:02:21	2020-12-18 17:02:21.297052	\N
213	Maiz silo	2020-12-18 20:06:21	2020-12-18 17:06:21.497336	\N
214	Pastura de buffel grass con renoval	2022-04-06 17:16:30	2022-04-06 14:16:30.68187	\N
215	Pastura de gatton panic con renoval	2022-04-06 17:17:10	2022-04-06 14:17:10.972816	\N
216	Pastura de panicum coloratum y gramma	2022-07-22 14:29:08	2022-07-22 11:29:08.760959	\N
\.


--
-- Name: use_declareds_id_seq; Type: SEQUENCE SET; Schema: public; Owner: r2
--

SELECT pg_catalog.setval('public.use_declareds_id_seq', 216, true);


--
-- PostgreSQL database dump complete
--

