<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 * @author agb 2019
 * @package Focus
 */
class Format_Type extends R2_DbObject {

    /**  Variables Static de Configuración del Model */
    protected static $_table_name = 'format_types';
    protected static $_display_name = 'Tipo de formato';
    protected static $_plural_name = 'Tipos de formatos';
    protected static $_display_column = 'name';

    public static $String = 1;
    public static $Numeric = 2;

    /** Variables Públicas del Model */
    public $name;

    /** Variables private */

    /** Construct */
    public function __construct() {
        parent::__construct();
    }

    public function related_with(){
        return $this->parameter_types();
    }

    private function parameter_types() {
        return Parameter_Type::where(Array('format_type_id'=>$this->primary_key_value()));
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
