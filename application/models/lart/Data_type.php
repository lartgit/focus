<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class Data_Type extends R2_DbObject {

    /**  Variables Static de Configuración del Model */
    protected static $_table_name = 'data_types';
    protected static $_display_name = 'producto';
    protected static $_plural_name = 'productos';
    protected static $_display_column = 'name';

    /** Variables Públicas del Model */
    public $name;
    public $unity;
    public $duration;

    /** Construct */
    public function __construct() {
        parent::__construct();
    }

    public function required_variables() {
        return array_merge(parent::required_variables(), array('name', 'unity'));
    }

    public function related_with() {
        //devuelve un array() de arrays de objetos
        return array($this->imagen_types());
    }

    public function is_deleteable() {

        if ($this->imagen_types()) {

            return false;
        }

        return true;
    }

    public function imagen_types() {
        if (!isset($this->imagen_types))
            $this->imagen_types = $this->db->query(
                            "SELECT * FROM imagen_types WHERE id IN
                        (SELECT imagen_type_id FROM layers WHERE data_type_id = $this->id)"
                    )->result('Imagen_type');


        return $this->imagen_types;
    }

}
