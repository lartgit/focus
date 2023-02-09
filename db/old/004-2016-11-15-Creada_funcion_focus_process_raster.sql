
BEGIN;

CREATE OR REPLACE FUNCTION focus_process_raster(
    arg_rast raster,
    arg_layer_type_id integer,
    arg_raster_file_id integer,
    arg_tmp_table regclass,
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
        INSERT INTO raster_layers (raster_file_id, layer_type_id) VALUES (arg_raster_file_id, arg_layer_type_id) RETURNING id INTO func_raster_layer_id;
    END IF;

    -- Esta sentencia es para obtener los píxeles que intersectan lotes.
    -- TODO: Si en algun momento postgis implementa 'geometry ST_Transform(geometry geom, text from_proj, integer to_srid);', habria que usarlo
    FOR row IN SELECT p.id AS pixel_id, r.geom AS geom, r.val AS value, r.x, r.y, ST_Area(St_intersection(ST_Transform(St_SetSRID(r.geom, arg_s_srid), 4326), p.the_geom)) / ST_Area(p.the_geom) as perc_area FROM ST_PixelAsPolygons(arg_rast) r JOIN pixel p on St_intersects(ST_Transform(St_SetSRID(r.geom, arg_s_srid), 4326), p.the_geom)
    LOOP
        new_value = row.value * arg_scale_factor + arg_offset_value;

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

CREATE TABLE public.pixel_values
(
    id serial, 
    ts timestamp without time zone DEFAULT NOW(), 
    created_at timestamp without time zone DEFAULT NOW(), 
    pixel_id integer, 
    raster_layer_id integer, 
    value double precision, 
    ammount integer,
    sum_area double precision, 
    CONSTRAINT pixel_values_pk PRIMARY KEY (id),
    CONSTRAINT pixel_values_raster_layer_id_fk FOREIGN KEY (raster_layer_id)
        REFERENCES public.raster_layers (id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE CASCADE,
    CONSTRAINT pixel_values_pixel_id_fk FOREIGN KEY (pixel_id)
        REFERENCES public.pixel (id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE CASCADE
);
CREATE INDEX pixel_values_pixel_id_idx ON pixel_values (pixel_id ASC NULLS LAST);
CREATE INDEX pixel_values_raster_layer_pixel_id_idx ON pixel_values (raster_layer_id ASC NULLS LAST, pixel_id ASC NULLS LAST);

/*
ALTER TABLE layer_types
   ALTER COLUMN name TYPE character varying(250);
*/

CREATE TABLE log_import_images
(
    id serial NOT NULL,
    description text,
    process_id integer,
    ts timestamp without time zone NOT NULL DEFAULT now(),
    CONSTRAINT log_import_images_pk PRIMARY KEY (id),
    CONSTRAINT process_id_to_process_images_id FOREIGN KEY (process_id)
        REFERENCES process_images (id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE CASCADE
);

CREATE OR REPLACE FUNCTION wavg_sfunc(
    agg_state point,
    value double precision,
    weight double precision)
  RETURNS point AS
$BODY$
declare
    value_sum double precision;
    area_sum double precision;
begin
    value_sum = agg_state[0] + value*weight;
    area_sum = agg_state[1] + weight;

    return point(value_sum, area_sum);
end;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

CREATE OR REPLACE FUNCTION wavg_finalfunc(agg_state point)
  RETURNS double precision AS
$BODY$
begin
    return agg_state[0] / agg_state[1];
end;
$BODY$
  LANGUAGE plpgsql IMMUTABLE STRICT
  COST 100;


CREATE AGGREGATE weighted_avg(double precision, double precision)
(
    sfunc = wavg_sfunc,
    stype = point,
    finalfunc = wavg_finalfunc,
    initcond = '(0,0)'
);

COMMIT;
