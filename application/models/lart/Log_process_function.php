<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class Log_Process_Function extends R2_DbObject {

    /**  Variables Static de Configuración del Model */
    protected static $_table_name = 'log_process_functions';
    protected static $_display_name = 'Log de Procesos de Funciones';
    protected static $_plural_name = 'Log de Procesos de Funciones';
    protected static $_display_column = 'id';

    /** Variables Públicas del Model */
    public $descripcion;
    public $process_id;

    /** Construct */
    public function __construct() {
        parent::__construct();
    }

}
