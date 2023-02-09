<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class Imagen_Type extends R2_DbObject {

    /**  Variables Static de Configuración del Model */
    protected static $_table_name = 'imagen_types';
    protected static $_display_name = 'Tipo_de_imagen / Producto';
    protected static $_plural_name = 'Tipos_de_imagenes / Producto';
    protected static $_display_column = 'name';

    /** Variables Públicas del Model */
    public $name;
    public $pixel_size;

    /** Variables private */

    /** Construct */
    public function __construct() {
        parent::__construct();
    }

    public function required_variables() {
        return array_merge(parent::required_variables(), array('name'));
    }

    //devuelve un array() de arrays de objetos
    public function related_with() {
        return array($this->process_results(), $this->pixel_sets(), $this->raster_files());
    }

    public function is_deleteable() {
        
        // if ($this->process_results())
        //     return false;

        // if ($this->pixel_sets())
        //     return false;
        
        // if ($this->raster_files())
        //     return false;

        return true;
    }

    public function process_results() {
        if (!isset($this->process_results))
            $this->process_results = Process_Result::where(Array('imagen_type_id' => $this->id));

        return $this->process_results;
    }

    public function raster_files() {
        if (!isset($this->raster_files))
            $this->raster_files = Raster_file::where(Array('image_type_id' => $this->id));

        return $this->raster_files;
    }



    public function pixel_sets() {
        if (!isset($this->pixel_sets))
            $this->pixel_sets = Pixel_set::where(Array('imagen_type_id' => $this->id));

        return $this->pixel_sets;
    }

    public static function get_index_data($filters = array()) {
        $CI=get_instance();

        // $CI->db->where($filters);

        $CI->db->select('imagen_types.id,imagen_types.name,imagen_types.created_at,imagen_types.ts');
        $CI->db->select('count(layer_types.image_type_id) as qt_layers');

        $CI->db->join('layer_types', 'layer_types.image_type_id = imagen_types.id', 'left');
        $CI->db->group_by('imagen_types.id,imagen_types.name,imagen_types.created_at,imagen_types.ts');

        return $CI->db->get(static::$_table_name)->result(get_called_class());
    }

    public static function get_dates_for($id, $from = NULL, $to = NULL)
    {
        $CI = get_instance();

        $CI->db->distinct();
        $CI->db->select('raster_layers.image_date');
        $CI->db->join('raster_files', 'imagen_types.id = raster_files.image_type_id');
        $CI->db->join('raster_layers', 'raster_files.id = raster_file_id');
        $CI->db->where('imagen_types.id', $id);

        if ($from) $CI->db->where('raster_layers.image_date>=', $from);
        if ($to)   $CI->db->where('raster_layers.image_date<=', $to);

        $CI->db->order_by('raster_layers.image_date', 'ASC');

        return $CI->db->get(static::class_table_name())->result();
    }
}
