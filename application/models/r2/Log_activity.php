<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description Loguea las actividades de todos los usuarios que ingresan al sistema.
 * Issue en la que se solicito el pedido. 
 * http://issues.monkeysoft.com.ar/issues/2901
 * @package Data Mehanics
 * @author Ariel Ramirez
 * @since 2016-10-11
 */
class Log_activity extends R2_DbObject {

    /** Variables Static de Configuración del Model */
    protected static $_table_name = 'r2_log_activity'; // Nombre de la tabla (responsabilidad de las subclases)
    protected static $_display_name = 'Activity'; // Nombre con el que se muestra la clase (dejar vacío para clases abstractas).
    protected static $_plural_name = 'Activities'; // Nombre en plural con el que se muestra la clase (dejar vacío para clases abstractas).

    public $ip;
    public $user_id;
    public $post_data;
    public $origin;
    public $controller;
    public $method;

    function __construct() {
        parent::__construct();
    }

    public static function get_processed_data($from, $to) {
        $ciObj = & get_instance();

        return $ciObj->db
            ->select("r2.log_activity.*, r2.users.name")
            ->where(array('r2.log_activity.ts BETWEEN ' => "'$from 00:00:00' AND '$to 23:59:59'"), null, FALSE)
            ->order_by('log_activity.id')
            ->join('r2.users', 'r2.users.id = log_activity.user_id')
            ->get('r2.log_activity')
            ->result(get_called_class());
    }

}
