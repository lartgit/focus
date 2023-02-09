
BEGIN;

INSERT INTO public.menu_options ("name",controller,"action",description,parent_id,menu_icon,"order") VALUES
('Consultar Resultados','process_query_functions','index','',76,'<i class="fa fa-magnifer"></i>',780);

INSERT INTO public.groups_by_options (user_group_id, menu_option_id) VALUES(1, 60);

CREATE TABLE public.process_query_functions (
	id serial NOT NULL,
	ts timestamp NOT NULL DEFAULT now(),
	created_at timestamp NOT NULL DEFAULT now(),
	status varchar(20) NOT NULL,
	user_id int4 NOT NULL,
	start_process_at timestamp NULL,
	end_process_at timestamp NULL,
	description varchar NULL,
	procces_run bool NULL DEFAULT false,
	pixel_id int NULL,
	region_id text NULL,
    client_id text NULL,
    project_id text NULL,
    version_id text NULL,
	farm_id text NULL,
	group_name text NULL,
	field_id text NULL,
	use_concrete_id text NULL,
	date timestamp NULL,
	date_from timestamp NULL,
	date_to timestamp NULL,
	group_field bool NOT NULL DEFAULT false,
	group_month bool NOT NULL DEFAULT false,
	aggregate_function varchar(50) NULL,
	CONSTRAINT process_query_functions_pk PRIMARY KEY (id),
	CONSTRAINT process_query_functions_pixel_id_to_pixels FOREIGN KEY (pixel_id) REFERENCES pixel(id) ON DELETE CASCADE
);

CREATE TABLE log.process_query_function_logs (
	id serial NOT NULL,
	ts timestamp NOT NULL DEFAULT now(),
	created_at timestamp NOT NULL DEFAULT now(),
	process_query_function_id int NOT NULL,
	log_type varchar(25),
	description TEXT,
	file TEXT,
	line int,
	callstack TEXT,
	CONSTRAINT process_query_function_logs_pk PRIMARY KEY (id),
	CONSTRAINT process_query_function_logs_process_query_function_id_to_process_query_functions FOREIGN KEY (process_query_function_id) REFERENCES process_query_functions(id) ON DELETE CASCADE
);

COMMIT;
