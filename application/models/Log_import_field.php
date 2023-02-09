<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class Log_import_field extends R2_DbObject {

    /**  Variables Static de Configuración del Model */
    protected static $_table_name = 'log_import_fields';
    protected static $_display_name = 'Log de Importaci&oacute;n';
    protected static $_plural_name = 'Log de Importaci&oacute;n';
    protected static $_display_column = 'id';

    /** Variables Públicas del Model */
    public $descripcion;
    public $process_id;

    /** Construct */
    public function __construct() {
        parent::__construct();
    }

    // public function required_variables() {
    //     return array_merge(parent::required_variables(), array('name'));
    // }

    // public function related_with() {
    //     return array($this->temporal_expansion_rules());
    // }


    // public function temporal_expansion_rules() {
    //     if (!isset($this->tmporal_expansion_rules))
    //         $this->temporal_expansion_rules = Temporal_expansion_rule::where(Array('region_id' => $this->id));

    //     return $this->temporal_expansion_rules;
    // }

}
