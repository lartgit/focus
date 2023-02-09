<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 * @author ABayerl
 * @package Focus
 */
class Raster_Layer extends R2_DbObject {

    /**  Variables Static de Configuración del Model */
    protected static $_table_name = 'raster_layers';
    protected static $_display_name = 'Capa de Raster';
    protected static $_plural_name = 'Capas de Raster';
    protected static $_display_column = 'id';

    /** Variables Públicas del Model */
    public $layer_type_id;
    public $raster_file_id;

    /** Construct */
    public function __construct() {
        parent::__construct();
    }

    public static function references_class() {
        return Array('layer_type_id' => 'Layer_type', 'raster_file_id' => 'Raster_file');
    }

    public function related_with(){
        return array();//Pixel_values::where(Array('parameter_type_id'=>$this->primary_key_value()));
    }

    public static function get_index_data($limit) {
        $CI=get_instance();

        if ($limit)
            $CI->db->limit($limit);

        $CI->db->select('raster_layers.*');
        $CI->db->select("regexp_replace(path, '^.+[/\\\\]', '') as raster_file_name");
        $CI->db->select("layer_types.name as layer_type_name");
        $CI->db->select("-1 as pixel_count", false);

        $CI->db->join('layer_types', 'layer_types.id = layer_type_id', 'LEFT');
        $CI->db->join('raster_files', 'raster_files.id = raster_file_id', 'LEFT');
//        $CI->db->join('(SELECT raster_layer_id, count (*) as pixel_count  FROM pixel_values GROUP BY raster_layer_id ) a', 'raster_layers.id = a.raster_layer_id', 'LEFT');
        
        $CI->db->order_by('raster_layers.ts', 'DESC');

        return $CI->db->get(static::$_table_name)->result(get_called_class());
    }
    
    public static function count_pixel_values($raster_layer_id){
        $CI=get_instance();
        
        $CI->db->select("COUNT(*)");
        $CI->db->where('raster_layer_id', $raster_layer_id);
        return $CI->db->get('pixel_values')->row()->count;
        
    }
}
