--Tablas Inicales del Sistema Focus-LART
--aramirez
BEGIN;

--Agrego el Public por si en el futuro lo tenemos que utilzar en otro schema

--*CLIENTE DATA TABLES*--
CREATE TABLE public.clients
(
  id serial NOT NULL,
  name character varying(50) NOT NULL,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  created_at timestamp(6) without time zone NOT NULL DEFAULT now(),
  CONSTRAINT clients_pk PRIMARY KEY (id)
);

CREATE TABLE public.projects
(
  id serial NOT NULL,
  name character varying(50) NOT NULL,
  ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  created_at timestamp(6) without time zone NOT NULL DEFAULT now(),
  client_id integer NOT NULL,
  CONSTRAINT projects_pk PRIMARY KEY (id),
  CONSTRAINT projects_to_client_id_fkey FOREIGN KEY (client_id)
      REFERENCES clients (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE
);



CREATE TABLE public.sub_projects
(
  id serial NOT NULL,
  name character varying(50) NOT NULL,
  ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  created_at timestamp(6) without time zone NOT NULL DEFAULT now(),
  project_id integer NOT NULL,
  CONSTRAINT sub_projects_pk PRIMARY KEY (id),
  CONSTRAINT sub_projecs_to_project_id_fkey FOREIGN KEY (project_id)
      REFERENCES projects (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE
);

CREATE TABLE public.versions
(
  id serial NOT NULL,
  name character varying(50) NOT NULL,
  ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  created_at timestamp(6) without time zone NOT NULL DEFAULT now(),
  sub_project_id integer NOT NULL,
  CONSTRAINT versions_pk PRIMARY KEY (id),
  CONSTRAINT versions_to_sub_project_id_fkey FOREIGN KEY (sub_project_id)
      REFERENCES sub_projects (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE
);

--***END CLIENTE DATA TABLES***---

--*CLIENTE USO/INPUT TABLES*--
CREATE TABLE public.farms
(
  id serial NOT NULL,
  name character varying(50) NOT NULL,
  ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  created_at timestamp(6) without time zone NOT NULL DEFAULT now(),
  version_id integer NOT NULL,
  CONSTRAINT farms_pk PRIMARY KEY (id),
  CONSTRAINT farms_to_version_id_fkey FOREIGN KEY (version_id)
      REFERENCES versions (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE
);

CREATE TABLE public.fields
(
  id serial NOT NULL,
  name character varying(50) NOT NULL,
  date_from date,
  date_to date,
  the_geom polygon,
  ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  created_at timestamp(6) without time zone NOT NULL DEFAULT now(),
  farm_id integer NOT NULL,
  CONSTRAINT fields_pk PRIMARY KEY (id),
  CONSTRAINT fields_to_farm_id_fkey FOREIGN KEY (farm_id)
      REFERENCES farms (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE
);


--*****Ordeno esta tabla por el Constraint de la tabla Declarations.

CREATE TABLE public.use_declareds
(
  id serial NOT NULL,
  name character varying(50) NOT NULL,
  ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  created_at timestamp(6) without time zone NOT NULL DEFAULT now(),
  CONSTRAINT use_declareds_pk PRIMARY KEY (id)
);


CREATE TABLE public.use_concretes
(
  id serial NOT NULL,
  name character varying(50) NOT NULL,
  ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  created_at timestamp(6) without time zone NOT NULL DEFAULT now(),
  CONSTRAINT use_concretes_pk PRIMARY KEY (id)
);


CREATE TABLE public.declarations
(
  id serial NOT NULL,
  ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  created_at timestamp(6) without time zone NOT NULL DEFAULT now(),
  date date NOT NULL,
  use_declared_id integer NOT NULL,
  field_id integer NOT NULL,
  CONSTRAINT declarations_pk PRIMARY KEY (id),
  CONSTRAINT declarations_to_field_id_fkey FOREIGN KEY (field_id)
      REFERENCES fields (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT declarations_to_use_declared_id_fkey FOREIGN KEY (use_declared_id)
      REFERENCES use_declareds (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT unique_constraint_date_field_id UNIQUE (date, field_id)
);

--***END CLIENTE USO/INPUT TABLES***---


--*SYSTEM CONFIGURATIONS TABLES*--
CREATE TABLE public.pixel_sets
(
  id serial NOT NULL,
  name character varying(50) NOT NULL,
  ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  created_at timestamp(6) without time zone NOT NULL DEFAULT now(),
  CONSTRAINT pixel_sets_pk PRIMARY KEY (id)
);


CREATE TABLE public.users
(
  id serial NOT NULL,
  name character varying(50) NOT NULL,
  password bytea NOT NULL DEFAULT ''::bytea,
  email character varying(320) NOT NULL,
  active boolean NOT NULL DEFAULT true,
  is_admin boolean NOT NULL DEFAULT false,
  last_login timestamp without time zone,
  last_ip inet,
  inactive_reason character varying(500),
  activation_code character varying(10),
  failed_login_count integer DEFAULT 0,
  ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  created_at timestamp(6) without time zone NOT NULL DEFAULT now(),
  CONSTRAINT users_pk PRIMARY KEY (id)
);


CREATE TABLE public.user_groups
(
  id serial NOT NULL,
  name character varying(50) NOT NULL,
  active boolean NOT NULL DEFAULT true,
  ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  created_at timestamp(6) without time zone NOT NULL DEFAULT now(),
  CONSTRAINT user_groups_pk PRIMARY KEY (id)
);


CREATE TABLE public.users_by_groups
(
  id serial NOT NULL,
  user_id INTEGER NOT NULL,
  user_group_id INTEGER NOT NULL,
  CONSTRAINT user_by_groups_pk PRIMARY KEY (id),
  CONSTRAINT users_by_groups_to_user_id_fkey FOREIGN KEY (user_id)
      REFERENCES users(id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT users_by_groups_to_user_groups_id_fkey FOREIGN KEY (user_group_id)
      REFERENCES user_groups(id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE
);

COMMIT;