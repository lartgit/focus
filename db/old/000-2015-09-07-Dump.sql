
BEGIN;

--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;


CREATE EXTENSION postgis;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: business_objects_translations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE business_objects_translations (
    id integer NOT NULL,
    current_name character varying(100) NOT NULL,
    spanish_translation character varying(100) DEFAULT ''::character varying,
    english_translation character varying(100) DEFAULT ''::character varying,
    ts timestamp without time zone DEFAULT now()
);


--
-- Name: business_objects_translations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE business_objects_translations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: business_objects_translations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE business_objects_translations_id_seq OWNED BY business_objects_translations.id;


--
-- Name: business_objects_translations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('business_objects_translations_id_seq', 1, false);


--
-- Name: clients; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE clients (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    active boolean DEFAULT true NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL
);


--
-- Name: clients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE clients_id_seq OWNED BY clients.id;


--
-- Name: clients_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('clients_id_seq', 1, false);


--
-- Name: concretes_by_declareds; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE concretes_by_declareds (
    id integer NOT NULL,
    declared_id integer NOT NULL,
    concrete_id integer NOT NULL
);


--
-- Name: concretes_by_declareds_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE concretes_by_declareds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: concretes_by_declareds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE concretes_by_declareds_id_seq OWNED BY concretes_by_declareds.id;


--
-- Name: concretes_by_declareds_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('concretes_by_declareds_id_seq', 1, false);


--
-- Name: dates; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE dates (
    id integer NOT NULL,
    set_id integer NOT NULL,
    date date NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL
);


--
-- Name: dates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE dates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: dates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE dates_id_seq OWNED BY dates.id;


--
-- Name: dates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('dates_id_seq', 1, false);


--
-- Name: db_actions_logs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE db_actions_logs (
    id integer NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    event character varying(30) NOT NULL,
    user_id integer NOT NULL,
    description text,
    object_class character varying(50) NOT NULL,
    object_id character varying(30) NOT NULL,
    object character varying
);


--
-- Name: db_actions_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE db_actions_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: db_actions_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE db_actions_logs_id_seq OWNED BY db_actions_logs.id;


--
-- Name: db_actions_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('db_actions_logs_id_seq', 1, false);


--
-- Name: declarations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE declarations (
    id integer NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    date date,
    use_declared_id integer NOT NULL,
    field_id integer NOT NULL,
    active boolean DEFAULT true NOT NULL,
    date_from date,
    date_to date
);


--
-- Name: declarations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE declarations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: declarations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE declarations_id_seq OWNED BY declarations.id;


--
-- Name: declarations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('declarations_id_seq', 1, false);


--
-- Name: farms; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE farms (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    version_id integer NOT NULL,
    active boolean DEFAULT true NOT NULL,
    code character varying(50) NOT NULL
);


--
-- Name: farms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE farms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: farms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE farms_id_seq OWNED BY farms.id;


--
-- Name: farms_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('farms_id_seq', 1, false);


--
-- Name: fields; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE fields (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    date_from date,
    date_to date,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    farm_id integer NOT NULL,
    active boolean DEFAULT true NOT NULL,
    the_geom geometry,
    code character varying(50) NOT NULL
);


--
-- Name: fields_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE fields_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: fields_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE fields_id_seq OWNED BY fields.id;


--
-- Name: fields_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('fields_id_seq', 1, false);


--
-- Name: groups_by_options; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE groups_by_options (
    id integer NOT NULL,
    user_group_id integer NOT NULL,
    menu_option_id integer NOT NULL
);


--
-- Name: groups_by_options_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE groups_by_options_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: groups_by_options_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE groups_by_options_id_seq OWNED BY groups_by_options.id;


--
-- Name: groups_by_options_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('groups_by_options_id_seq', 1, false);


--
-- Name: menu_options; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE menu_options (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    controller character varying(50) NOT NULL,
    action character varying(50) NOT NULL,
    description character varying(500),
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    parent_id integer,
    menu_icon character varying(50)
);


--
-- Name: menu_options_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE menu_options_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: menu_options_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE menu_options_id_seq OWNED BY menu_options.id;


--
-- Name: menu_options_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('menu_options_id_seq', 1, false);


--
-- Name: pixel; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE pixel (
    id integer NOT NULL,
    y integer NOT NULL,
    x integer NOT NULL,
    set_id integer NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    the_geom geometry
);


--
-- Name: pixel_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE pixel_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: pixel_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE pixel_id_seq OWNED BY pixel.id;


--
-- Name: pixel_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('pixel_id_seq', 1, false);


--
-- Name: pixel_selection_rules; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE pixel_selection_rules (
    id integer NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    name character varying(50) NOT NULL,
    tolerance integer NOT NULL
);


