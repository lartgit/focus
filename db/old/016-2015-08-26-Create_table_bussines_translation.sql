BEGIN;

/*
*Tabla para manejar el Lenguage de la Aplicacion.
*
*/
CREATE TABLE public.business_objects_translations
(
  id serial NOT NULL,
  current_name character varying(100) NOT NULL,
  spanish_translation character varying(100) DEFAULT ''::character varying,
  english_translation character varying(100) DEFAULT ''::character varying,
  ts timestamp without time zone DEFAULT now(),
  CONSTRAINT business_objects_translations_pkey PRIMARY KEY (id)
);

COMMIT;