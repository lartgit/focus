BEGIN;

CREATE TABLE r2_log_activity
(
  id serial NOT NULL,
  ts timestamp without time zone DEFAULT now(),
  created_at timestamp without time zone DEFAULT now(),
  ip inet,
  user_id integer,
  post_data character varying,
  get_data character varying,
  controller character varying,
  method character varying,
  uri character varying,
  http_response_code integer,
  CONSTRAINT log_activity_pk PRIMARY KEY (id)
);

COMMIT;