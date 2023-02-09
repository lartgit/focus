CREATE OR REPLACE FUNCTION focus_get_ndvi_quality(
    arg_map_id integer,
    arg_use_id integer,
    arg_pixel_id integer,
    arg_date timestamp)
  RETURNS double precision AS
$BODY$
DECLARE
paramRet double precision;

var_ndvi_layer_id INTEGER;

var_date_value timestamp;
var_ndvi_value double precision;
var_accepted BOOLEAN;

var_date_value_prev timestamp;
var_ndvi_value_prev double precision;
var_accepted_prev BOOLEAN;

var_date_value_next timestamp;
var_ndvi_value_next double precision;
var_accepted_next BOOLEAN;

var_date_value_prev_2 timestamp;
var_ndvi_value_prev_2 double precision;
var_accepted_prev_2 BOOLEAN;

var_date_value_next_2 timestamp;
var_ndvi_value_next_2 double precision;
var_accepted_next_2 BOOLEAN;

BEGIN
    SELECT id INTO var_ndvi_layer_id FROM layer_types WHERE name = '250m 16 days NDVI';

    SELECT image_date, value, accepted
      INTO var_date_value, var_ndvi_value, var_accepted
    FROM focus_get_ndvi_quality_raw(arg_map_id, arg_use_id, arg_pixel_id, arg_date) 
      AS (image_date timestamp, value double precision, accepted boolean);

    RAISE NOTICE 'var_date_value %', var_date_value;
    RAISE NOTICE 'var_ndvi_value %', var_ndvi_value;
    RAISE NOTICE 'var_accepted %', var_accepted;

    -- Si la calidad me dice que el NDVI esta bien, devuelvo el valor y listo.
    IF var_accepted THEN
       RETURN var_ndvi_value;
    END IF;

    -- Caso contrario, busco el dato anterior...
    SELECT
        rl.image_date INTO var_date_value_prev
        FROM pixel_values
        JOIN raster_layers rl ON raster_layer_id = rl.id and rl.layer_type_id = var_ndvi_layer_id
        WHERE image_date < var_date_value AND pixel_id = arg_pixel_id
        ORDER BY image_date DESC LIMIT 1;

    SELECT image_date, value, accepted
      INTO var_date_value_prev, var_ndvi_value_prev, var_accepted_prev
    FROM focus_get_ndvi_quality_raw(arg_map_id, arg_use_id, arg_pixel_id, var_date_value_prev) 
      AS (image_date timestamp, value double precision, accepted boolean);

    IF var_date_value_prev IS NULL THEN
        RETURN 'NaN';
    END IF;

    RAISE NOTICE 'var_date_value_prev %', var_date_value_prev;
    RAISE NOTICE 'var_ndvi_value_prev %', var_ndvi_value_prev;
    RAISE NOTICE 'var_accepted_prev %', var_accepted_prev;

    -- ...y el siguiente
    SELECT
        rl.image_date INTO var_date_value_next
        FROM pixel_values
        JOIN raster_layers rl ON raster_layer_id = rl.id and rl.layer_type_id = var_ndvi_layer_id
        WHERE image_date > var_date_value AND pixel_id = arg_pixel_id
        ORDER BY image_date ASC LIMIT 1;

    SELECT image_date, value, accepted
      INTO var_date_value_next, var_ndvi_value_next, var_accepted_next
    FROM focus_get_ndvi_quality_raw(arg_map_id, arg_use_id, arg_pixel_id, var_date_value_next) 
      AS (image_date timestamp, value double precision, accepted boolean);

    IF var_date_value_next IS NULL THEN
        RETURN 'NaN';
    END IF;

    RAISE NOTICE 'var_date_value_next %', var_date_value_next;
    RAISE NOTICE 'var_ndvi_value_next %', var_ndvi_value_next;
    RAISE NOTICE 'var_accepted_next %', var_accepted_next;

    -- Si el anterior y siguiente fueron aceptados, los promedio, los devuelvo, y listo.
    IF var_accepted_prev AND var_accepted_next THEN
        RETURN (var_ndvi_value_prev + var_ndvi_value_next) / 2;
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
            JOIN raster_layers rl ON raster_layer_id = rl.id and rl.layer_type_id = var_ndvi_layer_id
            WHERE image_date < var_date_value_prev AND pixel_id = arg_pixel_id
            ORDER BY image_date DESC LIMIT 1;

        SELECT image_date, value, accepted
          INTO var_date_value_prev_2, var_ndvi_value_prev_2, var_accepted_prev_2
        FROM focus_get_ndvi_quality_raw(arg_map_id, arg_use_id, arg_pixel_id, var_date_value_prev_2) 
          AS (image_date timestamp, value double precision, accepted boolean);

        IF var_date_value_prev_2 IS NULL THEN
            RETURN 'NaN';
        END IF;

        RAISE NOTICE 'var_date_value_prev_2 %', var_date_value_prev_2;
        RAISE NOTICE 'var_ndvi_value_prev_2 %', var_ndvi_value_prev_2;
        RAISE NOTICE 'var_accepted_prev_2 %', var_accepted_prev_2;

        -- Si falla aca, no puedo hacer nada.
        IF NOT var_accepted_prev_2 THEN
            RETURN 'NaN';
        END IF;

        -- Pondero el dato
        RETURN var_ndvi_value_next * 0.66 + var_ndvi_value_prev_2 * 0.33;
    ELSE
        SELECT
            rl.image_date INTO var_date_value_next_2
            FROM pixel_values
            JOIN raster_layers rl ON raster_layer_id = rl.id and rl.layer_type_id = var_ndvi_layer_id
            WHERE image_date > var_date_value_next AND pixel_id = arg_pixel_id
            ORDER BY image_date ASC LIMIT 1;

        SELECT image_date, value, accepted
          INTO var_date_value_next_2, var_ndvi_value_next_2, var_accepted_next_2
        FROM focus_get_ndvi_quality_raw(arg_map_id, arg_use_id, arg_pixel_id, var_date_value_next_2) 
          AS (image_date timestamp, value double precision, accepted boolean);

        IF var_date_value_next_2 IS NULL THEN
            RETURN 'NaN';
        END IF;

        RAISE NOTICE 'var_date_value_next_2 %', var_date_value_next_2;
        RAISE NOTICE 'var_ndvi_value_next_2 %', var_ndvi_value_next_2;
        RAISE NOTICE 'var_accepted_next_2 %', var_accepted_next_2;

        -- Si falla aca, no puedo hacer nada.
        IF NOT var_accepted_next_2 THEN
            RETURN 'NAN';
        END IF;

        -- Pondero el dato
        RETURN var_ndvi_value_prev * 0.66 + var_ndvi_value_next_2 * 0.33;
    END IF;

    RETURN NULL;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