--
-- Name: pixel_selection_rules_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE pixel_selection_rules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: pixel_selection_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE pixel_selection_rules_id_seq OWNED BY pixel_selection_rules.id;


--
-- Name: pixel_selection_rules_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('pixel_selection_rules_id_seq', 1, false);


--
-- Name: pixel_sets; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE pixel_sets (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    active boolean DEFAULT true NOT NULL
);


--
-- Name: pixel_sets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE pixel_sets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: pixel_sets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE pixel_sets_id_seq OWNED BY pixel_sets.id;


--
-- Name: pixel_sets_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('pixel_sets_id_seq', 1, false);


--
-- Name: process_fields; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE process_fields (
    id integer NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    start_process_at timestamp without time zone,
    end_process_at timestamp without time zone,
    client_id integer NOT NULL,
    project_id integer NOT NULL,
    subproject_id integer NOT NULL,
    version_id integer NOT NULL,
    path character varying(100),
    description character varying,
    user_id integer NOT NULL
);


--
-- Name: process_fields_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE process_fields_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: process_fields_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE process_fields_id_seq OWNED BY process_fields.id;


--
-- Name: process_fields_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('process_fields_id_seq', 1, false);


--
-- Name: process_pixels; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE process_pixels (
    id integer NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    start_process_at timestamp without time zone,
    end_process_at timestamp without time zone,
    description character varying,
    path character varying(100),
    set_id integer NOT NULL,
    user_id integer NOT NULL
);


--
-- Name: process_pixels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE process_pixels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: process_pixels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE process_pixels_id_seq OWNED BY process_pixels.id;


--
-- Name: process_pixels_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('process_pixels_id_seq', 1, false);


--
-- Name: process_regions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE process_regions (
    id integer NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    start_process_at timestamp without time zone,
    end_process_at timestamp without time zone,
    path character varying(100),
    description character varying,
    set_id integer NOT NULL
);


--
-- Name: process_regions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE process_regions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: process_regions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE process_regions_id_seq OWNED BY process_regions.id;


--
-- Name: process_regions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('process_regions_id_seq', 1, false);


--
-- Name: process_results; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE process_results (
    set_id integer NOT NULL,
    id integer NOT NULL,
    pixel_selection_rules_id integer NOT NULL,
    user_id integer NOT NULL,
    version_id integer NOT NULL,
    date_id integer NOT NULL,
    name character varying(30) NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    active boolean DEFAULT true NOT NULL,
    start_process_at timestamp without time zone,
    end_process_at timestamp without time zone,
    description character varying(200)
);


--
-- Name: process_results_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE process_results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: process_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE process_results_id_seq OWNED BY process_results.id;


--
-- Name: process_results_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('process_results_id_seq', 1, false);


--
-- Name: projects; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE projects (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    client_id integer NOT NULL,
    active boolean DEFAULT true NOT NULL
);


--
-- Name: projects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE projects_id_seq OWNED BY projects.id;


--
-- Name: projects_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('projects_id_seq', 1, false);


--
-- Name: r2_sessions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE r2_sessions (
    id character varying(40) NOT NULL,
    ip_address character varying(45) NOT NULL,
    "timestamp" bigint DEFAULT 0 NOT NULL,
    data text DEFAULT ''::text NOT NULL
);


--
-- Name: regions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE regions (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    the_geom polygon,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    set_id integer NOT NULL
);


--
-- Name: regions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE regions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: regions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE regions_id_seq OWNED BY regions.id;


--
-- Name: regions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('regions_id_seq', 1, false);


--
-- Name: results; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE results (
    id integer NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    process_id integer NOT NULL,
    field_id integer NOT NULL,
    intersect_idx real NOT NULL,
    selected boolean DEFAULT true NOT NULL,
    selected_by_user boolean DEFAULT false NOT NULL,
    pixel_id integer NOT NULL,
    set_id integer NOT NULL
);


--
-- Name: results_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE results_id_seq OWNED BY results.id;


--
-- Name: results_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('results_id_seq', 1, false);


--
-- Name: sub_projects; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sub_projects (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    project_id integer NOT NULL,
    active boolean DEFAULT true NOT NULL
);


--
-- Name: sub_projects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sub_projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: sub_projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sub_projects_id_seq OWNED BY sub_projects.id;


--
-- Name: sub_projects_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('sub_projects_id_seq', 1, false);


--
-- Name: temporal_expansion_rules; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE temporal_expansion_rules (
    id integer NOT NULL,
    region_id integer NOT NULL,
    use_declared_id integer NOT NULL,
    use_concrete_id integer NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    month_to integer,
    month_from integer,
    declaration_month integer
);


