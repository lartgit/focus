<?php

if (!defined('BASEPATH'))
   exit('No direct script access allowed');

/**
 * Description:
 * Esta clase devuelve la view index para los resultados.
 * Para la view index deberiamos mostrar unicamente
 * 2000 registros porque datatbles explota
 * para la exportacion a shp exportamos los datos completos
 *
 * @author Ariel Ramirez <ariel.ramirez@r2software.net>
 * @package Focus II
 */
class Results_two extends R2_DbObject {

   /**  Variables Static de Configuración del Model */
   protected static $_table_name = 'results_f2';
   // protected static $_display_name = 'Relación para exportación ';
   // protected static $_plural_name = 'Procesos de Relaciones para exportación';

    /** Variables Públicas del Model */
       public $key;
       public $value;
       public $process_result_id;
       public $process_focus_id;

    public static $_row_limit = 200;
    public static $_aggregates = array(
        "min_string" => "min",
        "max_string" => "max",
        "min_number" => "min",
        "max_number" => "max",
        "avg" => "avg",
        "weighted_avg" => "weighted_avg",
        "string_agg" => "string_agg"
    );

    /** Construct */
    public function __construct() {
        parent::__construct();
    }

    /**
    * Description
    * Metodo que devuelve la tabla para la view de index cuando el usuario viene de la pantalla
    * de procesos focus 2 y trae por get el id del proceso.
    * @param $process_id id del proceso focus 2
    */

    public static function get_index_data($process_id)
    {
        return static::filtered_results_by_process_id($process_id);
    }

    /**
     * Metodo que retorna un array de columnas para un proceso focus 2 id
     * basicamente hace un disctint a key
        * @param $process_id id del proceso focus 2
     * @return array
     */
    public static function get_table_headers($process_id)
    {
        $CI = get_instance();
        $CI->db->distinct();
        $CI->db->select('key');
        $CI->db->where(array('process_focus_id' => $process_id));
        $CI->db->order_by('key');
        $columns = array();

        $result_db = $CI->db->get(static::$_table_name)->result(get_called_class());
        if (!empty($result_db))
            foreach ($result_db as $col)
                $columns[] = strtolower($col->key);

        return $columns;
    }

