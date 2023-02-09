<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description of R2_Search
 *    Model para los usuarios del sistema.
 *
 * @author <NArias>
 * @package <r2>
 *
 */
class R2_Search extends CI_Model {
    /* {2015-09-28} */

    public $classes;

    /* ---------- */
    /* Construct  */
    /* ---------- */

    public function __construct() {
        parent::__construct();
        //Array que guarda las clases que se van a utilizar en la busqueda
        $this->classes = Array('client', 'project', 'version', 'farm', 'user', 'user_group', 'pixel_set', 'use_declared', 'region', 'use_concret', 'field');
    }

    /* ---------------------------------------------------------------------------------- */
    /* -- Funciones principales --------------------------------------------------------- */
    /* ---------------------------------------------------------------------------------- */

    /**
     * Esta función retorna un conjunto de resultados tal que cada resultado tien
     *    el campo de búsqueda, el id del objeto,  el nombre de la clase
     *    y demás columnas necesarias.
     * 
     * @param String $search_string
     */
    public function find_alike($search_string) {
        $query = '';
        if (strlen($search_string) < 4)
            return Array();

        $query = 'SELECT * FROM (';
        foreach ($this->classes as $class) {
            $table_name = $class::class_table_name();
            $display_column = $class::class_display_column();

            $query = $query . "SELECT id," . $display_column . " as display, '" . $class . "' as class_name, ts FROM " . $table_name;

            if ($class !== end($this->classes)) {
                $query = $query . ' UNION ';
                continue;
            }
        }
        $query = $query . ")AS foo WHERE lower(display) LIKE(lower('%" . $search_string . "%'))";

        return $this->db->query($query)->result();
    }

}
