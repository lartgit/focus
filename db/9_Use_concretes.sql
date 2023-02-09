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
-- Data for Name: use_concretes; Type: TABLE DATA; Schema: public; Owner: r2
--

COPY public.use_concretes (id, name, ts, created_at) FROM stdin;
60	Alfalfa	2017-12-26 07:12:18	2017-12-26 16:45:18.645521
61	-	2017-12-26 07:12:29	2017-12-26 16:45:29.043327
62	Arroz	2017-12-26 07:12:37	2017-12-26 16:45:37.616109
68	Fina	2017-12-26 07:12:38	2017-12-26 16:46:38.126733
69	Forestacion	2017-12-26 07:12:45	2017-12-26 16:46:45.648985
70	Gruesa	2017-12-26 07:12:53	2017-12-26 16:46:53.858967
73	Rastrojo	2017-12-26 07:12:13	2017-12-26 16:47:13.808382
88	Pastizal	2018-03-01 05:03:11	2018-03-01 14:30:11.615177
90	Estepa	2018-04-13 05:04:49	2018-04-13 14:13:49.897511
91	Mallin	2018-04-13 05:04:59	2018-04-13 14:13:59.969811
92	Bosque	2018-05-17 01:05:48	2018-05-17 10:53:48.40714
93	Agricultura	2018-07-26 06:07:20	2018-07-26 15:33:20.52117
96	Avena	2018-07-26 06:07:40	2018-07-26 15:33:40.017035
97	Barbecho	2018-07-26 06:07:49	2018-07-26 15:33:49.451808
100	Cultivos	2018-07-26 06:07:11	2018-07-26 15:34:11.947933
101	Festuca	2018-07-26 06:07:12	2018-07-26 15:35:12.513572
102	Maiz	2018-07-26 06:07:19	2018-07-26 15:35:19.585402
103	Pastura +3	2018-07-26 06:07:30	2018-07-26 15:35:30.055528
105	Soja	2018-07-26 06:07:43	2018-07-26 15:35:43.736013
107	Agropiro	2018-08-14 06:08:21	2018-08-14 15:28:21.884832
139	Pastura de festuca	2019-02-13 03:02:09	2019-02-13 12:18:09.136449
140	Pastura de gatton panic	2019-02-13 03:02:16	2019-02-13 12:18:16.144814
162	Campo natural alcalino	2019-03-06 06:03:03	2019-03-06 15:08:03.5814
74	Pastura polifitica	2018-11-20 11:11:42	2017-12-26 16:47:19.971325
75	Pastura polifitica de 2 anos	2018-11-20 11:11:43	2017-12-26 16:47:25.343135
76	Pastura polifitica de 3 anos	2018-11-20 11:11:51	2017-12-26 16:47:30.336263
77	Pastura polifitica de 4 anos	2018-11-20 11:11:57	2017-12-26 16:47:37.546472
78	Pastura polifitica de 5 anos	2018-11-20 11:11:09	2017-12-26 16:47:46.094443
79	Pastura polifitica degradada	2018-11-20 11:11:18	2017-12-26 16:47:53.708726
141	Pastura de gatton y buffel	2019-02-13 03:02:23	2019-02-13 12:18:23.899299
163	Campo natural bajo dulce	2019-03-06 06:03:09	2019-03-06 15:08:09.009157
164	Campo natural loma	2019-03-06 06:03:13	2019-03-06 15:08:13.34514
165	Campo natural media loma	2019-03-06 06:03:18	2019-03-06 15:08:18.219539
166	Sin datos	2019-05-21 19:42:23	2019-05-21 16:42:23.912233
142	Pastura de gatton y gramma	2019-02-13 03:02:37	2019-02-13 12:18:37.533599
80	Pastura polifitica de implantacion	2018-12-06 03:12:19	2017-12-26 16:48:02.626948
115	Cebadilla	2018-12-06 03:12:26	2018-12-06 12:49:26.235762
116	Nabo	2018-12-06 03:12:35	2018-12-06 12:49:35.072401
117	Trigo	2018-12-06 03:12:42	2018-12-06 12:49:42.093407
120	Silvopastoril	2019-02-07 06:02:21	2019-02-07 15:17:21.216319
121	Alpiste grano	2019-02-13 03:02:12	2019-02-13 12:12:12.898529
122	Avena grano	2019-02-13 03:02:23	2019-02-13 12:12:23.275111
63	Campo natural	2019-02-13 03:02:38	2017-12-26 16:45:44.560309
64	Campo natural mejorado	2019-02-13 03:02:55	2017-12-26 16:45:53.68926
167	Campo natural bajo salino	2019-08-05 20:00:10	2019-08-05 17:00:10.391848
168	Pastura de panicum coloratum	2019-10-18 18:32:19	2019-10-18 15:32:19.83969
72	Monte nativo	2019-02-13 03:02:16	2017-12-26 16:47:08.483026
110	Pastura de holcus	2019-02-13 03:02:41	2018-11-20 08:21:51.236249
71	Pastura de lotus	2019-02-13 03:02:46	2017-12-26 16:46:59.718859
112	Pastura de pensacola	2019-02-13 03:02:49	2018-11-20 08:27:29.382681
111	Pastura de setaria	2019-02-13 03:02:52	2018-11-20 08:27:18.457228
114	Pastura de trebol rojo	2019-02-13 03:02:57	2018-11-20 08:56:23.837697
84	Siembra en cobertura	2019-02-13 03:02:01	2017-12-26 16:48:39.678657
118	Verdeo de moha	2019-02-13 03:02:05	2018-12-06 12:49:50.076438
82	Verdeo de raigras	2019-02-13 03:02:08	2017-12-26 16:48:19.862334
113	Verdeo de sorgo forrajero	2019-02-13 03:02:12	2018-11-20 08:27:51.465444
119	Verdeo de sudan	2019-02-13 03:02:14	2018-12-06 12:49:55.745462
169	Matorral	2019-10-18 18:32:50	2019-10-18 15:32:50.912572
170	Campo natural inundable	2020-02-03 18:34:17	2020-02-03 15:34:17.38758
123	Campo natural con agropiro	2019-02-13 03:02:56	2019-02-13 12:14:56.321809
124	Campo natural con festuca	2019-02-13 03:02:05	2019-02-13 12:15:05.402984
125	Cebada grano	2019-02-13 03:02:14	2019-02-13 12:15:14.144908
126	Centeno grano	2019-02-13 03:02:21	2019-02-13 12:15:21.92983
127	Colza grano	2019-02-13 03:02:29	2019-02-13 12:15:29.223674
128	Girasol	2019-02-13 03:02:39	2019-02-13 12:15:39.249432
129	Lino	2019-02-13 03:02:47	2019-02-13 12:15:47.249002
130	Maiz grano	2019-02-13 03:02:55	2019-02-13 12:15:55.52106
131	Mijo grano	2019-02-13 03:02:04	2019-02-13 12:16:04.867675
132	Pastura consociada	2019-02-13 03:02:38	2019-02-13 12:16:38.266173
133	Monte	2019-02-13 03:02:48	2019-02-13 12:16:48.01093
134	Pastura de agropiro y festuca	2019-02-13 03:02:56	2019-02-13 12:16:56.983087
135	Pastura de alfalfa pura	2019-02-13 03:02:05	2019-02-13 12:17:05.726076
136	Pastura de brachiaria	2019-02-13 03:02:14	2019-02-13 12:17:14.930053
137	Pastura de buffel grass	2019-02-13 03:02:28	2019-02-13 12:17:28.556392
138	Pastura de digitaria	2019-02-13 03:02:00	2019-02-13 12:18:00.988391
143	Pastura de gramma	2019-02-13 03:02:45	2019-02-13 12:18:45.609241
144	Pastura de lloron	2019-02-13 03:02:27	2019-02-13 12:19:27.280217
146	Pastura base alfalfa	2019-02-13 03:02:13	2019-02-13 12:20:13.057669
147	Promocion de raigras	2019-02-13 03:02:20	2019-02-13 12:20:20.389553
149	Soja grano	2019-02-13 03:02:42	2019-02-13 12:20:42.890582
150	Sorgo grano	2019-02-13 03:02:50	2019-02-13 12:20:50.953693
151	Trigo grano	2019-02-13 03:02:08	2019-02-13 12:21:08.22451
152	Verdeo de avena	2019-02-13 03:02:18	2019-02-13 12:21:18.312431
153	Verdeo de avena y vicia	2019-02-13 03:02:27	2019-02-13 12:21:27.37639
154	Verdeo de cebada	2019-02-13 03:02:36	2019-02-13 12:21:36.041207
155	Verdeo de centeno	2019-02-13 03:02:43	2019-02-13 12:21:43.608196
156	Verdeo de invierno	2019-02-13 03:02:52	2019-02-13 12:21:52.397871
157	Verdeo de maiz	2019-02-13 03:02:56	2019-02-13 12:21:56.74953
159	Verdeo de sorgo	2019-02-13 03:02:08	2019-02-13 12:22:08.661805
160	Verdeo de triticale	2019-02-13 03:02:15	2019-02-13 12:22:15.710819
161	Verdeo de verano	2019-02-13 03:02:30	2019-02-13 12:22:22.254466
98	Cultivo de invierno	2019-02-13 03:02:50	2018-07-26 15:33:56.735825
99	Cultivo de verano	2019-02-13 03:02:53	2018-07-26 15:34:02.265614
148	Promocion intensiva de raigras	2019-02-13 05:02:21	2019-02-13 12:20:29.006158
171	T/Moha	2020-03-04 16:23:06	2020-03-04 13:23:06.202715
172	Avena-Vicia	2020-03-04 18:08:16	2020-03-04 15:08:16.342982
173	Mijo	2020-03-04 18:10:44	2020-03-04 15:10:44.11178
174	Cebada/Moha	2020-03-04 18:12:06	2020-03-04 15:12:06.370975
175	Centeno-Vicia	2020-03-04 18:13:15	2020-03-04 15:13:15.311906
176	T/VI	2020-03-04 18:16:27	2020-03-04 15:16:27.030825
177	Semidesierto	2020-03-05 16:16:01	2020-03-05 13:16:01.579644
178	Agua/Nieve permanente	2020-03-05 16:16:25	2020-03-05 13:16:25.212335
179	Estepa arbustiva	2020-03-05 16:16:37	2020-03-05 13:16:37.666834
180	Estepa arbustiva graminosa	2020-03-05 16:16:50	2020-03-05 13:16:50.801145
181	Estepa graminosa arbustiva/estepa graminosa	2020-03-05 16:17:10	2020-03-05 13:17:10.433022
183	Erial	2020-04-29 21:20:02	2020-04-29 18:20:02.169436
184	Estepa graminosa rala	2020-04-29 21:30:14	2020-04-29 18:30:14.418716
185	Pastura de agropiro	2020-05-05 12:59:50	2020-05-05 09:59:50.371917
188	Arbustal puneño de ladera y bajadas aluviales	2020-06-10 18:48:05	2020-06-10 15:48:05.271716
189	Arbustal puneño de planicie	2020-06-10 18:48:10	2020-06-10 15:48:10.196001
190	Arbustal puneño de quebradas y terrazas fluviales	2020-06-10 18:48:15	2020-06-10 15:48:15.14191
192	Pastizal de neblina	2020-06-10 18:48:26	2020-06-10 15:48:26.424983
193	Pastizal puneño abierto alto	2020-06-10 18:48:31	2020-06-10 15:48:31.778411
194	Pastizal puneño abierto bajo	2020-06-10 18:48:38	2020-06-10 15:48:38.370869
195	Pastizal puneño cerrado	2020-06-10 18:48:42	2020-06-10 15:48:42.996797
196	Vegas de altura	2020-06-10 18:48:47	2020-06-10 15:48:47.581853
191	Arbustal puneño denso de pedemonte	2020-06-10 21:13:19	2020-06-10 15:48:20.627479
186	Arbustal de monte de sierras y bolsones	2020-06-10 21:13:48	2020-06-10 15:47:44.951862
187	Arbustal puneño abierto de pedemonte	2020-06-10 21:16:38	2020-06-10 15:47:58.766738
197	Sabana	2020-07-07 21:33:36	2020-07-07 18:33:36.698965
198	Malezal	2020-07-07 21:33:53	2020-07-07 18:33:53.408827
199	Ralera	2020-07-07 21:34:08	2020-07-07 18:34:08.325582
200	Pajonal	2020-07-07 21:34:42	2020-07-07 18:34:42.193566
201	Campo natural restaurado	2020-07-27 18:55:18	2020-07-27 15:55:18.462099
202	Pradera permanente +3 anos	2020-07-27 19:08:53	2020-07-27 16:08:53.841945
203	Pradera permanente 3er ano	2020-07-27 19:09:01	2020-07-27 16:09:01.118073
204	Pradera permanente 2do ano	2020-07-27 19:09:06	2020-07-27 16:09:06.759642
205	Pradera permanente 1er ano	2020-07-27 19:09:14	2020-07-27 16:09:14.716561
206	gatton prueba	2020-08-31 20:52:20	2020-08-31 17:52:20.142776
207	Pastura de alfalfa pura prueba	2020-09-10 22:06:08	2020-09-10 19:06:08.934047
208	Pastura de lloron prueba	2020-09-10 22:08:46	2020-09-10 19:08:46.46638
209	Arbustal exotico	2020-10-01 14:12:17	2020-10-01 11:12:17.393045
210	Arboles exoticos	2020-10-01 14:31:00	2020-10-01 11:31:00.27992
211	Arbustal nativo	2020-10-01 14:32:19	2020-10-01 11:32:19.575121
212	Caña	2020-10-01 14:36:10	2020-10-01 11:36:10.182664
213	Cipres	2020-10-01 14:37:15	2020-10-01 11:37:15.561165
214	Cipres-Nire	2020-10-01 14:39:41	2020-10-01 11:39:41.376078
215	Cipres-Nire bajo	2020-10-01 14:40:38	2020-10-01 11:40:38.137182
216	Coihue	2020-10-01 14:41:32	2020-10-01 11:41:32.116828
217	Lenga	2020-10-01 14:43:58	2020-10-01 11:43:58.338071
218	Lenga achaparrada	2020-10-01 14:45:25	2020-10-01 11:45:25.332716
219	Matorral mixto	2020-10-01 14:47:06	2020-10-01 11:47:06.093086
220	Nire	2020-10-01 14:48:01	2020-10-01 11:48:01.144703
221	Nire bajo	2020-10-01 14:49:49	2020-10-01 11:49:49.389393
222	Nire bajo-Cipres	2020-10-01 14:50:19	2020-10-01 11:50:19.490805
223	Nire-Cipres	2020-10-01 14:50:56	2020-10-01 11:50:56.145818
224	Avena sobre girasol	2020-11-24 17:21:01	2020-11-24 14:21:01.03732
225	Rastrojo girasol + maiz	2020-11-24 17:37:16	2020-11-24 14:37:16.726731
226	Rastrojo soja	2020-11-24 17:44:03	2020-11-24 14:44:03.037678
227	Pastura consociada	2020-11-24 18:03:37	2020-11-24 15:03:37.84929
228	Siembra raigras	2020-11-24 18:19:49	2020-11-24 15:19:49.849175
229	Cultivo cobertura	2020-12-18 19:54:14	2020-12-18 16:40:40.304092
230	Maiz diferido	2020-12-18 19:54:54	2020-12-18 16:54:54.483827
231	Mani	2020-12-18 19:59:45	2020-12-18 16:59:45.660416
232	Sorgo diferido	2020-12-18 20:02:35	2020-12-18 17:02:35.840091
233	Maiz silo	2020-12-18 20:06:36	2020-12-18 17:06:36.573829
234	Pastura de lloron SL	2021-03-31 21:55:58	2021-03-31 18:55:58.734971
235	Pastura de alfalfa pura SL	2021-03-31 21:56:24	2021-03-31 18:56:24.946848
236	Pastura de buffel grass con renoval	2022-04-06 17:27:24	2022-04-06 14:27:24.154047
237	Pastura de gatton panic con renoval	2022-04-06 17:27:56	2022-04-06 14:27:56.113376
238	Pastura de panicum coloratum y gramma	2022-07-22 14:26:56	2022-07-22 11:26:56.269607
\.


--
-- Name: use_concretes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: r2
--

SELECT pg_catalog.setval('public.use_concretes_id_seq', 238, true);


--
-- PostgreSQL database dump complete
--

