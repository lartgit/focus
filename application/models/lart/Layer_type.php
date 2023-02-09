<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 */
class Layer_type extends R2_DbObject {

    /**  Variables Static de Configuración del Model */
    protected static $_table_name = 'layer_types';
    protected static $_display_name = 'Tipo de capa';
    protected static $_plural_name = 'Tipos de capa';
    protected static $_display_column = 'name';

    /** Variables Públicas del Model */
    public $parameter_type_id;
    public $image_type_id;
    public $name;
    public $id;

    /** Construct */
    public function __construct() {
        parent::__construct();
    }

    public function related_with() {
        return Array();
    }

    public function required_variables() {
        return array_merge(parent::required_variables(), array('name', 'parameter_type_id', 'image_type_id'));
    }

    public static function references_class() {
        return Array('parameter_type_id' => 'Parameter_type', 'image_type_id' => 'Imagen_type');
    }

    public function validate() {
        // if (isset($this->id) && !empty($this->id))
        //     $old = $this->where(Array('data_type_id' => $this->data_type_id, 'imagen_type_id' => $this->imagen_type_id, 'id !=' => $this->id));
        // else
        //     $old = $this->where(Array('data_type_id' => $this->data_type_id, 'imagen_type_id' => $this->imagen_type_id));

        // if (count($old) !== 0) {
        //     $this->errors("Ya existe ese tipo de datos para ese tipo de imagen");
        // }

        return parent::validate();
        // return true;
    }

	public static function get_index_data($filters = array()) {
		$CI=get_instance();

		$CI->db->where($filters);

		$CI->db->select('layer_types.*');
                
		return $CI->db->get(static::$_table_name)->result(get_called_class());
	}    

}
