-- Function: public.focus_get_evi_quality_raw(integer, integer, integer, timestamp without time zone)

-- DROP FUNCTION public.focus_get_evi_quality_raw(integer, integer, integer, timestamp without time zone);

CREATE OR REPLACE FUNCTION public.focus_get_evi_quality_raw(
    arg_map_id integer,
    arg_use_id integer,
    arg_pixel_id integer,
    arg_date timestamp without time zone)
  RETURNS record AS
$BODY$
DECLARE
paramRet RECORD;

var_evi_layer_id integer;
var_accepted BOOLEAN;

var_evi_value double precision;
var_date_value timestamp;

BEGIN
    /* Esta funcion sirve para obtener el dato de evi y aceptacion de calidad de la base de datos, sin filtro por calidad.
     * Argumentos:
     *   arg_map_id integer Id de mapa para pasarle los parametros de calidad
     *   arg_pixel_id integer Id de pixel que se quiere obtener los datos
     *   arg_date timestamp Fecha para la cual obtener los datos (se selecciona la la imagen mas cercana a la fecha)
     *
     * Retorna:
     *   Record:
     *     1. timestamp: Fecha de imagen seleccionada, NULL si no hay datos.
     *     2. double precision: evi del pixel seleccionado, NULL si no hay datos.
     *     3. boolean: salida de la funcion de calidad para el pixel dado, false si no hay datos.
     */


    SELECT id INTO var_evi_layer_id FROM layer_types WHERE name = '250m 16 days EVI';

    --RAISE NOTICE 'var_evi_layer_id %', var_evi_layer_id;

    SELECT
        value, image_date
        INTO
        var_evi_value, var_date_value
    FROM (
        SELECT
            value, rl.image_date as image_date,
            CASE WHEN ((rl.image_date - arg_date) < INTERVAL '0') THEN (arg_date - rl.image_date) ELSE (rl.image_date - arg_date) END as abs_diff
            FROM pixel_values
            JOIN raster_layers rl ON raster_layer_id = rl.id and rl.layer_type_id = var_evi_layer_id
            WHERE pixel_id = arg_pixel_id
            ORDER BY 3 ASC LIMIT 1
    ) a;

    IF var_date_value IS NULL THEN
    SELECT NULL, NULL, f INTO paramRet;
        RETURN paramRet;
    END IF;

    IF var_evi_value > 1 THEN
        var_evi_value = var_evi_value / 100000000;
    END IF;

    --RAISE NOTICE 'var_evi_value %', var_evi_value;
    --RAISE NOTICE 'var_date_value %', var_date_value;

    SELECT accepted
    INTO var_accepted
    FROM focus_get_quality(arg_map_id, arg_use_id, arg_pixel_id, arg_date) AS (
        date_value timestamp,
        accepted boolean
    );

    --RAISE NOTICE 'var_accepted %', var_accepted;

    SELECT var_date_value, var_evi_value, var_accepted INTO paramRet;
    RETURN paramRet;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

