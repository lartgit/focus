
BEGIN;


DROP FUNCTION IF EXISTS focus_upsert_result2(character varying, integer, integer, character varying);

CREATE OR REPLACE FUNCTION focus_upsert_result2(
    param_key character varying,
    param_process_result_id integer,
    param_process_focus_2_id integer,
    param_value character varying)
  RETURNS character varying AS
$BODY$
DECLARE
varId integer;
-- Esta funcion tiene como objetivo realizar el update o el insert de un resultado en focus 2
-- Si bien no es posible actualmente reiniar un proceso de resultado focus 2 lo podriamos utilzar para debug o en un futuro podriamos permitirlo.
BEGIN

    SELECT id into varId FROM results_f2 WHERE key = param_key AND process_result_id = param_process_result_id AND process_focus_id = param_process_focus_2_id ; 

    IF varId IS NULL THEN 
        INSERT INTO results_f2 (key, value, process_result_id, process_focus_id) VALUES (param_key, param_value, param_process_result_id, param_process_focus_2_id );
        return 'Inserted';
    ELSE
        UPDATE results_f2 SET value = param_value WHERE id =  varId;
        return 'Updated';
    END IF;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE TABLE results_f2
(
  id serial NOT NULL,
  key character varying(250) NOT NULL,
  value character varying(250),
  process_result_id integer,
  process_focus_id integer,
  ts timestamp without time zone NOT NULL DEFAULT now(),
  CONSTRAINT result_focus2_pk PRIMARY KEY (id)
);

COMMIT;
