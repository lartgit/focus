<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class Parameter_Type extends R2_DbObject {

    /**  Variables Static de Configuración del Model */
    protected static $_table_name = 'parameter_types';
    protected static $_display_name = 'Tipo de parametro';
    protected static $_plural_name = 'Tipos de parametros';
    protected static $_display_column = 'name';

    /** Variables Públicas del Model */
    public $name;
    public $description;
    public $unit;

    /** Variables private */

    /** Construct */
    public function __construct() {
        parent::__construct();
    }

    public static function get_index_data($limit=null) {
        $CI=get_instance();

        if ($limit)
            $CI->db->limit($limit);

        $CI->db->select('parameter_types.*');
        $CI->db->select('format_types.name as format_type_name');

        $CI->db->join('format_types', 'format_types.id = format_type_id', 'LEFT');
        
        $CI->db->order_by('parameter_types.ts', 'DESC');

        return $CI->db->get(static::$_table_name)->result(get_called_class());
    }
    
    public function related_with(){
        return $this->parameters();
    }

    private function parameters() {
        return Parameter::where(Array('parameter_type_id'=>$this->primary_key_value()));
    }

    public static function references_class() {
        return Array(
            'format_type_id' => 'Format_Type',
        );
    }

    public function required_variables() {
        return array_merge(parent::required_variables(),array('name'));
    }

    public function is_deleteable() {
        return true;
    }
    
    public function validate(){
        if(empty($this->name)){
            $this->errors("El nombre no puede estar vacío");
        }
        
        return parent::validate();
    }
}