    private static function order_headers_like_in_function($process_id, $keys)
    {
        $CI = get_instance();
        $result_db = $CI->db->query("
            SELECT
                f.column_name
            FROM process_functions pf
            JOIN functions f ON f.id = pf.function_id
            WHERE pf.id = '$process_id'
        ")->result();
        if (empty($result_db))
            return $keys;
        $columns = explode(',', $result_db[0]->column_name);
        if (empty($columns)) {
            return $keys;
        }
        $ret = array();
        foreach($columns as $column) {
            if (in_array(strtolower($column), $keys)) {
                $ret[] = strtolower($column);
            }
        }
        if(!count($ret)) return $keys;
        return $ret;
    }



    /**
     * Investigando un poco ,para no tener que parsear un objeto db
     * usar cortes de control y demas, encontre la funcion crosstabs que viene dentro la extension de postgres tablefunc
     * -- CREATE EXTENSION tablefunc;
     * Viene dentro de paquete de postgres a partir de 9.1 con lo cual no hay que incluir ningun packete externo como el caso de postgis
     * Dejo e link donde tome el ejemplo y el link a la documentacion de postgres
        * http://stackoverflow.com/questions/15415446/pivot-on-multiple-columns-using-tablefunc/15421607#15421607
        * https://www.postgresql.org/docs/current/static/tablefunc.html
        * @param $process_id id del proceso focus 2
        * @param $keys columnas que el usuario quiere calcular en el proceso
        * @return db result o empty array
     */
    public static function filtered_results_by_process_id($process_id)
    {
        $keys = static::get_table_headers($process_id);

        if (!empty($keys)) {
            $CI = get_instance();

            if (!empty($keys) && !is_null($process_id) && $process_id != '') {
                $keys = static::order_headers_like_in_function($process_id, $keys);

                $keys_columns = array();
                foreach ($keys as $value) {
                    $keys_columns[] = "round(focus_GarbageToDouble(result_f2.\"$value\")::numeric, 2) as \"$value\"";
                }

                $qresult = $CI->db->query('SELECT
                extract(\'year\' from to_timestamp(result_f2.pivot[3])::date) AS "'.lang("focus2_year").'",
                extract(\'month\' from to_timestamp(result_f2.pivot[3])::date) AS "'.lang("focus2_month").'",
                extract(\'day\' from to_timestamp(result_f2.pivot[3])::date) AS "'.lang("focus2_day").'",
                regions.name AS "'.lang("focus2_udeveg").'",
                fields.group_name AS "'.lang("focus2_group_name").'",
                rf1.farm_name AS "'.lang("focus2_farm_name").'",
                rf1.field_name AS "'.lang("focus2_field_name").'",
                st_area(fields.the_geom::geography)/10000 AS "'.lang("focus2_field_area").'",
                rf1.latitud AS "'.lang("focus2_lat").'",
                rf1.longitud AS "'.lang("focus2_lon").'",
                rf1.pixel_id AS "'.lang("focus2_pixel_id").'",
                rf1.intersect_idx AS "'.lang("focus2_intersect_idx").'",
                rf1.use_concrete_name AS "'.lang("focus2_use_concrete_name").'",
                rf1.uses_date_from AS "'.lang("focus2_uses_date_from").'",
                rf1.uses_date_to AS "'.lang("focus2_uses_date_to").'",
                '.join(', ', $keys_columns).' FROM (
                    SELECT *
                    FROM crosstab($$
                            SELECT ARRAY[process_result_id, process_focus_id, EXTRACT(\'epoch\' from date::timestamptz)], LOWER(key)::text,value::text
                            FROM   results_f2
                            WHERE process_focus_id = '.$process_id.'
                            ORDER  BY 1,2
                         $$,
                         $$
                            VALUES (\''.join('\'), (\'', $keys).'\')
                         $$
                    )
                    AS crosstabtable_f1 (pivot int[], "'.join('" text, "', $keys).'" text)
                ) result_f2
                JOIN result_focus1 rf1 ON rf1.result_id = result_f2.pivot[1]
                    AND COALESCE(EXTRACT(\'epoch\' from field_date_from) <= result_f2.pivot[3], TRUE)
                    AND COALESCE(EXTRACT(\'epoch\' from field_date_to) >= result_f2.pivot[3], TRUE)
                    AND COALESCE(EXTRACT(\'epoch\' from uses_date_from) <= result_f2.pivot[3], TRUE)
                    AND COALESCE(EXTRACT(\'epoch\' from uses_date_to) >= result_f2.pivot[3], TRUE)
                JOIN process_functions ON process_functions.id = result_f2.pivot[2]
                LEFT JOIN regions ON regions.map_id = process_functions.map_id 
                      AND regions.the_geom && rf1.the_geom 
                      AND ST_Intersects(ST_Centroid(rf1.the_geom), regions.the_geom)
                LEFT JOIN fields ON fields.id = rf1.field_id
                LIMIT '.static::$_row_limit);
                return $qresult->result();
            }

            return array();
        }

        return array();
    }

    /**
     * Description
     * Metodo que devuelve la tabla para la view de index cuando el usuario filtra y submitea
     * @param $process_id id del proceso focus 2
     */
    public static function filtered_results_by_process_id_field($process_id, $aggregates)
    {
        $keys = static::get_table_headers($process_id);

        if (!empty($keys)) {
        $CI = get_instance();

            $extra_columns = array();
            $has_column = false;
            foreach ($aggregates as $key => $value) {
                if(!is_numeric($key) && in_array($key, $keys) && isset(static::$_aggregates[$value])) {
                    if($value == 'weighted_avg')
                        $extra_columns[] = 'round('.static::$_aggregates[$value] . "(focus_GarbageToDouble(result_f2.\"$key\"), intersect_idx::double precision)::numeric,2) as \"$key\"";
                    else if($value == 'string_agg')
                        $extra_columns[] = static::$_aggregates[$value] . "(round(focus_GarbageToDouble(result_f2.\"$key\")::numeric,2)::text, ', ') as \"$key\"";
                    else if($value == 'min_string')
                        $extra_columns[] = 'round('.static::$_aggregates[$value] . "(result_f2.\"$key\")::numeric,2) as \"$key\"";
                    else if($value == 'max_string')
                        $extra_columns[] = 'round('.static::$_aggregates[$value] . "(result_f2.\"$key\")::numeric,2) as \"$key\"";
                    else if($value == 'min_number')
                        $extra_columns[] = 'round('.static::$_aggregates[$value] . "(focus_GarbageToDouble(result_f2.\"$key\"))::numeric,2) as \"$key\"";
                    else if($value == 'max_number')
                        $extra_columns[] = 'round('.static::$_aggregates[$value] . "(focus_GarbageToDouble(result_f2.\"$key\"))::numeric,2) as \"$key\"";
                    else
                        $extra_columns[] = 'round('.static::$_aggregates[$value] . "(focus_GarbageToDouble(result_f2.\"$key\"))::numeric,2) as \"$key\"";

                    $has_column = true;
                }
            }

            if (!empty($keys) && !is_null($process_id) && $process_id != '') {
                // $qresult = $CI->db->query('SELECT lote, weighted_avg(valor_1::double precision, valor_2::double precision), avg(valor_2::int), string_agg(valor_3, \',\') FROM results_f1 rf1
                $qresult = $CI->db->query('SELECT
                    extract(\'year\' from to_timestamp(result_f2.pivot[3])::date) AS "'.lang("focus2_year").'",
                    extract(\'month\' from to_timestamp(result_f2.pivot[3])::date) AS "'.lang("focus2_month").'",
                    extract(\'day\' from to_timestamp(result_f2.pivot[3])::date) AS "'.lang("focus2_day").'",
                    regions.name AS "'.lang("focus2_udeveg").'",
                    min(fields.group_name) AS "'.lang("focus2_group_name").'",
                    min(rf1.farm_name) AS "'.lang("focus2_farm_name").'",
                    min(rf1.field_name) AS "'.lang("focus2_field_name").'",
                    st_area(fields.the_geom::geography)/10000 AS "'.lang("focus2_field_area").'",
                    st_x(st_centroid(fields.the_geom)) AS "'.lang("focus2_lon").'",
                    st_y(st_centroid(fields.the_geom)) AS "'.lang("focus2_lat").'",
                    count(*) AS "'.lang("focus2_data_count").'",
                    rf1.use_concrete_name AS "'.lang("focus2_use_concrete_name").'",
                    rf1.uses_date_from AS "'.lang("focus2_uses_date_from").'",
                    rf1.uses_date_to AS "'.lang("focus2_uses_date_to").'"
                    '.($has_column?', ':'').join(', ', $extra_columns).'
                    FROM (
                        SELECT *
                        FROM crosstab($$
                                SELECT ARRAY[process_result_id, process_focus_id, EXTRACT(\'epoch\' from date::timestamptz)], lower(key)::text,value::text
                                FROM results_f2
                                WHERE process_focus_id = '.$process_id.'
                                ORDER BY 1,2
                             $$, $$
                                VALUES (\''.join('\'), (\'', $keys).'\')
                             $$)
                        AS crosstabtable_f1 (pivot int[], "'.join('" text, "', $keys).'" text)
                    ) result_f2
                    join result_focus1 rf1 ON rf1.result_id = result_f2.pivot[1]
                      AND COALESCE(EXTRACT(\'epoch\' from field_date_from) <= result_f2.pivot[3], TRUE)
                      AND COALESCE(EXTRACT(\'epoch\' from field_date_to) >= result_f2.pivot[3], TRUE)
                      AND COALESCE(EXTRACT(\'epoch\' from uses_date_from) <= result_f2.pivot[3], TRUE)
                      AND COALESCE(EXTRACT(\'epoch\' from uses_date_to) >= result_f2.pivot[3], TRUE)
                    join process_functions on process_functions.id = result_f2.pivot[2]
                    left join regions ON regions.map_id = process_functions.map_id
                          AND regions.the_geom && rf1.the_geom
                          AND st_intersects(st_centroid(rf1.the_geom), regions.the_geom)
                    left join fields on fields.id = rf1.field_id
                    group by rf1.field_id, fields.id, process_functions.id, regions.id, to_timestamp(result_f2.pivot[3])::date, rf1.use_concrete_name, rf1.uses_date_from, rf1.uses_date_to
                    limit '.static::$_row_limit);

                    return $qresult->result();

            }

            return array();
        }

        return array();
    }

    public static function filtered_results_by_process_id_month($process_id)
    {
        $keys = static::get_table_headers($process_id);

        if (!empty($keys)) {
            $CI = get_instance();

            if (!empty($keys) && !is_null($process_id) && $process_id != '') {
                $keys = static::order_headers_like_in_function($process_id, $keys);

                $str_keys = $str_keys2 = $str_keys3 = $str_keys4 = array();
                foreach ($keys as $key) {
                    $str_keys[] = "result_f2.\"$key\"";
                    $str_keys2[] = "('$key')";
                    $str_keys3[] = "\"$key\" text";
                    $str_keys4[] = "round((CASE WHEN sum(CASE WHEN focus_GarbageToDouble(\"$key\") IS NOT NULL THEN intersect_idx * extract_days((daterange(datadate,lead_date,'[)') * monthrange)::daterange) / months_data.days ELSE 0 END) != 0 THEN sum(CASE WHEN focus_GarbageToDouble(\"$key\") IS NOT NULL THEN extract_days((daterange(datadate,lead_date,'[)') * monthrange)::daterange) / months_data.days * focus_GarbageToDouble(\"$key\") * intersect_idx ELSE 0 END) / sum(CASE WHEN focus_GarbageToDouble(\"$key\") IS NOT NULL THEN intersect_idx * extract_days((daterange(datadate,lead_date,'[)') * monthrange)::daterange) / months_data.days ELSE 0 END) ELSE null END)::numeric, 2) as \"$key\"";
                }
                $str_keys = join(', ', $str_keys);
                $str_keys2 = join(', ', $str_keys2);
                $str_keys3 = join(', ', $str_keys3);
                $str_keys4 = join(', ', $str_keys4);

                $qq = $CI->db->query("
                WITH data as (
                    SELECT
                        rf1.pixel_id as datapixel_id,
                        to_timestamp(result_f2.pivot[3])::date as datadate,
                        lead(to_timestamp(result_f2.pivot[3])::date) OVER (w) as lead_date,
                        extract('year' from to_timestamp(result_f2.pivot[3])::date) as year,
                        extract('month' from to_timestamp(result_f2.pivot[3])::date) as month,
                        extract('day' from to_timestamp(result_f2.pivot[3])::date) as day,
                        regions.name as udeveg,
                        rf1.latitud,
                        rf1.longitud,
                        rf1.intersect_idx,
                        fields.group_name,
                        rf1.field_name,
                        rf1.field_date_from,
                        rf1.field_date_to,
                        rf1.farm_name,
                        rf1.use_concrete_name,
                        rf1.uses_date_from,
                        rf1.uses_date_to,
                        ''::text as admin,
                        st_area(fields.the_geom::geography)/10000 as field_area,
                        $str_keys
                    FROM (
                        SELECT *
                        FROM crosstab($$
                            SELECT ARRAY[process_result_id, process_focus_id, EXTRACT('epoch' from date::timestamptz)], LOWER(key)::text,value::text
                            FROM results_f2
                            WHERE process_focus_id = $process_id
                            ORDER BY 1,2
                        $$,$$
                            VALUES $str_keys2
                        $$) AS crosstabtable_f1 (pivot int[], $str_keys3)
                    ) result_f2
                    JOIN result_focus1 rf1 ON rf1.result_id = result_f2.pivot[1]
                     AND COALESCE(EXTRACT('epoch' from field_date_from) <= result_f2.pivot[3], TRUE)
                     AND COALESCE(EXTRACT('epoch' from field_date_to)   >= result_f2.pivot[3], TRUE)
                     AND COALESCE(EXTRACT('epoch' from uses_date_from)  <= result_f2.pivot[3], TRUE)
                     AND COALESCE(EXTRACT('epoch' from uses_date_to)    >= result_f2.pivot[3], TRUE)
                    JOIN process_functions ON process_functions.id = result_f2.pivot[2]
                    LEFT JOIN regions ON regions.map_id = process_functions.map_id 
                     AND regions.the_geom && rf1.the_geom 
                     AND ST_Intersects(ST_Centroid(rf1.the_geom), regions.the_geom)
                    LEFT JOIN fields ON fields.id = rf1.field_id
                    WINDOW w AS (PARTITION BY rf1.pixel_id order by result_f2.pivot[3])
                ), months as (
                    -- Obtengo los meses representados en lso datos
                    SELECT DISTINCT ON (to_char(datadate, 'YYYY-MM'))
                        to_char(datadate, 'YYYY-MM') as month,
                        datadate as months_date,
                        (to_char(datadate, 'YYYY-MM') || '-01')::date as monthstart,
                        DATE_PART('days', DATE_TRUNC('month', (to_char(datadate, 'YYYY-MM') || '-01')::date) + '1 MONTH'::INTERVAL - '1 DAY'::INTERVAL) monthdays
                    FROM data
                ), months_data as (
                    SELECT
                        months.month, months_date,
                        DATE_PART('days', DATE_TRUNC('month', monthstart) + '1 MONTH'::INTERVAL - '1 DAY'::INTERVAL) as days,
                        DATERANGE(monthstart, (months.month || '-' || monthdays)::date, '[]') as monthrange
                    FROM months
                )
                SELECT
                    extract('year' from months_data.months_date) AS \"".lang("focus2_year")."\",
                    extract('month' from months_data.months_date) AS \"".lang("focus2_month")."\",
                    udeveg AS \"".lang("focus2_udeveg")."\", 
                    group_name AS \"".lang("focus2_group_name")."\",
                    farm_name AS \"".lang("focus2_farm_name")."\",
                    field_name AS \"".lang("focus2_field_name")."\",
                    latitud AS \"".lang("focus2_lat")."\", 
                    longitud AS \"".lang("focus2_lon")."\", 
                    datapixel_id AS \"".lang("focus2_pixel_id")."\",
                    intersect_idx AS \"".lang("focus2_intersect_idx")."\",
                    use_concrete_name AS \"".lang("focus2_use_concrete_name")."\",
                    uses_date_from AS \"".lang("focus2_uses_date_from")."\",
                    uses_date_to AS \"".lang("focus2_uses_date_to")."\",
                    /*string_agg(to_char(data.datadate, 'YYYY-MM-DD') || ' (' || extract_days((daterange(datadate,lead_date,'[)') * monthrange)::daterange) / months_data.days || ')', ', '),*/
                    /*count(*),*/
                    /*sum(extract_days((daterange(datadate,lead_date,'[)') * monthrange)::daterange) / months_data.days) fill_idx,*/
                    $str_keys4
                FROM months_data
                JOIN data ON not isempty(daterange(datadate,lead_date,'[)') * monthrange)
                GROUP BY months_data.months_date, months_data.month, datapixel_id, latitud, longitud, udeveg, intersect_idx, group_name, farm_name, field_name, use_concrete_name, uses_date_from, uses_date_to
                ORDER BY months_data.months_date, months_data.month, datapixel_id, latitud, longitud, udeveg, intersect_idx, group_name, farm_name, field_name, use_concrete_name, uses_date_from, uses_date_to
                LIMIT ".static::$_row_limit
                )->result();
                return $qq;
            }

            return array();
        }

        return array();
    }

    public static function filtered_results_by_process_id_month_field($process_id)
    {
        $keys = static::get_table_headers($process_id);

        if (!empty($keys)) {
            $CI = get_instance();

            if (!empty($keys) && !is_null($process_id) && $process_id != '') {
                $keys = static::order_headers_like_in_function($process_id, $keys);

                $str_keys = $str_keys2 = $str_keys3 = $str_keys4 = array();
                foreach ($keys as $key) {
                    $str_keys[] = "result_f2.\"$key\"";
                    $str_keys2[] = "('$key')";
                    $str_keys3[] = "\"$key\" text";
                    $str_keys4[] = "round((CASE WHEN sum(CASE WHEN focus_GarbageToDouble(\"$key\") IS NOT NULL THEN intersect_idx * extract_days((daterange(datadate,lead_date,'[)') * monthrange)::daterange) / months_data.days ELSE 0 END) != 0 THEN sum(CASE WHEN focus_GarbageToDouble(\"$key\") IS NOT NULL THEN extract_days((daterange(datadate,lead_date,'[)') * monthrange)::daterange) / months_data.days * focus_GarbageToDouble(\"$key\") * intersect_idx ELSE 0 END) / sum(CASE WHEN focus_GarbageToDouble(\"$key\") IS NOT NULL THEN intersect_idx * extract_days((daterange(datadate,lead_date,'[)') * monthrange)::daterange) / months_data.days ELSE 0 END) ELSE null END)::numeric, 2) as \"$key\"";
                }
                $str_keys = join(', ', $str_keys);
                $str_keys2 = join(', ', $str_keys2);
                $str_keys3 = join(', ', $str_keys3);
                $str_keys4 = join(', ', $str_keys4);

                $qq = $CI->db->query("
                WITH data as (
                    SELECT
                        to_timestamp(result_f2.pivot[3])::date as datadate,
                        lead(to_timestamp(result_f2.pivot[3])::date) OVER (w) as lead_date,
                        extract('year' from to_timestamp(result_f2.pivot[3])::date) as year,
                        extract('month' from to_timestamp(result_f2.pivot[3])::date) as month,
                        extract('day' from to_timestamp(result_f2.pivot[3])::date) as day,
                        regions.name as udeveg,
                        st_x(st_centroid(fields.the_geom)) as lon,
                        st_y(st_centroid(fields.the_geom)) as lat,
                        rf1.intersect_idx,
                        rf1.pixel_id rf1_pixel_id,
                        rf1.field_name,
                        rf1.field_date_from,
                        rf1.field_date_to,
                        fields.group_name,
                        rf1.farm_name,
                        rf1.use_concrete_name,
                        rf1.uses_date_from,
                        rf1.uses_date_to,
                        ''::text as admin,
                        st_area(fields.the_geom::geography)/10000 as field_area,
                        $str_keys
                    FROM (
                        SELECT *
                        FROM crosstab($$
                            SELECT ARRAY[process_result_id, process_focus_id, EXTRACT('epoch' from date::timestamptz)], lower(key)::text,value::text
                            FROM results_f2
                            WHERE process_focus_id = $process_id
                            ORDER BY 1,2
                        $$,$$
                            VALUES $str_keys2
                        $$) AS crosstabtable_f1 (pivot int[], $str_keys3)
                    ) result_f2
                    JOIN result_focus1 rf1 ON rf1.result_id = result_f2.pivot[1]
                     AND COALESCE(EXTRACT('epoch' from field_date_from) <= result_f2.pivot[3], TRUE)
                     AND COALESCE(EXTRACT('epoch' from field_date_to)   >= result_f2.pivot[3], TRUE)
                     AND COALESCE(EXTRACT('epoch' from uses_date_from)  <= result_f2.pivot[3], TRUE)
                     AND COALESCE(EXTRACT('epoch' from uses_date_to)    >= result_f2.pivot[3], TRUE)
                    JOIN process_functions ON process_functions.id = result_f2.pivot[2]
                    LEFT JOIN regions ON regions.map_id = process_functions.map_id 
                     AND regions.the_geom && rf1.the_geom 
                     AND ST_Intersects(ST_Centroid(rf1.the_geom), regions.the_geom)
                    LEFT JOIN fields ON fields.id = rf1.field_id
                    WINDOW w AS (PARTITION BY rf1.pixel_id order by result_f2.pivot[3])
                ), months as (
                    -- Obtengo los meses representados en lso datos
                    SELECT DISTINCT ON (to_char(datadate, 'YYYY-MM'))
                        to_char(datadate, 'YYYY-MM') as month,
                        datadate as months_date,
                        (to_char(datadate, 'YYYY-MM') || '-01')::date as monthstart,
                        DATE_PART('days', DATE_TRUNC('month', (to_char(datadate, 'YYYY-MM') || '-01')::date) + '1 MONTH'::INTERVAL - '1 DAY'::INTERVAL) monthdays
                    FROM data
                ), months_data as (
                    SELECT
                        months.month, months_date,
                        DATE_PART('days', DATE_TRUNC('month', monthstart) + '1 MONTH'::INTERVAL - '1 DAY'::INTERVAL) as days,
                        DATERANGE(monthstart, (months.month || '-' || monthdays)::date, '[]') as monthrange
                    FROM months
                )
                SELECT
                    extract('year' from months_data.months_date) as \"".lang("focus2_year")."\",
                    extract('month' from months_data.months_date) as \"".lang("focus2_month")."\",
                    udeveg as \"".lang("focus2_udeveg")."\",
                    group_name AS \"".lang("focus2_group_name")."\",
                    farm_name as \"".lang("focus2_farm_name")."\",
                    field_name as \"".lang("focus2_field_name")."\",
                    field_area as \"".lang("focus2_field_area")."\",
                    lat as \"".lang("focus2_lat")."\",
                    lon as \"".lang("focus2_lon")."\",
                    count(DISTINCT rf1_pixel_id) as \"".lang("focus2_data_count")."\",
                    use_concrete_name as \"".lang("focus2_use_concrete_name")."\",
                    uses_date_from as \"".lang("focus2_uses_date_from")."\",
                    uses_date_to as \"".lang("focus2_uses_date_to")."\",

                    /*string_agg(to_char(datadate, 'YYYY-MM-DD') || ' (' || extract_days((daterange(datadate,lead_date,'[)') * monthrange)::daterange) / months_data.days || ')', ', '),*/
                    /*count(*),*/
                    /*sum(extract_days((daterange(datadate,lead_date,'[)') * monthrange)::daterange) / months_data.days) fill_idx,*/
                    $str_keys4
                FROM months_data
                JOIN data ON not isempty(daterange(datadate,lead_date,'[)') * monthrange)
                WHERE COALESCE(to_char(field_date_from, 'YYYY-MM') <= months_data.month, TRUE)
                  AND COALESCE(to_char(field_date_to, 'YYYY-MM')   >= months_data.month, TRUE)
                  AND COALESCE(to_char(uses_date_from, 'YYYY-MM')  <= months_data.month, TRUE)
                  AND COALESCE(to_char(uses_date_to, 'YYYY-MM')    >= months_data.month, TRUE)
                GROUP BY months_data.months_date, months_data.month, udeveg, lat, lon, group_name, field_name, field_date_from, field_date_to, farm_name, field_area, use_concrete_name, uses_date_from, uses_date_to, admin
                ORDER BY months_data.months_date, months_data.month, udeveg, lat, lon, group_name, field_name, field_date_from, field_date_to, farm_name, field_area, use_concrete_name, uses_date_from, uses_date_to, admin
                LIMIT ".static::$_row_limit
                )->result();
                return $qq;
            }

            return array();
        }

        return array();
    }



    /**
     * Metodo que devuelve el shp
     */
    public static function datatable_to_shp($process_id, $folder)
    {
        $CI = get_instance();
        $folder = trim($folder, '/');
        $keys = static::get_table_headers($process_id);
        set_time_limit(0);
        $output = array();
        $return = '';
        $file_name = $CI->user->name . uniqid('-');

        $keys_columns = array();
        foreach ($keys as $value) {
            $keys_columns[] = "round(focus_GarbageToDouble(result_f2.\"$value\")::numeric, 2) as \"$value\"";
        }

        #Traemos los datos del archivo Config y Database para correr el proceso en el pgsql2shp
        $path = $CI->config->item('upload_path') . $folder;
        $dbname = $CI->db->database;
        $dbusername = $CI->db->username;
        $dbpassword = $CI->db->password;
        $dbhost = $CI->db->hostname;

        $tmp_table = "tmp.f2_" . bin2hex(random_bytes(5));
        $CI->db->query("CREATE TABLE $tmp_table AS (
            SELECT
                extract('year' from to_timestamp(result_f2.pivot[3])::date) AS \"".lang("focus2_year")."\",
                extract('month' from to_timestamp(result_f2.pivot[3])::date) AS \"".lang("focus2_month")."\",
                extract('day' from to_timestamp(result_f2.pivot[3])::date) AS \"".lang("focus2_day")."\",
                regions.name AS \"".lang("focus2_udeveg")."\",
                fields.group_name AS \"".lang("focus2_group_name")."\",
                rf1.farm_name AS \"".lang("focus2_farm_name")."\",
                rf1.field_name AS \"".lang("focus2_field_name")."\",
                st_area(fields.the_geom::geography)/10000 AS \"".lang("focus2_field_area")."\",
                rf1.latitud AS \"".lang("focus2_lat")."\",
                rf1.longitud AS \"".lang("focus2_lon")."\",
                rf1.pixel_id AS \"".lang("focus2_pixel_id")."\",
                rf1.intersect_idx AS \"".lang("focus2_intersect_idx")."\",
                rf1.use_concrete_name AS \"".lang("focus2_use_concrete_name")."\",
                rf1.uses_date_from AS \"".lang("focus2_uses_date_from")."\",
                rf1.uses_date_to AS \"".lang("focus2_uses_date_to")."\",
                rf1.the_geom,
                ".join(', ', $keys_columns)." FROM (
                    SELECT *
                    FROM crosstab($$
                            SELECT ARRAY[process_result_id, process_focus_id, EXTRACT('epoch' from date::timestamptz)], LOWER(key)::text,value::text
                            FROM   results_f2
                            WHERE process_focus_id = $process_id
                            ORDER  BY 1,2
                         $$,
                         $$
                            VALUES ('".join("'), ('", $keys)."')
                         $$
                    )
                    AS crosstabtable_f1 (pivot int[], \"".join('" text, "', $keys)."\" text)
                ) result_f2
                JOIN result_focus1 rf1 ON rf1.result_id = result_f2.pivot[1]
                    AND COALESCE(EXTRACT('epoch' from field_date_from) <= result_f2.pivot[3], TRUE)
                    AND COALESCE(EXTRACT('epoch' from field_date_to) >= result_f2.pivot[3], TRUE)
                    AND COALESCE(EXTRACT('epoch' from uses_date_from) <= result_f2.pivot[3], TRUE)
                    AND COALESCE(EXTRACT('epoch' from uses_date_to) >= result_f2.pivot[3], TRUE)
                JOIN process_functions ON process_functions.id = result_f2.pivot[2]
                LEFT JOIN regions ON regions.map_id = process_functions.map_id 
                      AND regions.the_geom && rf1.the_geom 
                      AND ST_Intersects(ST_Centroid(rf1.the_geom), regions.the_geom)
                LEFT JOIN fields ON fields.id = rf1.field_id)");

        #Ejecutamos el comando pgsql2shp
        exec("pgsql2shp -u $dbusername -h $dbhost -P $dbpassword -p 5432 -f \"$path/$file_name\" $dbname $tmp_table", $output, $return);
        $CI->db->query("DROP TABLE $tmp_table;");

        #Retorno true o false y el error lo manejo en la view, para no pasar la salida standar de la terminal
        if ($return == 0) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * Metodo que devuelve el shp
     */
    public static function datatable_to_shp_field($process_id, $folder, $aggregates)
    {
        $CI = get_instance();
        $folder = trim($folder, '/');
        $keys = static::get_table_headers($process_id);
        set_time_limit(0);

        $output = array();
        $return = '';
        $file_name = $CI->user->name . uniqid('-');

        $extra_columns = array();
        $has_column = false;
        foreach ($aggregates as $key => $value) {
            if(in_array($key, $keys) && isset(static::$_aggregates[$value])) {
                if($value == 'weighted_avg')
                    $extra_columns[] = 'round('.static::$_aggregates[$value] . "(focus_GarbageToDouble(result_f2.\"$key\"), intersect_idx::double precision)::numeric,2) as \"$key\"";
                else if($value == 'string_agg')
                    $extra_columns[] = static::$_aggregates[$value] . "(round(focus_GarbageToDouble(result_f2.\"$key\")::numeric)::text, ', ') as \"$key\"";
                else if($value == 'min_string')
                    $extra_columns[] = 'round('.static::$_aggregates[$value] . "(result_f2.\"$key\")::numeric,2) as \"$key\"";
                else if($value == 'max_string')
                    $extra_columns[] = 'round('.static::$_aggregates[$value] . "(result_f2.\"$key\")::numeric,2) as \"$key\"";
                else if($value == 'min_number')
                    $extra_columns[] = 'round('.static::$_aggregates[$value] . "(focus_GarbageToDouble(result_f2.\"$key\"))::numeric,2) as \"$key\"";
                else if($value == 'max_number')
                    $extra_columns[] = 'round('.static::$_aggregates[$value] . "(focus_GarbageToDouble(result_f2.\"$key\"))::numeric,2) as \"$key\"";
                else
                    $extra_columns[] = 'round('.static::$_aggregates[$value] . "(focus_GarbageToDouble(result_f2.\"$key\"))::numeric,2) as \"$key\"";

                $has_column = true;
            }
        }

        #Traemos los datos del archivo Config y Database para correr el proceso en el pgsql2shp
        $path = $CI->config->item('upload_path') . $folder;
        $dbname = $CI->db->database;
        $dbusername = $CI->db->username;
        $dbpassword = $CI->db->password;
        $dbhost = $CI->db->hostname;

        $tmp_table = "tmp.f2_" . bin2hex(random_bytes(5));
        $CI->db->query(" CREATE TABLE $tmp_table AS (
            SELECT
                extract('year' from to_timestamp(result_f2.pivot[3])::date) AS \"".lang("focus2_year")."\",
                extract('month' from to_timestamp(result_f2.pivot[3])::date) AS \"".lang("focus2_month")."\",
                extract('day' from to_timestamp(result_f2.pivot[3])::date) AS \"".lang("focus2_day")."\",
                regions.name AS \"".lang("focus2_udeveg")."\",
                min(fields.group_name) AS \"".lang("focus2_group_name")."\",
                min(rf1.farm_name) AS \"".lang("focus2_farm_name")."\",
                min(rf1.field_name) AS \"".lang("focus2_field_name")."\",
                st_area(fields.the_geom::geography)/10000 AS \"".lang("focus2_field_area")."\",
                st_x(st_centroid(fields.the_geom)) AS \"".lang("focus2_lon")."\",
                st_y(st_centroid(fields.the_geom)) AS \"".lang("focus2_lat")."\",
                count(*) AS \"".lang("focus2_data_count")."\",
                rf1.use_concrete_name AS \"".lang("focus2_use_concrete_name")."\",
                rf1.uses_date_from AS \"".lang("focus2_uses_date_from")."\",
                rf1.uses_date_to AS \"".lang("focus2_uses_date_to")."\",
                st_union(pixel.the_geom) as the_geom
                ".($has_column?', ':'').join(', ', $extra_columns)."
                FROM (
                    SELECT *
                    FROM crosstab($$
                            SELECT ARRAY[process_result_id, process_focus_id, EXTRACT('epoch' from date::timestamptz)], lower(key)::text,value::text
                            FROM results_f2
                            WHERE process_focus_id = $process_id
                            ORDER BY 1,2
                         $$,
                         $$
                            VALUES ('".join("'), ('", $keys)."')
                         $$)
                    AS crosstabtable_f1 (pivot int[], \"".join('" text, "', $keys)."\" text)
                ) result_f2
                join result_focus1 rf1 ON rf1.result_id = result_f2.pivot[1]
                  AND COALESCE(EXTRACT('epoch' from field_date_from) <= result_f2.pivot[3], TRUE)
                  AND COALESCE(EXTRACT('epoch' from field_date_to) >= result_f2.pivot[3], TRUE)
                  AND COALESCE(EXTRACT('epoch' from uses_date_from) <= result_f2.pivot[3], TRUE)
                  AND COALESCE(EXTRACT('epoch' from uses_date_to) >= result_f2.pivot[3], TRUE)
                join process_functions on process_functions.id = result_f2.pivot[2]
                left join regions ON regions.map_id = process_functions.map_id
                      AND regions.the_geom && rf1.the_geom
                      AND st_intersects(st_centroid(rf1.the_geom), regions.the_geom)
                left join fields on fields.id = rf1.field_id
                group by rf1.field_id, fields.id, process_functions.id, regions.id, to_timestamp(result_f2.pivot[3])::date, rf1.use_concrete_name, rf1.uses_date_from, rf1.uses_date_to
        )");

        #Ejecutamos el comando pgsql2shp
        exec("pgsql2shp -u $dbusername -h $dbhost -P $dbpassword -p 5432 -f \"$path/$file_name\" $dbname $tmp_table",$output,$return);
        $CI->db->query("DROP TABLE $tmp_table;");

        #Retorno true o false y el error lo manejo en la view, para no pasar la salida standar de la terminal
        if ($return == 0) {
            return true;
        } else
            return false;
    }

    /**
     * Metodo que devuelve el shp
     */
    public static function datatable_to_shp_month($process_id, $folder)
    {
        $CI = get_instance();
        $folder = trim($folder, '/');
        $keys = static::get_table_headers($process_id);
        set_time_limit(0);

        $output = array();
        $return = '';
        $file_name = $CI->user->name . uniqid('-');

        #Traemos los datos del archivo Config y Database para correr el proceso en el pgsql2shp
        $path = $CI->config->item('upload_path') . $folder;
        $dbname = $CI->db->database;
        $dbusername = $CI->db->username;
        $dbpassword = $CI->db->password;
        $dbhost = $CI->db->hostname;

        $str_keys = $str_keys2 = $str_keys3 = $str_keys4 = array();
        foreach ($keys as $key) {
            $str_keys[] = "result_f2.\"$key\"";
            $str_keys2[] = "('$key')";
            $str_keys3[] = "\"$key\" text";
            $str_keys4[] = "round((CASE WHEN sum(CASE WHEN focus_GarbageToDouble(\"$key\") IS NOT NULL THEN intersect_idx * extract_days((daterange(datadate,lead_date,'[)') * monthrange)::daterange) / months_data.days ELSE 0 END) != 0 THEN sum(CASE WHEN focus_GarbageToDouble(\"$key\") IS NOT NULL THEN extract_days((daterange(datadate,lead_date,'[)') * monthrange)::daterange) / months_data.days * focus_GarbageToDouble(\"$key\") * intersect_idx ELSE 0 END) / sum(CASE WHEN focus_GarbageToDouble(\"$key\") IS NOT NULL THEN intersect_idx * extract_days((daterange(datadate,lead_date,'[)') * monthrange)::daterange) / months_data.days ELSE 0 END) ELSE null END)::numeric, 2) as \"$key\"";
        }
        $str_keys  = join(', ', $str_keys);
        $str_keys2 = join(', ', $str_keys2);
        $str_keys3 = join(', ', $str_keys3);
        $str_keys4 = join(', ', $str_keys4);

        $tmp_table = "tmp.f2_" . bin2hex(random_bytes(5));

        $CI->db->query(" CREATE TABLE $tmp_table AS (
            WITH data as (
                SELECT
                    rf1.the_geom,
                    datapixel_id,
                    to_timestamp(result_f2.pivot[3])::datadate as datadate,
                    lead(to_timestamp(result_f2.pivot[3])::date) OVER (w) as lead_date,
                    extract('year' from to_timestamp(result_f2.pivot[3])::date) as year,
                    extract('month' from to_timestamp(result_f2.pivot[3])::date) as month,
                    extract('day' from to_timestamp(result_f2.pivot[3])::date) as day,
                    regions.name as udeveg,
                    rf1.latitud,
                    rf1.longitud,
                    rf1.intersect_idx,
                    fields.group_name,
                    rf1.field_name,
                    rf1.field_date_from,
                    rf1.field_date_to,
                    rf1.farm_name,
                    rf1.use_concrete_name,
                    rf1.uses_date_from,
                    rf1.uses_date_to,
                    ''::text as admin,
                    st_area(fields.the_geom::geography)/10000 as field_area,
                    $str_keys
                FROM (
                    SELECT *
                    FROM crosstab(\$\$
                        SELECT ARRAY[process_result_id, process_focus_id, EXTRACT('epoch' from date::timestamptz)], LOWER(key)::text,value::text
                        FROM results_f2
                        WHERE process_focus_id = $process_id
                        ORDER BY 1,2
                    \$\$,\$\$
                        VALUES $str_keys2
                    \$\$) AS crosstabtable_f1 (pivot int[], $str_keys3)
                ) result_f2
                JOIN result_focus1 rf1 ON rf1.result_id = result_f2.pivot[1]
                 AND COALESCE(EXTRACT('epoch' from field_date_from) <= result_f2.pivot[3], TRUE)
                 AND COALESCE(EXTRACT('epoch' from field_date_to)   >= result_f2.pivot[3], TRUE)
                 AND COALESCE(EXTRACT('epoch' from uses_date_from)  <= result_f2.pivot[3], TRUE)
                 AND COALESCE(EXTRACT('epoch' from uses_date_to)    >= result_f2.pivot[3], TRUE)
                JOIN process_functions ON process_functions.id = result_f2.pivot[2]
                LEFT JOIN regions ON regions.map_id = process_functions.map_id 
                 AND regions.the_geom && rf1.the_geom 
                 AND ST_Intersects(ST_Centroid(rf1.the_geom), regions.the_geom)
                LEFT JOIN fields ON fields.id = rf1.field_id
                WINDOW w AS (PARTITION BY rf1.pixel_id order by result_f2.pivot[3])
            ), months as (
                /* Obtengo los meses representados en los datos */
                SELECT DISTINCT ON (to_char(datadate, 'YYYY-MM'))
                    to_char(datadate, 'YYYY-MM') as month,
                    datadate as months_date,
                    (to_char(datadate, 'YYYY-MM') || '-01')::date as monthstart,
                    DATE_PART('days', DATE_TRUNC('month', (to_char(datadate, 'YYYY-MM') || '-01')::date) + '1 MONTH'::INTERVAL - '1 DAY'::INTERVAL) monthdays
                FROM data
            ), months_data as (
                SELECT
                    months.month, months_date,
                    DATE_PART('days', DATE_TRUNC('month', monthstart) + '1 MONTH'::INTERVAL - '1 DAY'::INTERVAL) as days,
                    DATERANGE(monthstart, (months.month || '-' || monthdays)::date, '[]') as monthrange
                FROM months
            )
            SELECT
                data.the_geom,
                extract('year' from months_data.months_date) AS \"".lang("focus2_year")."\",
                extract('month' from months_data.months_date) AS \"".lang("focus2_month")."\",
                data.udeveg AS \"".lang("focus2_udeveg")."\",
                data.group_name AS \"".lang("focus2_group_name")."\",
                data.farm_name AS \"".lang("focus2_farm_name")."\",
                data.field_name AS \"".lang("focus2_field_name")."\",
                data.latitud AS \"".lang("focus2_lat")."\",
                data.longitud AS \"".lang("focus2_lon")."\",
                datapixel_id AS \"".lang("focus2_pixel_id")."\",
                intersect_idx AS \"".lang("focus2_intersect_idx")."\",
                data.use_concrete_name AS \"".lang("focus2_use_concrete_name")."\",
                data.uses_date_from AS \"".lang("focus2_uses_date_from")."\",
                data.uses_date_to AS \"".lang("focus2_uses_date_to")."\",

                /*string_agg(to_char(data.date, 'YYYY-MM-DD') || ' (' || extract_days((daterange(datadate,lead_date,'[)') * monthrange)::daterange) / months_data.days || ')', ', '),*/
                /*count(*),*/
                /*sum(extract_days((daterange(datadate,lead_date,'[)') * monthrange)::daterange) / months_data.days) fill_idx,*/
                $str_keys4
            FROM months_data
            JOIN data ON not isempty(daterange(datadate,lead_date,'[)') * monthrange)
            GROUP BY months_data.months_date, months_data.month, datapixel_id, data.the_geom, latitud, longitud, udeveg, intersect_idx, 
                     data.group_name, data.farm_name, data.field_name, data.use_concrete_name, data.uses_date_from, data.uses_date_to
            ORDER BY months_data.months_date, months_data.month, datapixel_id, data.the_geom, latitud, longitud, udeveg, intersect_idx, 
                     data.group_name, data.farm_name, data.field_name, data.use_concrete_name, data.uses_date_from, data.uses_date_to
        )");

        exec("pgsql2shp -u $dbusername -h $dbhost -P $dbpassword -p 5432 -f \"$path/$file_name\" $dbname $tmp_table", $output, $return);
        $CI->db->query("DROP TABLE $tmp_table;");

        if ($return == 0) {
            return true;
        } else
            return false;
    }

    /**
     * Metodo que devuelve el shp
     */
    public static function datatable_to_shp_month_field($process_id, $folder)
    {
        $CI = get_instance();
        $folder = trim($folder, '/');
        $keys = static::get_table_headers($process_id);
        set_time_limit(0);

        $output = array();
        $return = '';
        $file_name = $CI->user->name . uniqid('-');

        #Traemos los datos del archivo Config y Database para correr el proceso en el pgsql2shp
        $path = $CI->config->item('upload_path') . $folder;
        $dbname = $CI->db->database;
        $dbusername = $CI->db->username;
        $dbpassword = $CI->db->password;
        $dbhost = $CI->db->hostname;

        $str_keys = $str_keys2 = $str_keys3 = $str_keys4 = array();
        foreach ($keys as $key) {
            $str_keys[] = "\"$key\"";
            $str_keys2[] = "('$key')";
            $str_keys3[] = "\"$key\" text";
            $str_keys4[] = "round((CASE WHEN sum(CASE WHEN focus_GarbageToDouble(\"$key\") IS NOT NULL THEN intersect_idx * extract_days((daterange(datadate,lead_date,'[)') * monthrange)::daterange) / months_data.days ELSE 0 END) != 0 THEN sum(CASE WHEN focus_GarbageToDouble(\"$key\") IS NOT NULL THEN extract_days((daterange(datadate,lead_date,'[)') * monthrange)::daterange) / months_data.days * focus_GarbageToDouble(\"$key\") * intersect_idx ELSE 0 END) / sum(CASE WHEN focus_GarbageToDouble(\"$key\") IS NOT NULL THEN intersect_idx * extract_days((daterange(datadate,lead_date,'[)') * monthrange)::daterange) / months_data.days ELSE 0 END)  ELSE null END)::numeric, 2) as \"$key\"";
        }
        $str_keys  = join(', ', $str_keys);
        $str_keys2 = join(', ', $str_keys2);
        $str_keys3 = join(', ', $str_keys3);
        $str_keys4 = join(', ', $str_keys4);

        $tmp_table = "tmp.f2_" . bin2hex(random_bytes(5));

        $CI->db->query(" CREATE TABLE $tmp_table AS (
            WITH data as (
                SELECT
                    rf1.the_geom,
                    to_timestamp(result_f2.pivot[3])::date as datadate,
                    lead(to_timestamp(result_f2.pivot[3])::date) OVER (w) as lead_date,
                    extract('year' from to_timestamp(result_f2.pivot[3])::date) as year,
                    extract('month' from to_timestamp(result_f2.pivot[3])::date) as month,
                    extract('day' from to_timestamp(result_f2.pivot[3])::date) as day,
                    regions.name as udeveg,
                    st_x(st_centroid(fields.the_geom)) as lon,
                    st_y(st_centroid(fields.the_geom)) as lat,
                    rf1.intersect_idx,
                    rf1.pixel_id rf1_pixel_id,
                    fields.group_name,
                    rf1.field_name,
                    rf1.field_date_from,
                    rf1.field_date_to,
                    rf1.farm_name,
                    rf1.use_concrete_name,
                    rf1.uses_date_from,
                    rf1.uses_date_to,
                    ''::text as admin,
                    st_area(fields.the_geom::geography)/10000 as field_area,
                    $str_keys
                FROM (
                    SELECT *
                    FROM crosstab(\$\$
                        SELECT ARRAY[process_result_id, process_focus_id, EXTRACT('epoch' from date::timestamptz)], lower(key)::text,value::text
                        FROM results_f2
                        WHERE process_focus_id = $process_id
                        ORDER BY 1,2
                    \$\$,\$\$
                        VALUES $str_keys2
                    \$\$) AS crosstabtable_f1 (pivot int[], $str_keys3)
                ) result_f2
                JOIN result_focus1 rf1 ON rf1.result_id = result_f2.pivot[1]
                 AND COALESCE(EXTRACT('epoch' from field_date_from) <= result_f2.pivot[3], TRUE)
                 AND COALESCE(EXTRACT('epoch' from field_date_to)   >= result_f2.pivot[3], TRUE)
                 AND COALESCE(EXTRACT('epoch' from uses_date_from)  <= result_f2.pivot[3], TRUE)
                 AND COALESCE(EXTRACT('epoch' from uses_date_to)    >= result_f2.pivot[3], TRUE)
                JOIN process_functions ON process_functions.id = result_f2.pivot[2]
                LEFT JOIN regions ON regions.map_id = process_functions.map_id 
                 AND regions.the_geom && rf1.the_geom 
                 AND ST_Intersects(ST_Centroid(rf1.the_geom), regions.the_geom)
                LEFT JOIN fields ON fields.id = rf1.field_id
                WINDOW w AS (PARTITION BY rf1.pixel_id order by result_f2.pivot[3])
            ), months as (
                /* Obtengo los meses representados en los datos */
                SELECT DISTINCT ON (to_char(datadate, 'YYYY-MM'))
                    to_char(datadate, 'YYYY-MM') as month,
                    datadate as months_date,
                    (to_char(datadate, 'YYYY-MM') || '-01')::date as monthstart,
                    DATE_PART('days', DATE_TRUNC('month', (to_char(datadate, 'YYYY-MM') || '-01')::date) + '1 MONTH'::INTERVAL - '1 DAY'::INTERVAL) monthdays
                FROM data
            ), months_data as (
                SELECT
                    months.month, months_date,
                    DATE_PART('days', DATE_TRUNC('month', monthstart) + '1 MONTH'::INTERVAL - '1 DAY'::INTERVAL) as days,
                    DATERANGE(monthstart, (months.month || '-' || monthdays)::date, '[]') as monthrange
                FROM months
            )
            SELECT
                extract('year' from months_data.months_date) as \"".lang("focus2_year")."\",
                extract('month' from months_data.months_date) as \"".lang("focus2_month")."\",
                data.udeveg as \"".lang("focus2_udeveg")."\",
                data.group_name as \"".lang("focus2_group_name")."\",
                data.farm_name as \"".lang("focus2_farm_name")."\",
                data.field_name as \"".lang("focus2_field_name")."\",
                field_area as \"".lang("focus2_field_area")."\",
                data.lat as \"".lang("focus2_lat")."\",
                data.lon as \"".lang("focus2_lon")."\",
                count(DISTINCT rf1_pixel_id) as \"".lang("focus2_data_count")."\",
                data.use_concrete_name as \"".lang("focus2_use_concrete_name")."\",
                data.uses_date_from as \"".lang("focus2_uses_date_from")."\",
                data.uses_date_to as \"".lang("focus2_uses_date_to")."\",
                st_union(data.the_geom) as the_geom,

                /*string_agg(to_char(data.date, 'YYYY-MM-DD') || ' (' || extract_days((daterange(datadate,lead_date,'[)') * monthrange)::daterange) / months_data.days || ')', ', '),*/
                /*count(*),*/
                /*sum(extract_days((daterange(datadate,lead_date,'[)') * monthrange)::daterange) / months_data.days) fill_idx,*/
                $str_keys4
            FROM months_data
            JOIN data ON not isempty(daterange(datadate,lead_date,'[)') * monthrange)

            WHERE COALESCE(to_char(field_date_from, 'YYYY-MM') <= months_data.month, TRUE)
              AND COALESCE(to_char(field_date_to, 'YYYY-MM')   >= months_data.month, TRUE)
              AND COALESCE(to_char(uses_date_from, 'YYYY-MM')  <= months_data.month, TRUE)
              AND COALESCE(to_char(uses_date_to, 'YYYY-MM')    >= months_data.month, TRUE)

            GROUP BY months_data.months_date, months_data.month, udeveg, lat, lon, group_name, field_name, field_date_from, field_date_to, farm_name, field_area, use_concrete_name, uses_date_from, uses_date_to, admin
            ORDER BY months_data.months_date, months_data.month, udeveg, lat, lon, group_name, field_name, field_date_from, field_date_to, farm_name, field_area, use_concrete_name, uses_date_from, uses_date_to, admin
        )");

        exec("pgsql2shp -u $dbusername -h $dbhost -P $dbpassword -p 5432 -f \"$path/$file_name\" $dbname $tmp_table", $output, $return);
        $CI->db->query("DROP TABLE $tmp_table;");

        if ($return == 0) {
            return true;
        } else
            return false;
    }



    /**
     * Metodo que devuelve el csv
     *
     *
     */
    public static function datatable_to_csv($process_id, $tmpname)
    {
        set_time_limit(0);
        $CI = get_instance();
        $keys = static::get_table_headers($process_id);

        if(empty($keys)) return array(array(),array());

        $keys_columns = array();
        foreach ($keys as $value) {
            $keys_columns[] = "round(focus_GarbageToDouble(result_f2.\"$value\")::numeric, 2) as \"$value\"";
        }

        $quer_middle =  '
        SELECT
            extract(\'year\' from to_timestamp(result_f2.pivot[3])::date) AS "'.lang("focus2_year").'",
            extract(\'month\' from to_timestamp(result_f2.pivot[3])::date) AS "'.lang("focus2_month").'",
            extract(\'day\' from to_timestamp(result_f2.pivot[3])::date) AS "'.lang("focus2_day").'",
            regions.name AS "'.lang("focus2_udeveg").'",
            fields.group_name AS "'.lang("focus2_group_name").'",
            rf1.farm_name AS "'.lang("focus2_farm_name").'",
            rf1.field_name AS "'.lang("focus2_field_name").'",
            st_area(fields.the_geom::geography)/10000 AS "'.lang("focus2_field_area").'",
            rf1.latitud AS "'.lang("focus2_lat").'",
            rf1.longitud AS "'.lang("focus2_lon").'",
            rf1.pixel_id AS "'.lang("focus2_pixel_id").'",
            rf1.intersect_idx AS "'.lang("focus2_intersect_idx").'",
            rf1.use_concrete_name AS "'.lang("focus2_use_concrete_name").'",
            rf1.uses_date_from AS "'.lang("focus2_uses_date_from").'",
            rf1.uses_date_to AS "'.lang("focus2_uses_date_to").'",
            '.join(', ', $keys_columns).'
        FROM (
            SELECT *
            FROM crosstab($$
                SELECT ARRAY[process_result_id, process_focus_id, EXTRACT(\'epoch\' from date::timestamptz)], LOWER(key)::text,value::text
                FROM results_f2
                WHERE process_focus_id = '.$process_id.'
                ORDER BY 1,2
            $$,$$
                VALUES (\''.join('\'), (\'', $keys).'\')
            $$) AS crosstabtable_f1 (pivot int[], "'.join('" text, "', $keys).'" text)
        ) result_f2
        JOIN result_focus1 rf1 ON rf1.result_id = result_f2.pivot[1]
         AND COALESCE(EXTRACT(\'epoch\' from field_date_from) <= result_f2.pivot[3], TRUE)
         AND COALESCE(EXTRACT(\'epoch\' from field_date_to)   >= result_f2.pivot[3], TRUE)
         AND COALESCE(EXTRACT(\'epoch\' from uses_date_from)  <= result_f2.pivot[3], TRUE)
         AND COALESCE(EXTRACT(\'epoch\' from uses_date_to)    >= result_f2.pivot[3], TRUE)
        JOIN process_functions ON process_functions.id = result_f2.pivot[2]
        LEFT JOIN regions ON regions.map_id = process_functions.map_id 
         AND regions.the_geom && rf1.the_geom 
         AND ST_Intersects(ST_Centroid(rf1.the_geom), regions.the_geom)
        LEFT JOIN fields ON fields.id = rf1.field_id
        ';

        $query = "SET TimeZone = 'UTC'; COPY ( ";
        $query_end = " ) TO PROGRAM ". "'gzip > $tmpname ; chmod a+rwx $tmpname ; ' WITH CSV HEADER;";
        $query = $CI->db->query($query.$quer_middle.$query_end);
    }

    /**
     * Metodo que devuelve el csv
     *
     *
     */
    public static function datatable_to_csv_field($process_id, $tmpname, $aggregates)
    {
        $CI = get_instance();
        $keys = static::get_table_headers($process_id);
        set_time_limit(0);

        $extra_columns = array();
        $has_column = false;
        foreach ($aggregates as $key => $value) {
            if(!is_numeric($key) && in_array($key, $keys) && isset(static::$_aggregates[$value])) {
                if($value == 'weighted_avg')
                    $extra_columns[] = 'round('.static::$_aggregates[$value] . "(focus_GarbageToDouble(result_f2.\"$key\"), intersect_idx::double precision)::numeric,2) as \"$key\"";
                else if($value == 'string_agg')
                    $extra_columns[] = static::$_aggregates[$value] . "(round(focus_GarbageToDouble(result_f2.\"$key\")::numeric, 2)::text, ', ') as \"$key\"";
                else if($value == 'min_string')
                    $extra_columns[] = 'round('.static::$_aggregates[$value] . "(result_f2.\"$key\")::numeric,2) as \"$key\"";
                else if($value == 'max_string')
                    $extra_columns[] = 'round('.static::$_aggregates[$value] . "(result_f2.\"$key\")::numeric,2) as \"$key\"";
                else if($value == 'min_number')
                    $extra_columns[] = 'round('.static::$_aggregates[$value] . "(focus_GarbageToDouble(result_f2.\"$key\"))::numeric,2) as \"$key\"";
                else if($value == 'max_number')
                    $extra_columns[] = 'round('.static::$_aggregates[$value] . "(focus_GarbageToDouble(result_f2.\"$key\"))::numeric,2) as \"$key\"";
                else
                    $extra_columns[] = 'round('.static::$_aggregates[$value] . "(focus_GarbageToDouble(result_f2.\"$key\"))::numeric,2) as \"$key\"";

                $has_column = true;
            }
        }

        if (!empty($keys) && !is_null($process_id) && $process_id != '') {
            // $qresult = $CI->db->query('SELECT lote, weighted_avg(valor_1::double precision, valor_2::double precision), avg(valor_2::int), string_agg(valor_3, \',\') FROM results_f1 rf1
            $quer_middle = 'SELECT
                extract(\'year\' from to_timestamp(result_f2.pivot[3])::date) AS "'.lang("focus2_year").'",
                extract(\'month\' from to_timestamp(result_f2.pivot[3])::date) AS "'.lang("focus2_month").'",
                extract(\'day\' from to_timestamp(result_f2.pivot[3])::date) AS "'.lang("focus2_day").'",
                regions.name AS "'.lang("focus2_udeveg").'",
                min(fields.group_name) AS "'.lang("focus2_group_name").'",
                min(rf1.farm_name) AS "'.lang("focus2_farm_name").'",
                min(rf1.field_name) AS "'.lang("focus2_field_name").'",
                st_area(fields.the_geom::geography)/10000 AS "'.lang("focus2_field_area").'",
                st_x(st_centroid(fields.the_geom)) AS "'.lang("focus2_lon").'",
                st_y(st_centroid(fields.the_geom)) AS "'.lang("focus2_lat").'",
                count(*) AS "'.lang("focus2_data_count").'",
                rf1.use_concrete_name AS "'.lang("focus2_use_concrete_name").'",
                rf1.uses_date_from AS "'.lang("focus2_uses_date_from").'",
                rf1.uses_date_to AS "'.lang("focus2_uses_date_to").'"
                '.($has_column?', ':'').join(', ', $extra_columns).' FROM (
                    SELECT *
                    FROM crosstab($$
                            SELECT ARRAY[process_result_id, process_focus_id, EXTRACT(\'epoch\' from date::timestamptz)], LOWER(key)::text,value::text
                            FROM   results_f2
                            WHERE process_focus_id = '.$process_id.'
                            ORDER  BY 1,2
                         $$,
                         $$
                            VALUES (\''.join('\'), (\'', $keys).'\')
                         $$)
                    AS crosstabtable_f1 (pivot int[], "'.join('" text, "', $keys).'" text)
                ) result_f2
                join result_focus1 rf1 ON rf1.result_id = result_f2.pivot[1]
                  AND COALESCE(EXTRACT(\'epoch\' from field_date_from) <= result_f2.pivot[3], TRUE)
                  AND COALESCE(EXTRACT(\'epoch\' from field_date_to) >= result_f2.pivot[3], TRUE)
                  AND COALESCE(EXTRACT(\'epoch\' from uses_date_from) <= result_f2.pivot[3], TRUE)
                  AND COALESCE(EXTRACT(\'epoch\' from uses_date_to) >= result_f2.pivot[3], TRUE)
                join process_functions on process_functions.id = result_f2.pivot[2]
                left join regions ON regions.map_id = process_functions.map_id
                      AND regions.the_geom && rf1.the_geom
                      AND st_intersects(st_centroid(rf1.the_geom), regions.the_geom)
                left join fields on fields.id = rf1.field_id
                group by rf1.field_id, fields.id, process_functions.id, regions.id, to_timestamp(result_f2.pivot[3])::date, rf1.use_concrete_name, rf1.uses_date_from, rf1.uses_date_to ';

                $query = "SET TimeZone = 'UTC'; COPY ( ";
                $query_end = " ) TO PROGRAM ". "'gzip > $tmpname ; chmod a+rwx $tmpname ; ' WITH CSV HEADER;";

                $query = $CI->db->query($query.$quer_middle.$query_end);

        }
    }

    /**
     * Metodo que devuelve el csv
     *
     *
     */
    public static function datatable_to_csv_month($process_id, $tmpname)
    {
        $CI = get_instance();
        $keys = static::get_table_headers($process_id);
        set_time_limit(0);

        if (!empty($keys) && !is_null($process_id) && $process_id != '') {
            $str_keys = $str_keys2 = $str_keys3 = $str_keys4 = array();
            foreach ($keys as $key) {
                $str_keys[] = "result_f2.\"$key\"";
                $str_keys2[] = "('$key')";
                $str_keys3[] = "\"$key\" text";
                $str_keys4[] = "round((CASE WHEN sum(CASE WHEN focus_GarbageToDouble(\"$key\") IS NOT NULL THEN intersect_idx * extract_days((daterange(datadate,lead_date,'[)') * monthrange)::daterange) / months_data.days ELSE 0 END) != 0 THEN sum(CASE WHEN focus_GarbageToDouble(\"$key\") IS NOT NULL THEN extract_days((daterange(datadate,lead_date,'[)') * monthrange)::daterange) / months_data.days * focus_GarbageToDouble(\"$key\") * intersect_idx ELSE 0 END) / sum(CASE WHEN focus_GarbageToDouble(\"$key\") IS NOT NULL THEN intersect_idx * extract_days((daterange(datadate,lead_date,'[)') * monthrange)::daterange) / months_data.days ELSE 0 END) ELSE null END)::numeric, 2) as \"$key\"";
            }
            $str_keys = join(', ', $str_keys);
            $str_keys2 = join(', ', $str_keys2);
            $str_keys3 = join(', ', $str_keys3);
            $str_keys4 = join(', ', $str_keys4);

            $quer_middle = "
                WITH data as (
                    SELECT
                        rf1.pixel_id as datapixel_id,
                        to_timestamp(result_f2.pivot[3])::date as datadate,
                        lead(to_timestamp(result_f2.pivot[3])::date) OVER (w) as lead_date,
                        extract('year' from to_timestamp(result_f2.pivot[3])::date) as year,
                        extract('month' from to_timestamp(result_f2.pivot[3])::date) as month,
                        extract('day' from to_timestamp(result_f2.pivot[3])::date) as day,
                        regions.name as udeveg,
                        rf1.latitud,
                        rf1.longitud,
                        rf1.intersect_idx,
                        fields.group_name,
                        rf1.field_name,
                        rf1.field_date_from,
                        rf1.field_date_to,
                        rf1.farm_name,
                        rf1.use_concrete_name,
                        rf1.uses_date_from,
                        rf1.uses_date_to,
                        ''::text as admin,
                        st_area(fields.the_geom::geography)/10000 as field_area,
                        $str_keys
                    FROM (
                        SELECT *
                        FROM crosstab($$
                            SELECT ARRAY[process_result_id, process_focus_id, EXTRACT('epoch' from date::timestamptz)], LOWER(key)::text,value::text
                            FROM results_f2
                            WHERE process_focus_id = $process_id
                            ORDER BY 1,2
                        $$,$$
                            VALUES $str_keys2
                        $$) AS crosstabtable_f1 (pivot int[], $str_keys3)
                    ) result_f2
                    JOIN result_focus1 rf1 ON rf1.result_id = result_f2.pivot[1]
                     AND COALESCE(EXTRACT('epoch' from field_date_from) <= result_f2.pivot[3], TRUE)
                     AND COALESCE(EXTRACT('epoch' from field_date_to)   >= result_f2.pivot[3], TRUE)
                     AND COALESCE(EXTRACT('epoch' from uses_date_from)  <= result_f2.pivot[3], TRUE)
                     AND COALESCE(EXTRACT('epoch' from uses_date_to)    >= result_f2.pivot[3], TRUE)
                    JOIN process_functions ON process_functions.id = result_f2.pivot[2]
                    LEFT JOIN regions ON regions.map_id = process_functions.map_id 
                     AND regions.the_geom && rf1.the_geom 
                     AND ST_Intersects(ST_Centroid(rf1.the_geom), regions.the_geom)
                    LEFT JOIN fields ON fields.id = rf1.field_id
                    WINDOW w AS (PARTITION BY rf1.pixel_id order by result_f2.pivot[3])
                ), months as (
                    -- Obtengo los meses representados en lso datos
                    SELECT DISTINCT ON (to_char(datadate, 'YYYY-MM'))
                        to_char(datadate, 'YYYY-MM') as month,
                        datadate as months_date,
                        (to_char(datadate, 'YYYY-MM') || '-01')::date as monthstart,
                        DATE_PART('days', DATE_TRUNC('month', (to_char(datadate, 'YYYY-MM') || '-01')::date) + '1 MONTH'::INTERVAL - '1 DAY'::INTERVAL) monthdays
                    FROM data
                ), months_data as (
                    SELECT
                        months.month, months_date,
                        DATE_PART('days', DATE_TRUNC('month', monthstart) + '1 MONTH'::INTERVAL - '1 DAY'::INTERVAL) as days,
                        DATERANGE(monthstart, (months.month || '-' || monthdays)::date, '[]') as monthrange
                    FROM months
                )
                SELECT
                    extract('year' from months_data.months_date) AS \"".lang("focus2_year")."\",
                    extract('month' from months_data.months_date) AS \"".lang("focus2_month")."\",
                    data.udeveg AS \"".lang("focus2_udeveg")."\",
                    group_name AS \"".lang("focus2_group_name")."\",
                    farm_name AS \"".lang("focus2_farm_name")."\",
                    field_name AS \"".lang("focus2_field_name")."\",
                    data.latitud AS \"".lang("focus2_lat")."\",
                    data.longitud AS \"".lang("focus2_lon")."\",
                    datapixel_id AS \"".lang("focus2_pixel_id")."\",
                    intersect_idx AS \"".lang("focus2_intersect_idx")."\",
                    use_concrete_name AS \"".lang("focus2_use_concrete_name")."\",
                    uses_date_from AS \"".lang("focus2_uses_date_from")."\",
                    uses_date_to AS \"".lang("focus2_uses_date_to")."\",
                    /*string_agg(to_char(data.date, 'YYYY-MM-DD') || ' (' || extract_days((daterange(datadate,lead_date,'[)') * monthrange)::daterange) / months_data.days || ')', ', '),*/
                    /*count(*),*/
                    /*sum(extract_days((daterange(datadate,lead_date,'[)') * monthrange)::daterange) / months_data.days) fill_idx,*/
                    $str_keys4
                FROM months_data
                JOIN data ON not isempty(daterange(datadate,lead_date,'[)') * monthrange)
                GROUP BY months_data.months_date, months_data.month, datapixel_id, latitud, longitud, udeveg, intersect_idx, group_name, farm_name, field_name, use_concrete_name, uses_date_from, uses_date_to
                ORDER BY months_data.months_date, months_data.month, datapixel_id, latitud, longitud, udeveg, intersect_idx, group_name, farm_name, field_name, use_concrete_name, uses_date_from, uses_date_to
            ";

            $query = "SET TimeZone = 'UTC'; COPY ( ";
            $query_end = " ) TO PROGRAM ". "'gzip > $tmpname ; chmod a+rwx $tmpname ; ' WITH CSV HEADER;";
            $query = $CI->db->query($query.$quer_middle.$query_end);

        }
    }

    /**
     * Metodo que devuelve el csv
     *
     *
     */
    public static function datatable_to_csv_month_field($process_id, $tmpname)
    {
        $CI = get_instance();
        $keys = static::get_table_headers($process_id);
        set_time_limit(0);

        if (!empty($keys) && !is_null($process_id) && $process_id != '') {
            $str_keys = $str_keys2 = $str_keys3 = $str_keys4 = array();
            foreach ($keys as $key) {
                $str_keys[] = "result_f2.\"$key\"";
                $str_keys2[] = "('$key')";
                $str_keys3[] = "\"$key\" text";
                $str_keys4[] = "round((CASE WHEN sum(CASE WHEN focus_GarbageToDouble(\"$key\") IS NOT NULL THEN intersect_idx * extract_days((daterange(datadate,lead_date,'[)') * monthrange)::daterange) / months_data.days ELSE 0 END) != 0 THEN sum(CASE WHEN focus_GarbageToDouble(\"$key\") IS NOT NULL THEN extract_days((daterange(datadate,lead_date,'[)') * monthrange)::daterange) / months_data.days * focus_GarbageToDouble(\"$key\") * intersect_idx ELSE 0 END) / sum(CASE WHEN focus_GarbageToDouble(\"$key\") IS NOT NULL THEN intersect_idx * extract_days((daterange(datadate,lead_date,'[)') * monthrange)::daterange) / months_data.days ELSE 0 END) ELSE null END)::numeric, 2) as \"$key\"";
            }
            $str_keys = join(', ', $str_keys);
            $str_keys2 = join(', ', $str_keys2);
            $str_keys3 = join(', ', $str_keys3);
            $str_keys4 = join(', ', $str_keys4);

            $quer_middle = "
                WITH data as (
                    SELECT
                        to_timestamp(result_f2.pivot[3])::date as datadate,
                        lead(to_timestamp(result_f2.pivot[3])::date) OVER (w) as lead_date,
                        extract('year' from to_timestamp(result_f2.pivot[3])::date) as year,
                        extract('month' from to_timestamp(result_f2.pivot[3])::date) as month,
                        extract('day' from to_timestamp(result_f2.pivot[3])::date) as day,
                        st_x(st_centroid(fields.the_geom)) as lon,
                        st_y(st_centroid(fields.the_geom)) as lat,
                        regions.name as udeveg,
                        latitud,
                        longitud,
                        intersect_idx,
                        rf1.pixel_id rf1_pixel_id,
                        group_name,
                        field_name,
                        field_date_from,
                        field_date_to,
                        farm_name,
                        use_concrete_name,
                        uses_date_from,
                        uses_date_to,
                        ''::text as admin,
                        st_area(fields.the_geom::geography)/10000 as field_area,
                        $str_keys
                    FROM (
                        SELECT *
                        FROM crosstab($$
                            SELECT ARRAY[process_result_id, process_focus_id, EXTRACT('epoch' from date::timestamptz)], lower(key)::text,value::text
                            FROM results_f2
                            WHERE process_focus_id = $process_id
                            ORDER BY 1,2
                        $$,$$
                            VALUES $str_keys2
                        $$) AS crosstabtable_f1 (pivot int[], $str_keys3)
                    ) result_f2
                    JOIN result_focus1 rf1 ON rf1.result_id = result_f2.pivot[1]
                     AND COALESCE(EXTRACT('epoch' from field_date_from) <= result_f2.pivot[3], TRUE)
                     AND COALESCE(EXTRACT('epoch' from field_date_to)   >= result_f2.pivot[3], TRUE)
                     AND COALESCE(EXTRACT('epoch' from uses_date_from)  <= result_f2.pivot[3], TRUE)
                     AND COALESCE(EXTRACT('epoch' from uses_date_to)    >= result_f2.pivot[3], TRUE)
                    JOIN process_functions ON process_functions.id = result_f2.pivot[2]
                    LEFT JOIN regions ON regions.map_id = process_functions.map_id 
                     AND regions.the_geom && rf1.the_geom 
                     AND ST_Intersects(ST_Centroid(rf1.the_geom), regions.the_geom)
                    LEFT JOIN fields ON fields.id = rf1.field_id
                    WINDOW w AS (PARTITION BY rf1.pixel_id order by result_f2.pivot[3])
                ), months as (
                    -- Obtengo los meses representados en lso datos
                    SELECT DISTINCT ON (to_char(datadate, 'YYYY-MM'))
                        to_char(datadate, 'YYYY-MM') as month,
                        datadate as months_date,
                        (to_char(datadate, 'YYYY-MM') || '-01')::date as monthstart,
                        DATE_PART('days', DATE_TRUNC('month', (to_char(datadate, 'YYYY-MM') || '-01')::date) + '1 MONTH'::INTERVAL - '1 DAY'::INTERVAL) monthdays
                    FROM data
                ), months_data as (
                    SELECT
                        months.month, months_date,
                        DATE_PART('days', DATE_TRUNC('month', monthstart) + '1 MONTH'::INTERVAL - '1 DAY'::INTERVAL) as days,
                        DATERANGE(monthstart, (months.month || '-' || monthdays)::date, '[]') as monthrange
                    FROM months
                )
                SELECT
                    extract('year' from months_data.months_date) as \"".lang("focus2_year")."\",
                    extract('month' from months_data.months_date) as \"".lang("focus2_month")."\",
                    data.udeveg as \"".lang("focus2_udeveg")."\",
                    group_name as \"".lang("focus2_group_name")."\",
                    farm_name as \"".lang("focus2_farm_name")."\",
                    field_name as \"".lang("focus2_field_name")."\",
                    field_area as \"".lang("focus2_field_area")."\",
                    data.lat as \"".lang("focus2_lat")."\",
                    data.lon as \"".lang("focus2_lon")."\",
                    count(DISTINCT rf1_pixel_id) as \"".lang("focus2_data_count")."\",
                    use_concrete_name as \"".lang("focus2_use_concrete_name")."\",
                    uses_date_from as \"".lang("focus2_uses_date_from")."\",
                    uses_date_to as \"".lang("focus2_uses_date_to")."\",

                    /*string_agg(to_char(data.date, 'YYYY-MM-DD') || ' (' || extract_days((daterange(datadate,lead_date,'[)') * monthrange)::daterange) / months_data.days || ')', ', '),*/
                    /*count(*),*/
                    /*sum(extract_days((daterange(datadate,lead_date,'[)') * monthrange)::daterange) / months_data.days) fill_idx,*/
                    $str_keys4
                FROM months_data
                JOIN data ON not isempty(daterange(datadate,lead_date,'[)') * monthrange)
                WHERE COALESCE(to_char(field_date_from, 'YYYY-MM') <= months_data.month, TRUE)
                  AND COALESCE(to_char(field_date_to, 'YYYY-MM')   >= months_data.month, TRUE)
                  AND COALESCE(to_char(uses_date_from, 'YYYY-MM')  <= months_data.month, TRUE)
                  AND COALESCE(to_char(uses_date_to, 'YYYY-MM')    >= months_data.month, TRUE)

                GROUP BY months_data.months_date, months_data.month, lat, lon, udeveg, field_name, field_date_from, field_date_to, group_name, farm_name, field_area, use_concrete_name, uses_date_from, uses_date_to, admin
                ORDER BY months_data.months_date, months_data.month, lat, lon, udeveg, field_name, field_date_from, field_date_to, group_name, farm_name, field_area, use_concrete_name, uses_date_from, uses_date_to, admin
            ";

            $query = "SET TimeZone = 'UTC'; COPY ( ";
            $query_end = " ) TO PROGRAM ". "'gzip > $tmpname ; chmod a+rwx $tmpname ; ' WITH CSV HEADER;";
            $query = $CI->db->query($query.$quer_middle.$query_end);

        }
    }

}
