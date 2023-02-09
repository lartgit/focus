<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class Variable_Type extends Parameter_Type {

    /**  Variables Static de Configuración del Model */
    // protected static $_table_name = 'parameter_types';
    protected static $_display_name = 'Tipo de variable';
    protected static $_plural_name = 'Tipos de variables';
    // protected static $_display_column = 'name';

    /** Variables Públicas del Model */
    public $quantity;

    /** Variables private */

    /** Construct */
    public function __construct() {
        parent::__construct();
    }

    public function related_with(){
        return array();
    }

    public function non_editable_variables() {
        return array_merge(parent::non_editable_variables(), array('quantity'));
    }
}
