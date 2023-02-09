
BEGIN;

DROP FUNCTION IF EXISTS focus_cast_to_double(text);

-- CREATE OR REPLACE FUNCTION focus_cast_to_double(v_input text, v_retzero boolean = true)
  -- RETURNS character varying AS
CREATE OR REPLACE FUNCTION focus_cast_to_double(v_input text)
  RETURNS double precision AS
$BODY$
DECLARE v_int_value INTEGER DEFAULT NULL;
BEGIN
    BEGIN
        v_int_value := v_input::double precision;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Invalid integer value: "%".  Returning NULL.', v_input;
        -- IF v_retzero THEN
            RETURN 0;
        -- ELSE
            -- RETURN v_input;
        -- END IF;
    END;
RETURN v_int_value;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

COMMIT;
