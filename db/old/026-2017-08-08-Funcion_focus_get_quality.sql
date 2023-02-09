--BEGIN;

CREATE OR REPLACE FUNCTION focus_get_quality(
    arg_map_id integer,
    arg_use_id integer,
    arg_pixel_id integer,
    arg_date timestamp)
  RETURNS RECORD AS
$BODY$
DECLARE
paramRet RECORD;

var_qi_layer_id integer;
var_qi_value integer;
var_date_value timestamp;

var_modland_qa integer;
var_vi_usefulness integer;
var_aerosol_quantity integer;
var_adjacent_cloud_detected integer;
var_brdf_correction integer;
var_mixed_clouds integer;
var_land_water integer;
var_snow integer;
var_shadow integer;

var_tmp_modland_qa text;
var_tmp_aerosol_quantity text;
var_tmp_mixed_clouds text;
var_tmp_land_water text;
var_tmp_snow text;
var_tmp_shadow text;

var_region_id integer;

var_accepted boolean;
BEGIN
    SELECT id INTO var_qi_layer_id FROM layer_types WHERE name = '250m 16 days VI Quality';

    SELECT
        image_date, value
        INTO
        var_date_value, var_qi_value
    FROM (
        SELECT
            ROUND(value::numeric, 0) as value, rl.image_date as image_date,
            CASE WHEN ((rl.image_date - arg_date) < INTERVAL '0') THEN (arg_date - rl.image_date) ELSE (rl.image_date - arg_date) END as abs_diff
            FROM pixel_values
            JOIN raster_layers rl ON raster_layer_id = rl.id and rl.layer_type_id = var_qi_layer_id
            WHERE pixel_id = arg_pixel_id
            ORDER BY 3 ASC LIMIT 1
    ) a;

    --RAISE NOTICE 'var_qi_value %', var_qi_value;
    --RAISE NOTICE 'var_date_value %', var_date_value;

    var_modland_qa :=               var_qi_value        & 3;
    var_vi_usefulness :=           (var_qi_value >> 2)  & 15;
    var_aerosol_quantity :=        (var_qi_value >> 6)  & 3;
    var_adjacent_cloud_detected := (var_qi_value >> 8)  & 1;
    var_brdf_correction :=         (var_qi_value >> 9)  & 1;
    var_mixed_clouds :=            (var_qi_value >> 10) & 1;
    var_land_water :=              (var_qi_value >> 11) & 7;
    var_snow :=                    (var_qi_value >> 14) & 1;
    var_shadow :=                  (var_qi_value >> 15) & 1;

    SELECT r.id INTO var_region_id
    FROM regions r JOIN pixel p ON st_intersects(r.the_geom, p.the_geom)
    WHERE map_id = arg_map_id AND p.id = arg_pixel_id
    order by ST_Area(ST_Intersection(r.the_geom, p.the_geom))/ST_Area(p.the_geom) DESC
    LIMIT 1;

    IF var_region_id IS NOT NULL THEN
	select focus_get_parameter('modland_qa'::text, var_date_value::date, arg_use_id, var_region_id) INTO var_tmp_modland_qa;
	select focus_get_parameter('aerosol_quantity'::text, var_date_value::date, arg_use_id, var_region_id) INTO var_tmp_aerosol_quantity;
	select focus_get_parameter('mixed_clouds'::text, var_date_value::date, arg_use_id, var_region_id) INTO var_tmp_mixed_clouds;
	select focus_get_parameter('land_water'::text, var_date_value::date, arg_use_id, var_region_id) INTO var_tmp_land_water;
	select focus_get_parameter('snow'::text, var_date_value::date, arg_use_id, var_region_id) INTO var_tmp_snow;
	select focus_get_parameter('shadow'::text, var_date_value::date, arg_use_id, var_region_id) INTO var_tmp_shadow;
    END IF;

    BEGIN
        IF ((SELECT bool_or(var_modland_qa = opts::integer::bit(2)::integer)
                FROM unnest(('{'||COALESCE(var_tmp_modland_qa, '00,01')||'}')::text[]) as opts) AND
            (SELECT bool_or(var_aerosol_quantity = opts::integer::bit(2)::integer)
                FROM unnest(('{'||COALESCE(var_tmp_aerosol_quantity, '00,01')||'}')::text[]) as opts) AND
            (SELECT bool_or(var_mixed_clouds = opts::integer::bit(1)::integer)
                FROM unnest(('{'||COALESCE(var_tmp_mixed_clouds, '0')||'}')::text[]) as opts) AND
            (SELECT bool_or(var_land_water = opts::integer::bit(3)::integer)
                FROM unnest(('{'||COALESCE(var_tmp_land_water, '001')||'}')::text[]) as opts) AND
            (SELECT bool_or(var_snow = opts::integer::bit(1)::integer)
                FROM unnest(('{'||COALESCE(var_tmp_snow, '0')||'}')::text[]) as opts) AND
            (SELECT bool_or(var_shadow = opts::integer::bit(1)::integer)
                FROM unnest(('{'||COALESCE(var_tmp_shadow, '0')||'}')::text[]) as opts)) THEN

            var_accepted := true;
        ELSE
            var_accepted := false;
        END IF;
    EXCEPTION
        WHEN others THEN
            RAISE NOTICE '% %', SQLERRM, SQLSTATE;
            var_accepted := false;
    END; 

    SELECT var_date_value as date_value,
           var_accepted as accepted
    INTO paramRet;

    RETURN paramRet;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

--COMMIT;
/*
SELECT 629950490, focus_get_quality(1, NULL, 629950490,'2011-01-02'::timestamp)
UNION
SELECT 629950487, focus_get_quality(1, NULL, 629950487,'2011-01-02'::timestamp)
UNION
SELECT 629950488, focus_get_quality(1, NULL, 629950488,'2011-01-02'::timestamp)
UNION
SELECT 629950489, focus_get_quality(1, NULL, 629950489,'2011-01-02'::timestamp)
UNION
SELECT 629950490, focus_get_quality(1, NULL, 629950490,'2011-01-02'::timestamp)
UNION
SELECT 629950491, focus_get_quality(1, NULL, 629950491,'2011-01-02'::timestamp)
UNION
SELECT 630056104, focus_get_quality(1, NULL, 630056104,'2011-01-02'::timestamp)
UNION
SELECT 630132920, focus_get_quality(1, NULL, 630132920,'2011-01-02'::timestamp)
UNION
SELECT 630099328, focus_get_quality(1, NULL, 630099328,'2011-01-02'::timestamp)
UNION
SELECT 630132921, focus_get_quality(1, NULL, 630132921,'2011-01-02'::timestamp)
UNION
SELECT 630104130, focus_get_quality(1, NULL, 630104130,'2011-01-02'::timestamp);
*/
/*
select distinct on (value) * from pixel_values
JOIN raster_layers rl ON raster_layer_id = rl.id and rl.layer_type_id = 4 and rl.image_date = '2011-01-01'::timestamp
limit 1000
*/
--SELECT focus_get_parameter('modland_qa', '2011-01-01'::date, 81, 12)

--select * from regions where id = 92

