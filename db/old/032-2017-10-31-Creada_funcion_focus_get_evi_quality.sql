-- Function: public.focus_get_evi_quality(integer, integer, integer, timestamp without time zone)

-- DROP FUNCTION public.focus_get_evi_quality(integer, integer, integer, timestamp without time zone);

CREATE OR REPLACE FUNCTION public.focus_get_evi_quality(
    arg_map_id integer,
    arg_use_id integer,
    arg_pixel_id integer,
    arg_date timestamp without time zone)
  RETURNS double precision AS
$BODY$
DECLARE
paramRet double precision;

var_evi_layer_id INTEGER;

var_date_value timestamp;
var_evi_value double precision;
var_accepted BOOLEAN;

var_date_value_prev timestamp;
var_evi_value_prev double precision;
var_accepted_prev BOOLEAN;

var_date_value_next timestamp;
var_evi_value_next double precision;
var_accepted_next BOOLEAN;

var_date_value_prev_2 timestamp;
var_evi_value_prev_2 double precision;
var_accepted_prev_2 BOOLEAN;

var_date_value_next_2 timestamp;
var_evi_value_next_2 double precision;
var_accepted_next_2 BOOLEAN;

BEGIN
    SELECT id INTO var_evi_layer_id FROM layer_types WHERE name = '250m 16 days EVI';

    SELECT image_date, value, accepted
      INTO var_date_value, var_evi_value, var_accepted
    FROM focus_get_evi_quality_raw(arg_map_id, arg_use_id, arg_pixel_id, arg_date) 
      AS (image_date timestamp, value double precision, accepted boolean);

    RAISE NOTICE 'var_date_value %', var_date_value;
    RAISE NOTICE 'var_evi_value %', var_evi_value;
    RAISE NOTICE 'var_accepted %', var_accepted;

    -- Si la calidad me dice que el evi esta bien, devuelvo el valor y listo.
    IF var_accepted THEN
       RETURN var_evi_value;
    END IF;

    -- Caso contrario, busco el dato anterior...
    SELECT
        rl.image_date INTO var_date_value_prev
        FROM pixel_values
        JOIN raster_layers rl ON raster_layer_id = rl.id and rl.layer_type_id = var_evi_layer_id
        WHERE image_date < var_date_value AND pixel_id = arg_pixel_id
        ORDER BY image_date DESC LIMIT 1;

    SELECT image_date, value, accepted
      INTO var_date_value_prev, var_evi_value_prev, var_accepted_prev
    FROM focus_get_evi_quality_raw(arg_map_id, arg_use_id, arg_pixel_id, var_date_value_prev) 
      AS (image_date timestamp, value double precision, accepted boolean);

    IF var_date_value_prev IS NULL THEN
        RETURN 'NaN';
    END IF;

    RAISE NOTICE 'var_date_value_prev %', var_date_value_prev;
    RAISE NOTICE 'var_evi_value_prev %', var_evi_value_prev;
    RAISE NOTICE 'var_accepted_prev %', var_accepted_prev;

    -- ...y el siguiente
    SELECT
        rl.image_date INTO var_date_value_next
        FROM pixel_values
        JOIN raster_layers rl ON raster_layer_id = rl.id and rl.layer_type_id = var_evi_layer_id
        WHERE image_date > var_date_value AND pixel_id = arg_pixel_id
        ORDER BY image_date ASC LIMIT 1;

    SELECT image_date, value, accepted
      INTO var_date_value_next, var_evi_value_next, var_accepted_next
    FROM focus_get_evi_quality_raw(arg_map_id, arg_use_id, arg_pixel_id, var_date_value_next) 
      AS (image_date timestamp, value double precision, accepted boolean);

    IF var_date_value_next IS NULL THEN
        RETURN 'NaN';
    END IF;

    RAISE NOTICE 'var_date_value_next %', var_date_value_next;
    RAISE NOTICE 'var_evi_value_next %', var_evi_value_next;
    RAISE NOTICE 'var_accepted_next %', var_accepted_next;

    -- Si el anterior y siguiente fueron aceptados, los promedio, los devuelvo, y listo.
    IF var_accepted_prev AND var_accepted_next THEN
        RETURN (var_evi_value_prev + var_evi_value_next) / 2;
    END IF;

    -- Si los 2 fueron rechazados, no puedo hacer nada.
    IF NOT var_accepted_prev AND NOT var_accepted_next THEN
        RETURN 'NAN';
    END IF;

    -- Si solo fallo el prev, me fijo el anterior
    IF NOT var_accepted_prev THEN
        SELECT
            rl.image_date INTO var_date_value_prev_2
            FROM pixel_values
            JOIN raster_layers rl ON raster_layer_id = rl.id and rl.layer_type_id = var_evi_layer_id
            WHERE image_date < var_date_value_prev AND pixel_id = arg_pixel_id
            ORDER BY image_date DESC LIMIT 1;

        SELECT image_date, value, accepted
          INTO var_date_value_prev_2, var_evi_value_prev_2, var_accepted_prev_2
        FROM focus_get_evi_quality_raw(arg_map_id, arg_use_id, arg_pixel_id, var_date_value_prev_2) 
          AS (image_date timestamp, value double precision, accepted boolean);

        IF var_date_value_prev_2 IS NULL THEN
            RETURN 'NaN';
        END IF;

        RAISE NOTICE 'var_date_value_prev_2 %', var_date_value_prev_2;
        RAISE NOTICE 'var_evi_value_prev_2 %', var_evi_value_prev_2;
        RAISE NOTICE 'var_accepted_prev_2 %', var_accepted_prev_2;

        -- Si falla aca, no puedo hacer nada.
        IF NOT var_accepted_prev_2 THEN
            RETURN 'NaN';
        END IF;

        -- Pondero el dato
        RETURN var_evi_value_next * 0.66 + var_evi_value_prev_2 * 0.33;
    ELSE
        SELECT
            rl.image_date INTO var_date_value_next_2
            FROM pixel_values
            JOIN raster_layers rl ON raster_layer_id = rl.id and rl.layer_type_id = var_evi_layer_id
            WHERE image_date > var_date_value_next AND pixel_id = arg_pixel_id
            ORDER BY image_date ASC LIMIT 1;

        SELECT image_date, value, accepted
          INTO var_date_value_next_2, var_evi_value_next_2, var_accepted_next_2
        FROM focus_get_evi_quality_raw(arg_map_id, arg_use_id, arg_pixel_id, var_date_value_next_2) 
          AS (image_date timestamp, value double precision, accepted boolean);

        IF var_date_value_next_2 IS NULL THEN
            RETURN 'NaN';
        END IF;

        RAISE NOTICE 'var_date_value_next_2 %', var_date_value_next_2;
        RAISE NOTICE 'var_evi_value_next_2 %', var_evi_value_next_2;
        RAISE NOTICE 'var_accepted_next_2 %', var_accepted_next_2;

        -- Si falla aca, no puedo hacer nada.
        IF NOT var_accepted_next_2 THEN
            RETURN 'NAN';
        END IF;

        -- Pondero el dato
        RETURN var_evi_value_prev * 0.66 + var_evi_value_next_2 * 0.33;
    END IF;

    RETURN NULL;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

