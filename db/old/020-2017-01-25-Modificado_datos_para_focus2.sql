
BEGIN;

-- Error en wavg_finalfunc con una division por 0
DROP AGGREGATE weighted_avg(double precision, double precision);
DROP FUNCTION IF EXISTS wavg_finalfunc(point);
DROP FUNCTION IF EXISTS wavg_sfunc(point, double precision, double precision);

CREATE OR REPLACE FUNCTION wavg_finalfunc(agg_state point)
  RETURNS double precision AS
$BODY$
begin
    IF COALESCE(agg_state[1], 0) = 0 THEN
        RETURN 0;
    ELSE
        return agg_state[0] / agg_state[1];
    END IF;
end;
$BODY$
  LANGUAGE plpgsql IMMUTABLE STRICT
  COST 100;

CREATE FUNCTION wavg_sfunc(agg_state point, value double precision, weight double precision) RETURNS point
    LANGUAGE plpgsql IMMUTABLE
    AS $$
declare
    value_sum double precision;
    area_sum double precision;
begin
    value_sum = agg_state[0] + value*weight;
    area_sum = agg_state[1] + weight;

    return point(value_sum, area_sum);
end;
$$;

CREATE AGGREGATE weighted_avg(double precision, double precision) (
    SFUNC = wavg_sfunc,
    STYPE = point,
    INITCOND = '(0,0)',
    FINALFUNC = wavg_finalfunc
);

-- Fecha en raster_layers
DROP FUNCTION IF EXISTS focus_process_raster(raster, integer, integer, regclass, integer, double precision, double precision);

CREATE OR REPLACE FUNCTION focus_process_raster(
    arg_rast raster,
    arg_layer_type_id integer,
    arg_raster_file_id integer,
    arg_tmp_table regclass,
    arg_image_date date,
    arg_s_srid integer DEFAULT 9001,
    arg_scale_factor double precision DEFAULT 1.0,
    arg_offset_value double precision DEFAULT 0.0)
  RETURNS text AS
$BODY$
DECLARE
    row record;
    func_raster_layer_id integer;
    amt integer;
    func_pixel_value_id integer;
    new_value double precision;
BEGIN
    amt = 0;

    SELECT id into func_raster_layer_id FROM raster_layers WHERE raster_file_id = arg_raster_file_id AND layer_type_id = arg_layer_type_id;

    IF func_raster_layer_id IS NULL THEN
        INSERT INTO raster_layers (raster_file_id, layer_type_id, image_date) VALUES (arg_raster_file_id, arg_layer_type_id, arg_image_date) RETURNING id INTO func_raster_layer_id;
    END IF;

    -- Esta sentencia es para obtener los píxeles que intersectan lotes.
    -- TODO: Si en algun momento postgis implementa 'geometry ST_Transform(geometry geom, text from_proj, integer to_srid);', habria que usarlo
    FOR row IN SELECT p.id AS pixel_id, r.geom AS geom, r.val AS value, r.x, r.y, ST_Area(St_intersection(ST_Transform(St_SetSRID(r.geom, arg_s_srid), 4326), p.the_geom)) / ST_Area(p.the_geom) as perc_area FROM ST_PixelAsPolygons(arg_rast) r JOIN pixel p on St_intersects(ST_Transform(St_SetSRID(r.geom, arg_s_srid), 4326), p.the_geom)
    LOOP
        -- Cambie el * por un / ya que MODIS al parecer no sabe documentar
        new_value = (row.value / arg_scale_factor) + arg_offset_value;

        EXECUTE format('INSERT INTO %s (pixel_id, raster_layer_id, value, perc_insersect) VALUES (%s, %s, %s, %s);', arg_tmp_table, row.pixel_id, func_raster_layer_id, new_value, row.perc_area);
    
        /*
        -- Me fijo si para ese (raster_layer_id, pixel) ya hay un valor cargado.
        SELECT id INTO func_pixel_value_id FROM pixel_values WHERE raster_layer_id = func_raster_layer_id AND pixel_id = row.pixel_id;

        -- si es NULL, no hay
        IF func_pixel_value_id IS NULL THEN
            INSERT INTO pixel_values (raster_layer_id, pixel_id, value, ammount, sum_area) VALUES (func_raster_layer_id, row.pixel_id, new_value * row.perc_area, 1, row.perc_area);
        ELSE
            UPDATE pixel_values SET value = value+new_value*row.perc_area, ammount = ammount + 1, sum_area = sum_area + row.perc_area WHERE id = func_pixel_value_id;
        END IF;
        */

        amt = amt+1;
    END LOOP;

    RETURN 'Processed pixels: ' || amt;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- Modificada funcion focus_cast_to_double
DROP FUNCTION IF EXISTS focus_cast_to_double(text);

CREATE OR REPLACE FUNCTION focus_cast_to_double(v_input text)
  RETURNS double precision AS
$BODY$
DECLARE v_int_value DOUBLE PRECISION DEFAULT NULL;
BEGIN
    BEGIN
        v_int_value := v_input::double precision;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Invalid double precision value: "%".  Returning NULL.', v_input;
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

-- Modificada funcion focus_get_parameter
DROP FUNCTION IF EXISTS focus_get_parameter(text, date, integer, integer);

CREATE OR REPLACE FUNCTION focus_get_parameter(
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


COMMIT;
