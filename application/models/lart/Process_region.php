<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 * @author ARamirez
 * @package Focus
 */
class Process_region extends R2_DbObject {

    /**  Variables Static de Configuración del Model */
    protected static $_table_name = 'process_regions';
    protected static $_display_name = 'Proceso de Regiones';
    protected static $_plural_name = 'Procesos de Regiones';

    /** Variables Públicas del Model */

    /** Variables private */
    // private $_extension = 'shp';
    public $procces_run;
    public $user_id;


    /** Construct */
    public function __construct() {
        parent::__construct();
    }

    public function required_variables() {
        return array_merge(parent::required_variables(), array('path'));
    }

    public static function references_class() {
        return array();
    }

    public function non_editable_variables() {
        return array_merge(parent::non_editable_variables(), array('start_process_at', 'end_process_at', 'path', 'description','set_id','procces_run','user_id'));
    }

}
