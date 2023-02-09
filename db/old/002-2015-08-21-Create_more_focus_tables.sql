BEGIN; --NArias


CREATE TABLE public.pixel
(
  id serial NOT NULL,
  center_latitude FLOAT NOT NULL,
  center_longitude FLOAT NOT NULL,
  set_id INTEGER NOT NULL,
  the_geom polygon,
  ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  created_at timestamp(6) without time zone NOT NULL DEFAULT now(),
  CONSTRAINT pixel_pk PRIMARY KEY (id),
  CONSTRAINT pixel_to_set_id_fkey FOREIGN KEY (set_id)
      REFERENCES pixel_sets (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE
);


CREATE TABLE public.menu_options
(
  id serial NOT NULL,
  name character varying(50) NOT NULL,
  controller character varying(50) NOT NULL,
  action character varying(50) NOT NULL,
  description character varying(500),
  ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  created_at timestamp(6) without time zone NOT NULL DEFAULT now(),
  CONSTRAINT menu_option_pk PRIMARY KEY (id)
);


CREATE TABLE public.groups_by_options
(
  id serial NOT NULL,
  user_group_id INTEGER NOT NULL,
  menu_option_id INTEGER NOT NULL,
  CONSTRAINT groups_by_options_pk PRIMARY KEY (id),
  CONSTRAINT groups_by_options_to_user_groups_id_fkey FOREIGN KEY (user_group_id)
      REFERENCES user_groups(id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT groups_by_options_to_menu_option_fkey FOREIGN KEY (menu_option_id)
      REFERENCES menu_options(id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE
);





COMMIT;
