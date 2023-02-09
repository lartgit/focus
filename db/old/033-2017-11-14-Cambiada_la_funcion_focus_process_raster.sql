BEGIN;
-- Function: public.focus_process_raster(raster, integer, integer, regclass, date, integer, double precision, double precision)

DROP FUNCTION public.focus_process_raster(raster, integer, integer, regclass, date, integer, double precision, double precision);

CREATE OR REPLACE FUNCTION public.focus_process_raster(
    arg_rast character varying,
    arg_tmp_table regclass,
    arg_raster_layer_id integer,
    arg_s_srid integer DEFAULT 9001,
    arg_scale_factor double precision DEFAULT 1.0,
    arg_offset_value double precision DEFAULT 0.0)
  RETURNS text AS
$BODY$
DECLARE
BEGIN

        EXECUTE format('INSERT INTO %s (pixel_id, raster_layer_id, value, perc_insersect)
               SELECT p.id AS pixel_id, %s, r.val * %s + %s, ST_Area(St_intersection(ST_Transform(St_SetSRID(r.geom, %s), 4326), p.the_geom)) / ST_Area(p.the_geom) as perc_area 
               FROM ST_PixelAsPolygons(''%s''::raster) r 
               JOIN pixel p on St_intersects(ST_Transform(St_SetSRID(r.geom, %s), 4326), p.the_geom)
                           AND              (ST_Transform(St_SetSRID(r.geom, %s), 4326) && p.the_geom);', arg_tmp_table, arg_raster_layer_id, arg_scale_factor, arg_offset_value, arg_s_srid, arg_rast, arg_s_srid, arg_s_srid);

    RETURN 'Processed pixels';
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

COMMIT;