--
-- Name: temporal_expansion_rules_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE temporal_expansion_rules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: temporal_expansion_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE temporal_expansion_rules_id_seq OWNED BY temporal_expansion_rules.id;


--
-- Name: temporal_expansion_rules_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('temporal_expansion_rules_id_seq', 1, false);


--
-- Name: use_concretes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE use_concretes (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL
);


--
-- Name: use_concretes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE use_concretes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: use_concretes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE use_concretes_id_seq OWNED BY use_concretes.id;


--
-- Name: use_concretes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('use_concretes_id_seq', 1, false);


--
-- Name: use_declareds; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE use_declareds (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    description character varying(200)
);


--
-- Name: use_declareds_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE use_declareds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: use_declareds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE use_declareds_id_seq OWNED BY use_declareds.id;


--
-- Name: use_declareds_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('use_declareds_id_seq', 1, false);


--
-- Name: user_groups; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE user_groups (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    active boolean DEFAULT true NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    description character varying(200)
);


--
-- Name: user_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: user_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_groups_id_seq OWNED BY user_groups.id;


--
-- Name: user_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('user_groups_id_seq', 1, false);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    password bytea DEFAULT ''::bytea,
    email character varying(320) NOT NULL,
    active boolean DEFAULT true NOT NULL,
    is_admin boolean DEFAULT false NOT NULL,
    last_login timestamp without time zone,
    last_ip inet,
    inactive_reason character varying(500),
    activation_code character varying(10),
    failed_login_count integer DEFAULT 0,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    password_sent_at timestamp without time zone
);


--
-- Name: users_by_groups; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users_by_groups (
    id integer NOT NULL,
    user_id integer NOT NULL,
    user_group_id integer NOT NULL
);


--
-- Name: users_by_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_by_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: users_by_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_by_groups_id_seq OWNED BY users_by_groups.id;


--
-- Name: users_by_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('users_by_groups_id_seq', 1, false);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('users_id_seq', 1, false);


--
-- Name: versions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE versions (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    sub_project_id integer NOT NULL,
    active boolean DEFAULT true NOT NULL
);


--
-- Name: versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE versions_id_seq OWNED BY versions.id;


