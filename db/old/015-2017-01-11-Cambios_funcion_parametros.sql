
BEGIN;

DROP FUNCTION IF EXISTS public.focus_get_parameter(text, date, integer, integer);

CREATE OR REPLACE FUNCTION public.focus_get_parameter(
    arg_parameter_name text,
    pixel_date date,
    param_use_id integer,
    param_region_id integer)
  RETURNS character varying AS
$BODY$
DECLARE
paramRet character varying;

BEGIN
    SELECT value into paramRet
    FROM parameters
    JOIN parameter_types ON parameter_types.id = parameter_type_id
    WHERE region_id = param_region_id 
      AND parameter_types.name = arg_parameter_name
      AND (month = 0 or month = extract('month' from pixel_date))
      AND (use_id is null or use_id = param_use_id)
    ORDER BY priority DESC;

    IF paramRet IS NULL THEN 
        RETURN NULL;
    ELSE
        RETURN paramRet;
    END IF;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- Tests:
/*
SELECT '1: x1', focus_get_parameter('ndvi', '2017-01-11'::date, 70, 108)
UNION
SELECT '2: x2', focus_get_parameter('ndvi', '2017-02-11'::date, 70, 108)
UNION
SELECT '3: x4', focus_get_parameter('ndvi', '2017-01-11'::date, null, 108)
UNION
SELECT '4: x4', focus_get_parameter('ndvi', '2017-01-11'::date, 73, 108)
*/

COMMIT;
