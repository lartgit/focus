
BEGIN;

ALTER SEQUENCE menu_options_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 35
  CACHE 1;
ALTER TABLE menu_options_id_seq
  OWNER TO msoft;

ALTER SEQUENCE menu_options_id_seq restart;

ALTER SEQUENCE groups_by_options_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 50
  CACHE 1;
ALTER TABLE groups_by_options_id_seq
  OWNER TO msoft;

ALTER SEQUENCE groups_by_options_id_seq restart;

--Controller de Usos concretos
INSERT INTO public.menu_options ("name","controller","action","parent_id","menu_icon")
 VALUES ('Usos Concretos','use_concretes','index',17,'<i class="fa fa-circle"></i>');
 
INSERT INTO public.groups_by_options ("user_group_id","menu_option_id")
 VALUES (1,35);

COMMIT;