--
-- Name: versions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('versions_id_seq', 1, false);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY business_objects_translations ALTER COLUMN id SET DEFAULT nextval('business_objects_translations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY clients ALTER COLUMN id SET DEFAULT nextval('clients_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY concretes_by_declareds ALTER COLUMN id SET DEFAULT nextval('concretes_by_declareds_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY dates ALTER COLUMN id SET DEFAULT nextval('dates_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY db_actions_logs ALTER COLUMN id SET DEFAULT nextval('db_actions_logs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY declarations ALTER COLUMN id SET DEFAULT nextval('declarations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY farms ALTER COLUMN id SET DEFAULT nextval('farms_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY fields ALTER COLUMN id SET DEFAULT nextval('fields_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY groups_by_options ALTER COLUMN id SET DEFAULT nextval('groups_by_options_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY menu_options ALTER COLUMN id SET DEFAULT nextval('menu_options_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY pixel ALTER COLUMN id SET DEFAULT nextval('pixel_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY pixel_selection_rules ALTER COLUMN id SET DEFAULT nextval('pixel_selection_rules_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY pixel_sets ALTER COLUMN id SET DEFAULT nextval('pixel_sets_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY process_fields ALTER COLUMN id SET DEFAULT nextval('process_fields_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY process_pixels ALTER COLUMN id SET DEFAULT nextval('process_pixels_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY process_regions ALTER COLUMN id SET DEFAULT nextval('process_regions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY process_results ALTER COLUMN id SET DEFAULT nextval('process_results_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY projects ALTER COLUMN id SET DEFAULT nextval('projects_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY regions ALTER COLUMN id SET DEFAULT nextval('regions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY results ALTER COLUMN id SET DEFAULT nextval('results_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sub_projects ALTER COLUMN id SET DEFAULT nextval('sub_projects_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY temporal_expansion_rules ALTER COLUMN id SET DEFAULT nextval('temporal_expansion_rules_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY use_concretes ALTER COLUMN id SET DEFAULT nextval('use_concretes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY use_declareds ALTER COLUMN id SET DEFAULT nextval('use_declareds_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_groups ALTER COLUMN id SET DEFAULT nextval('user_groups_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users_by_groups ALTER COLUMN id SET DEFAULT nextval('users_by_groups_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY versions ALTER COLUMN id SET DEFAULT nextval('versions_id_seq'::regclass);


--
-- Data for Name: business_objects_translations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY business_objects_translations (id, current_name, spanish_translation, english_translation, ts) FROM stdin;
\.


--
-- Data for Name: clients; Type: TABLE DATA; Schema: public; Owner: -
--

COPY clients (id, name, active, ts, created_at) FROM stdin;
\.


--
-- Data for Name: concretes_by_declareds; Type: TABLE DATA; Schema: public; Owner: -
--

COPY concretes_by_declareds (id, declared_id, concrete_id) FROM stdin;
\.


--
-- Data for Name: dates; Type: TABLE DATA; Schema: public; Owner: -
--

COPY dates (id, set_id, date, ts, created_at) FROM stdin;
\.


--
-- Data for Name: db_actions_logs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY db_actions_logs (id, ts, event, user_id, description, object_class, object_id, object) FROM stdin;
\.


--
-- Data for Name: declarations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY declarations (id, ts, created_at, date, use_declared_id, field_id, active, date_from, date_to) FROM stdin;
\.


--
-- Data for Name: farms; Type: TABLE DATA; Schema: public; Owner: -
--

COPY farms (id, name, ts, created_at, version_id, active, code) FROM stdin;
\.


--
-- Data for Name: fields; Type: TABLE DATA; Schema: public; Owner: -
--

COPY fields (id, name, date_from, date_to, ts, created_at, farm_id, active, the_geom, code) FROM stdin;
\.


--
-- Data for Name: groups_by_options; Type: TABLE DATA; Schema: public; Owner: -
--

COPY groups_by_options (id, user_group_id, menu_option_id) FROM stdin;
2	1	3
3	1	4
4	1	5
5	1	6
6	1	7
11	1	9
12	1	10
13	1	11
14	1	12
15	1	13
18	1	15
19	1	16
20	1	17
21	1	18
22	1	19
27	1	22
28	1	23
29	1	24
30	1	25
35	1	27
38	1	29
39	1	30
40	1	31
41	1	32
49	1	34
\.


--
-- Data for Name: menu_options; Type: TABLE DATA; Schema: public; Owner: -
--

COPY menu_options (id, name, controller, action, description, ts, created_at, parent_id, menu_icon) FROM stdin;
12	Descargar Datos Espaciales	controller	index	\N	2015-08-24 16:57:57.115832	2015-08-24 16:57:57.115832	\N	<i class="fa fa-download"></i>
16	Descargar Imagen Satelital	controller	index	\N	2015-08-24 16:59:48.763192	2015-08-24 16:59:48.763192	12	<i class="fa fa-camera"></i>
15	Descargar Shp	controller	index	\N	2015-08-24 16:59:21.467474	2015-08-24 16:59:21.467474	12	<i class="fa fa-file"></i>
3	Datos de Cliente	none	none	\N	2015-08-24 16:46:16.335325	2015-08-24 16:46:16.335325	\N	<i class="fa fa-user "></i>
5	Proyecto	projects	index	\N	2015-08-24 16:49:16.158121	2015-08-24 16:49:16.158121	3	<i class="fa fa-tag"></i>
4	Cliente	clients	index	\N	2015-08-24 16:48:10.095566	2015-08-24 16:48:10.095566	3	<i class="fa fa-user"></i>
7	Carga de Datos Espaciales	none	none	\N	2015-08-24 16:52:31.885139	2015-08-24 16:52:31.885139	\N	<i class="fa fa-globe"></i>
13	Descargar Grilla	none	none	\N	2015-08-24 16:58:33.965238	2015-08-24 16:58:33.965238	12	<i class="fa fa-th"></i>
17	Administracion	none	none	\N	2015-08-24 17:02:24.555211	2015-08-24 17:02:24.555211	\N	<i class="fa fa-wrench fa-fw"></i>
11	Cargar Imagen Satelital	controller	index	\N	2015-08-24 16:57:26.155459	2015-08-24 16:57:26.155459	7	<i class="fa fa-camera"></i>
32	Establecimiento	farms	index	\N	2015-08-24 17:19:20.67954	2015-08-24 17:19:20.67954	3	<i class="fa fa-picture-o"></i>
31	Version	versions	index	\N	2015-08-24 17:18:29.174088	2015-08-24 17:18:29.174088	3	<i class="fa fa-cubes"></i>
6	SubProyecto	sub_projects	index	\N	2015-08-24 16:49:56.749999	2015-08-24 16:49:56.749999	3	<i class="fa fa-tags"></i>
18	Usuarios	users	index	\N	2015-08-24 17:03:20.906361	2015-08-24 17:03:20.906361	17	<i class="fa fa-user"></i>
22	Sets	pixel_sets	index	\N	2015-08-24 17:03:51.899899	2015-08-24 17:03:51.899899	17	<i class="fa fa-circle"></i>
23	Fechas	dates	index	\N	2015-08-24 17:04:05.17918	2015-08-24 17:04:05.17918	17	<i class="fa fa-calendar"></i>
19	Grupos	user_groups	index	\N	2015-08-24 17:03:37.771776	2015-08-24 17:03:37.771776	17	<i class="fa fa-group"></i>
30	Pixeles	pixeles	index	\N	2015-08-24 17:06:50.615873	2015-08-24 17:06:50.615873	17	<i class="fa fa-circle"></i>
25	Reglas de Seleccion de Pixeles	pixel_selection_rules	index	\N	2015-08-24 17:04:55.465713	2015-08-24 17:04:55.465713	17	<i class="fa fa-circle"></i>
33	Log de Procesos	controller	index	\N	2015-08-25 13:44:09.723953	2015-08-25 13:44:09.723953	17	<i class="fa fa-circle"></i>
34	Log de Acciones de Usuarios y Descarga	actions_log	index	\N	2015-08-25 13:47:42.330004	2015-08-25 13:47:42.330004	17	<i class="fa fa-circle"></i>
24	Reglas de Expansion Temporal	temporal_expansion_rules	index	\N	2015-08-24 17:04:33.306013	2015-08-24 17:04:33.306013	17	<i class="fa fa-circle"></i>
27	Usos Declarados	use_declareds	index	\N	2015-08-24 17:05:15.19334	2015-08-24 17:05:15.19334	17	<i class="fa fa-circle"></i>
29	Regiones	process_regions	index	\N	2015-08-24 17:06:35.705207	2015-08-24 17:06:35.705207	17	<i class="fa fa-circle"></i>
9	Carga Grilla	process_pixels	index	\N	2015-08-24 16:55:16.700718	2015-08-24 16:55:16.700718	7	<i class="fa fa-th"></i>
10	Carga Shp	process_fields	index	\N	2015-08-24 16:55:48.236215	2015-08-24 16:55:48.236215	7	<i class="fa fa-file"></i>
\.


--
-- Data for Name: pixel; Type: TABLE DATA; Schema: public; Owner: -
--

COPY pixel (id, y, x, set_id, ts, created_at, the_geom) FROM stdin;
\.


--
-- Data for Name: pixel_selection_rules; Type: TABLE DATA; Schema: public; Owner: -
--

COPY pixel_selection_rules (id, ts, created_at, name, tolerance) FROM stdin;
\.


--
-- Data for Name: pixel_sets; Type: TABLE DATA; Schema: public; Owner: -
--

COPY pixel_sets (id, name, ts, created_at, active) FROM stdin;
\.


--
-- Data for Name: process_fields; Type: TABLE DATA; Schema: public; Owner: -
--

COPY process_fields (id, ts, created_at, start_process_at, end_process_at, client_id, project_id, subproject_id, version_id, path, description, user_id) FROM stdin;
\.


--
-- Data for Name: process_pixels; Type: TABLE DATA; Schema: public; Owner: -
--

COPY process_pixels (id, ts, created_at, start_process_at, end_process_at, description, path, set_id, user_id) FROM stdin;
\.


--
-- Data for Name: process_regions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY process_regions (id, ts, created_at, start_process_at, end_process_at, path, description, set_id) FROM stdin;
\.


--
-- Data for Name: process_results; Type: TABLE DATA; Schema: public; Owner: -
--

COPY process_results (set_id, id, pixel_selection_rules_id, user_id, version_id, date_id, name, ts, created_at, active, start_process_at, end_process_at, description) FROM stdin;
\.


--
-- Data for Name: projects; Type: TABLE DATA; Schema: public; Owner: -
--

COPY projects (id, name, ts, created_at, client_id, active) FROM stdin;
\.


--
-- Data for Name: r2_sessions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY r2_sessions (id, ip_address, "timestamp", data) FROM stdin;
\.


--
-- Data for Name: regions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY regions (id, name, the_geom, ts, created_at, set_id) FROM stdin;
\.


--
-- Data for Name: results; Type: TABLE DATA; Schema: public; Owner: -
--

COPY results (id, ts, created_at, process_id, field_id, intersect_idx, selected, selected_by_user, pixel_id, set_id) FROM stdin;
\.


--
-- Data for Name: sub_projects; Type: TABLE DATA; Schema: public; Owner: -
--

COPY sub_projects (id, name, ts, created_at, project_id, active) FROM stdin;
\.


--
-- Data for Name: temporal_expansion_rules; Type: TABLE DATA; Schema: public; Owner: -
--

COPY temporal_expansion_rules (id, region_id, use_declared_id, use_concrete_id, ts, created_at, month_to, month_from, declaration_month) FROM stdin;
\.


--
-- Data for Name: use_concretes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY use_concretes (id, name, ts, created_at) FROM stdin;
\.


--
-- Data for Name: use_declareds; Type: TABLE DATA; Schema: public; Owner: -
--

COPY use_declareds (id, name, ts, created_at, description) FROM stdin;
\.


--
-- Data for Name: user_groups; Type: TABLE DATA; Schema: public; Owner: -
--

COPY user_groups (id, name, active, ts, created_at, description) FROM stdin;
1	admin	t	2015-08-24 14:22:40.64215	2015-08-24 14:22:40.64215	\N
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY users (id, name, password, email, active, is_admin, last_login, last_ip, inactive_reason, activation_code, failed_login_count, ts, created_at, password_sent_at) FROM stdin;
-1	admin	793345890aad8365eaa502e69b9698bc69921f68	r2Soft@gmail.com	t	t	\N	\N	\N	\N	0	2015-08-25 00:00:00	2015-08-25 00:00:00	\N
\.


--
-- Data for Name: users_by_groups; Type: TABLE DATA; Schema: public; Owner: -
--

COPY users_by_groups (id, user_id, user_group_id) FROM stdin;
1	-1	1
\.


--
-- Data for Name: versions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY versions (id, name, ts, created_at, sub_project_id, active) FROM stdin;
\.


--
-- Name: business_objects_translations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY business_objects_translations
    ADD CONSTRAINT business_objects_translations_pkey PRIMARY KEY (id);


--
-- Name: clients_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY clients
    ADD CONSTRAINT clients_pk PRIMARY KEY (id);


--
-- Name: concretes_by_declareds_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY concretes_by_declareds
    ADD CONSTRAINT concretes_by_declareds_pk PRIMARY KEY (id);


--
-- Name: dates_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY dates
    ADD CONSTRAINT dates_pk PRIMARY KEY (id);


--
-- Name: db_actions_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY db_actions_logs
    ADD CONSTRAINT db_actions_logs_pkey PRIMARY KEY (id);


--
-- Name: declarations_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY declarations
    ADD CONSTRAINT declarations_pk PRIMARY KEY (id);


--
-- Name: farm_field_code; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY fields
    ADD CONSTRAINT farm_field_code UNIQUE (farm_id, code);


--
-- Name: farms_code; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY farms
    ADD CONSTRAINT farms_code UNIQUE (code);


--
-- Name: farms_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY farms
    ADD CONSTRAINT farms_pk PRIMARY KEY (id);


--
-- Name: fields_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY fields
    ADD CONSTRAINT fields_pk PRIMARY KEY (id);


--
-- Name: groups_by_options_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY groups_by_options
    ADD CONSTRAINT groups_by_options_pk PRIMARY KEY (id);


--
-- Name: menu_option_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY menu_options
    ADD CONSTRAINT menu_option_pk PRIMARY KEY (id);


--
-- Name: pixel_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pixel
    ADD CONSTRAINT pixel_pk PRIMARY KEY (id);


--
-- Name: pixel_selection_rules_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pixel_selection_rules
    ADD CONSTRAINT pixel_selection_rules_pk PRIMARY KEY (id);


--
-- Name: pixel_sets_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pixel_sets
    ADD CONSTRAINT pixel_sets_pk PRIMARY KEY (id);


--
-- Name: process_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY process_fields
    ADD CONSTRAINT process_fields_pkey PRIMARY KEY (id);


--
-- Name: process_pixels_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY process_pixels
    ADD CONSTRAINT process_pixels_pkey PRIMARY KEY (id);


--
-- Name: process_regions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY process_regions
    ADD CONSTRAINT process_regions_pkey PRIMARY KEY (id);


--
-- Name: process_results_id_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY process_results
    ADD CONSTRAINT process_results_id_pk PRIMARY KEY (id);


--
-- Name: projects_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT projects_pk PRIMARY KEY (id);


--
-- Name: r2_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY r2_sessions
    ADD CONSTRAINT r2_sessions_pkey PRIMARY KEY (id);


--
-- Name: regions_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY regions
    ADD CONSTRAINT regions_pk PRIMARY KEY (id);


--
-- Name: results_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY results
    ADD CONSTRAINT results_pkey PRIMARY KEY (id);


--
-- Name: sub_projects_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sub_projects
    ADD CONSTRAINT sub_projects_pk PRIMARY KEY (id);


--
-- Name: temporal_expansion_rules_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY temporal_expansion_rules
    ADD CONSTRAINT temporal_expansion_rules_pk PRIMARY KEY (id);


--
-- Name: unique_constraint_date_field_id; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY declarations
    ADD CONSTRAINT unique_constraint_date_field_id UNIQUE (date, field_id);


--
-- Name: use_concretes_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY use_concretes
    ADD CONSTRAINT use_concretes_pk PRIMARY KEY (id);


--
-- Name: use_declareds_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY use_declareds
    ADD CONSTRAINT use_declareds_pk PRIMARY KEY (id);


--
-- Name: user_by_groups_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users_by_groups
    ADD CONSTRAINT user_by_groups_pk PRIMARY KEY (id);


--
-- Name: user_groups_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY user_groups
    ADD CONSTRAINT user_groups_pk PRIMARY KEY (id);


--
-- Name: users_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pk PRIMARY KEY (id);


--
-- Name: versions_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY versions
    ADD CONSTRAINT versions_pk PRIMARY KEY (id);


--
-- Name: fields_the_geom_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX fields_the_geom_idx ON fields USING gist (the_geom);


--
-- Name: fki_menu_options_to_menu_options_fk; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX fki_menu_options_to_menu_options_fk ON menu_options USING btree (parent_id);


--
-- Name: pixel_the_geom_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX pixel_the_geom_idx ON pixel USING gist (the_geom);


--
-- Name: r2_sessions_timestamp; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX r2_sessions_timestamp ON r2_sessions USING btree ("timestamp");


--
-- Name: Regions_to_pixel_sets; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY regions
    ADD CONSTRAINT "Regions_to_pixel_sets" FOREIGN KEY (set_id) REFERENCES pixel_sets(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: concretes_by_declareds_to_use_concretes_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY concretes_by_declareds
    ADD CONSTRAINT concretes_by_declareds_to_use_concretes_id_fkey FOREIGN KEY (concrete_id) REFERENCES use_concretes(id) ON DELETE CASCADE;


--
-- Name: concretes_by_declareds_to_use_declareds_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY concretes_by_declareds
    ADD CONSTRAINT concretes_by_declareds_to_use_declareds_id_fkey FOREIGN KEY (declared_id) REFERENCES use_declareds(id) ON DELETE CASCADE;


--
-- Name: dates_to_set_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY dates
    ADD CONSTRAINT dates_to_set_id_fkey FOREIGN KEY (set_id) REFERENCES pixel_sets(id) ON DELETE CASCADE;


--
-- Name: declarations_to_field_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY declarations
    ADD CONSTRAINT declarations_to_field_id_fkey FOREIGN KEY (field_id) REFERENCES fields(id) ON DELETE CASCADE;


--
-- Name: declarations_to_use_declared_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY declarations
    ADD CONSTRAINT declarations_to_use_declared_id_fkey FOREIGN KEY (use_declared_id) REFERENCES use_declareds(id) ON DELETE CASCADE;


--
-- Name: farms_to_version_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY farms
    ADD CONSTRAINT farms_to_version_id_fkey FOREIGN KEY (version_id) REFERENCES versions(id) ON DELETE CASCADE;


--
-- Name: fields_to_farm_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY fields
    ADD CONSTRAINT fields_to_farm_id_fkey FOREIGN KEY (farm_id) REFERENCES farms(id) ON DELETE CASCADE;


--
-- Name: fk_db_actions_logs_to_users; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY db_actions_logs
    ADD CONSTRAINT fk_db_actions_logs_to_users FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: groups_by_options_to_menu_option_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY groups_by_options
    ADD CONSTRAINT groups_by_options_to_menu_option_fkey FOREIGN KEY (menu_option_id) REFERENCES menu_options(id) ON DELETE CASCADE;


--
-- Name: groups_by_options_to_user_groups_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY groups_by_options
    ADD CONSTRAINT groups_by_options_to_user_groups_id_fkey FOREIGN KEY (user_group_id) REFERENCES user_groups(id) ON DELETE CASCADE;


--
-- Name: menu_options_to_menu_options_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY menu_options
    ADD CONSTRAINT menu_options_to_menu_options_fk FOREIGN KEY (parent_id) REFERENCES menu_options(id) ON DELETE CASCADE;


--
-- Name: pixel_to_set_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY pixel
    ADD CONSTRAINT pixel_to_set_id_fkey FOREIGN KEY (set_id) REFERENCES pixel_sets(id) ON DELETE CASCADE;


--
-- Name: process_fields_to_clients_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY process_fields
    ADD CONSTRAINT process_fields_to_clients_fk FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;


--
-- Name: process_fields_to_projects_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY process_fields
    ADD CONSTRAINT process_fields_to_projects_fk FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE DEFERRABLE;


--
-- Name: process_fields_to_subprojects_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY process_fields
    ADD CONSTRAINT process_fields_to_subprojects_fk FOREIGN KEY (subproject_id) REFERENCES sub_projects(id) ON DELETE CASCADE;


--
-- Name: process_fields_to_users_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY process_fields
    ADD CONSTRAINT process_fields_to_users_fk FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: process_fields_to_versions_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY process_fields
    ADD CONSTRAINT process_fields_to_versions_fk FOREIGN KEY (version_id) REFERENCES versions(id) ON DELETE CASCADE;


--
-- Name: process_pixels_to_pixel_sets_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY process_pixels
    ADD CONSTRAINT process_pixels_to_pixel_sets_fk FOREIGN KEY (set_id) REFERENCES pixel_sets(id) ON DELETE CASCADE;


--
-- Name: process_pixels_to_users_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY process_pixels
    ADD CONSTRAINT process_pixels_to_users_fk FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: process_regions_to_pixel_sets_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY process_regions
    ADD CONSTRAINT process_regions_to_pixel_sets_fk FOREIGN KEY (set_id) REFERENCES pixel_sets(id) ON DELETE CASCADE;


--
-- Name: process_results_to_dates_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY process_results
    ADD CONSTRAINT process_results_to_dates_id_fkey FOREIGN KEY (date_id) REFERENCES dates(id);


--
-- Name: process_results_to_pixel_selection_rules_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY process_results
    ADD CONSTRAINT process_results_to_pixel_selection_rules_id_fkey FOREIGN KEY (pixel_selection_rules_id) REFERENCES pixel_selection_rules(id);


--
-- Name: process_results_to_pixel_sets_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY process_results
    ADD CONSTRAINT process_results_to_pixel_sets_id FOREIGN KEY (set_id) REFERENCES pixel_sets(id);


--
-- Name: process_results_to_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY process_results
    ADD CONSTRAINT process_results_to_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: process_results_to_versions_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY process_results
    ADD CONSTRAINT process_results_to_versions_id_fkey FOREIGN KEY (version_id) REFERENCES versions(id);


--
-- Name: projects_to_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT projects_to_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;


--
-- Name: results_to_fields_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY results
    ADD CONSTRAINT results_to_fields_fk FOREIGN KEY (field_id) REFERENCES fields(id) ON DELETE CASCADE DEFERRABLE;


--
-- Name: results_to_pixel_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY results
    ADD CONSTRAINT results_to_pixel_fk FOREIGN KEY (pixel_id) REFERENCES pixel(id) ON DELETE CASCADE;


--
-- Name: results_to_sets_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY results
    ADD CONSTRAINT results_to_sets_fk FOREIGN KEY (set_id) REFERENCES pixel_sets(id) ON DELETE CASCADE;


--
-- Name: sub_projecs_to_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sub_projects
    ADD CONSTRAINT sub_projecs_to_project_id_fkey FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE;


--
-- Name: temporal_expansion_rules_to_region_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY temporal_expansion_rules
    ADD CONSTRAINT temporal_expansion_rules_to_region_id_fkey FOREIGN KEY (region_id) REFERENCES regions(id) ON DELETE CASCADE;


--
-- Name: temporal_expansion_rules_to_use_concrete_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY temporal_expansion_rules
    ADD CONSTRAINT temporal_expansion_rules_to_use_concrete_id_fkey FOREIGN KEY (use_concrete_id) REFERENCES use_concretes(id) ON DELETE CASCADE;


--
-- Name: temporal_expansion_rules_to_use_declared_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY temporal_expansion_rules
    ADD CONSTRAINT temporal_expansion_rules_to_use_declared_id_fkey FOREIGN KEY (use_declared_id) REFERENCES use_declareds(id) ON DELETE CASCADE;


--
-- Name: users_by_groups_to_user_groups_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users_by_groups
    ADD CONSTRAINT users_by_groups_to_user_groups_id_fkey FOREIGN KEY (user_group_id) REFERENCES user_groups(id) ON DELETE CASCADE;


--
-- Name: users_by_groups_to_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users_by_groups
    ADD CONSTRAINT users_by_groups_to_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: versions_to_sub_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY versions
    ADD CONSTRAINT versions_to_sub_project_id_fkey FOREIGN KEY (sub_project_id) REFERENCES sub_projects(id) ON DELETE CASCADE;


--
-- Name: public; Type: ACL; Schema: -; Owner: -
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

COMMIT;

