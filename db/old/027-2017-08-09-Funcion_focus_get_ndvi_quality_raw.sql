CREATE OR REPLACE FUNCTION focus_get_ndvi_quality_raw (
    arg_map_id integer,
    arg_use_id integer,
    arg_pixel_id integer,
    arg_date timestamp)
  RETURNS RECORD AS
$BODY$
DECLARE
paramRet RECORD;

var_ndvi_layer_id integer;
var_accepted BOOLEAN;

var_ndvi_value double precision;
var_date_value timestamp;

BEGIN
    /* Esta funcion sirve para obtener el dato de ndvi y aceptacion de calidad de la base de datos, sin filtro por calidad.
     * Argumentos:
     *   arg_map_id integer Id de mapa para pasarle los parametros de calidad
     *   arg_pixel_id integer Id de pixel que se quiere obtener los datos
     *   arg_date timestamp Fecha para la cual obtener los datos (se selecciona la la imagen mas cercana a la fecha)
     *
     * Retorna:
     *   Record:
     *     1. timestamp: Fecha de imagen seleccionada, NULL si no hay datos.
     *     2. double precision: NDVI del pixel seleccionado, NULL si no hay datos.
     *     3. boolean: salida de la funcion de calidad para el pixel dado, false si no hay datos.
     */


    SELECT id INTO var_ndvi_layer_id FROM layer_types WHERE name = '250m 16 days NDVI';

    --RAISE NOTICE 'var_ndvi_layer_id %', var_ndvi_layer_id;

    SELECT
        value, image_date
        INTO
        var_ndvi_value, var_date_value
    FROM (
        SELECT
            value, rl.image_date as image_date,
            CASE WHEN ((rl.image_date - arg_date) < INTERVAL '0') THEN (arg_date - rl.image_date) ELSE (rl.image_date - arg_date) END as abs_diff
            FROM pixel_values
            JOIN raster_layers rl ON raster_layer_id = rl.id and rl.layer_type_id = var_ndvi_layer_id
            WHERE pixel_id = arg_pixel_id
            ORDER BY 3 ASC LIMIT 1
    ) a;

    IF var_date_value IS NULL THEN
	SELECT NULL, NULL, f INTO paramRet;
        RETURN paramRet;
    END IF;

    IF var_ndvi_value > 1 THEN
        var_ndvi_value = var_ndvi_value / 100000000;
    END IF;

    --RAISE NOTICE 'var_ndvi_value %', var_ndvi_value;
    --RAISE NOTICE 'var_date_value %', var_date_value;

    SELECT accepted
    INTO var_accepted
    FROM focus_get_quality(arg_map_id, arg_use_id, arg_pixel_id, arg_date) AS (
        date_value timestamp,
        accepted boolean
    );

    --RAISE NOTICE 'var_accepted %', var_accepted;

    SELECT var_date_value, var_ndvi_value, var_accepted INTO paramRet;
    RETURN paramRet;
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
UNION*//*
SELECT 1, focus_get_ndvi_quality_raw(1,NULL,629950491,'2013-01-02'::timestamp)
UNION
SELECT 2, focus_get_ndvi_quality_raw(1,NULL,629950491,'2012-01-01'::timestamp)
UNION
SELECT 3, focus_get_ndvi_quality_raw(1,NULL,629950491,'2012-06-10'::timestamp)
UNION
SELECT 4, focus_get_ndvi_quality_raw(1,NULL,629950491,'2012-06-22'::timestamp)
*//*UNION
SELECT 630132921, focus_get_ndvi_quality(1,630132921,'2013-01-02'::timestamp)
UNION
SELECT 630104130, focus_get_ndvi_quality(1,630104130,'2013-01-02'::timestamp);
*/
/*
select * from pixel_values
JOIN raster_layers rl ON raster_layer_id = rl.id and rl.layer_type_id = 1 and pixel_id = 629950491-- and rl.image_date = '2011-01-01'::timestamp
order by rl.image_date
limit 1000

update pixel_values SET value = B'0000100001000111'::integer::double precision where id in (47239744,47285572)
*/

