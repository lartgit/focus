<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Clase para servir los datos de lso landing pages de los proyectos de R2
 *
 */
abstract class R2_Landing_Page extends CI_Model {

    // Construct
    public function __construct()
    {
        parent::__construct();
    }

    public static function get_index_data() {
        $CI = get_instance();

        $filter = "1=1";
        if($CI->user->primary_key_value() != -1) {
            $filter = "organization_id = " . $CI->user->organization_id;
        }

        $process_query = $CI->db->query("
            SELECT a.*, users.email
            FROM processes_vw a
            JOIN users ON users.id = a.user_id
            WHERE $filter
            ORDER BY a.created_at DESC
            LIMIT 10
        ");

        $size_query = $CI->db->query("SELECT sum(total_bytes) AS total, pg_size_pretty(sum(total_bytes)) AS total_pretty
          FROM (
          SELECT *, total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes FROM (
              SELECT c.oid,nspname AS table_schema, relname AS TABLE_NAME
                      , c.reltuples AS row_estimate
                      , pg_total_relation_size(c.oid) AS total_bytes
                      , pg_indexes_size(c.oid) AS index_bytes
                      , pg_total_relation_size(reltoastrelid) AS toast_bytes
                  FROM pg_class c
                  LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
                  WHERE relkind = 'r'
          ) a
        ) a");

        $last7_query = $CI->db->query("
            SELECT count(*) AS value FROM processes_vw a
            JOIN users ON users.id = a.user_id
            WHERE $filter AND end_process_at > (now()-'7 days'::interval)
        ");

        $last30_query = $CI->db->query("
            SELECT count(*) AS value FROM processes_vw a
            JOIN users ON users.id = a.user_id
            WHERE $filter AND end_process_at > (now()-'30 days'::interval)
        ");

        $last_images = $CI->db->query("
            SELECT it.id, it.name, it.pixel_size, max(image_date) AS last_image_date
            FROM imagen_types it
            LEFT JOIN layer_types lt ON lt.image_type_id = it.id
            LEFT JOIN raster_layers rl ON rl.layer_type_id = lt.id
            GROUP BY it.name, it.pixel_size, it.id
        ");

        return array(
            'process_table' => $process_query->result(),
            'images_table' => $last_images->result(),
            'db_size' => $size_query->result()[0],
            'last7_ammt' => $last7_query->result()[0],
            'last30_ammt' => $last30_query->result()[0]
        );
    }
}