/*
SELECT 629950490, focus_get_ndvi_quality(1,629950490,'2013-01-02'::timestamp)
UNION
SELECT 629950487, focus_get_ndvi_quality(1,629950487,'2013-01-02'::timestamp)
UNION
SELECT 629950488, focus_get_ndvi_quality(1,629950488,'2013-01-02'::timestamp)
UNION
SELECT 629950489, focus_get_ndvi_quality(1,629950489,'2013-01-02'::timestamp)
UNION
SELECT 629950490, focus_get_ndvi_quality(1,629950490,'2013-01-02'::timestamp)
UNION*/
/*SELECT 1, focus_get_ndvi_quality(1, NULL,629950491,'2013-01-02'::timestamp)
UNION
SELECT 2, focus_get_ndvi_quality(1, NULL,629950491,'2012-01-01'::timestamp)
UNION
SELECT 3, focus_get_ndvi_quality(1, NULL,629950491,'2012-06-10'::timestamp)
UNION
SELECT 4, focus_get_ndvi_quality(1, NULL,629950491,'2012-06-22'::timestamp)
*/
/*UNION
SELECT 630132921, focus_get_ndvi_quality(1,630132921,'2013-01-02'::timestamp)
UNION
SELECT 630104130, focus_get_ndvi_quality(1,630104130,'2013-01-02'::timestamp);
*/
--order by 1
/*
select * from pixel_values
JOIN raster_layers rl ON raster_layer_id = rl.id and rl.layer_type_id = 1 and pixel_id = 629950491-- and rl.image_date = '2011-01-01'::timestamp
order by rl.image_date
limit 1000

update pixel_values SET value = B'0000100001000111'::integer::double precision where id in (47239744,47285572)
*/

--select focus_get_parameter('blah'::text, '2011-01-01'::date, 81, 3)

--select 2116::bit(16) precision
