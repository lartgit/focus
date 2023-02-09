<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class Pixel_selection_rule extends R2_DbObject {

    /**  Variables Static de Configuración del Model */
    protected static $_table_name = 'pixel_selection_rules';
    protected static $_display_name = 'Regla de selección de Pixel';
    protected static $_plural_name = 'Reglas de selección de Pixel';
    protected static $_display_column = 'name';

    /** Variables Públicas del Model */
    public $name;
    public $tolerance;
    public $errors;
    public $success;

    //public $inactive_reason;
    /** Construct */
    public function __construct() {
        parent::__construct();

        $this->add_config("tolerance_max", 100);
        $this->add_config("tolerance_min", 0);
    }

    public function required_variables() {
        return array_merge(parent::required_variables(), array('name', 'tolerance'));
    }

    public function related_with() {
        return null;
    }

    public static function references_class() {
        return Array();
    }

    public function is_deleteable() {

        return true;
    }

    public function validate() {

        if (!isset($this->tolerance))
            $this->errors("El valor tolerancia es requerido");

        if (isset($this->tolerance) && ($this->tolerance < 0 || $this->tolerance > 100)) {
            $this->errors("El valor de la tolerancia debe estar entre 0 y 100");
        }

        return parent::validate();
    }

    public function validate_excel_file($data) {

        $cant_save = 0;
        $instances = array();

        //Elimino los datos null que me vevolvio el archivo excel
        foreach ($data as $key => &$row) {
            $row = array_filter($row, function($cell) {
                return !is_null($cell);
            }
            );
            if (count($row) == 0) {
                unset($data[$key]);
            }
        }
        unset($row);

        //Re-indexo el array
        $new_data = [];
        foreach ($data as $d) {
            $sub_data = [];
            foreach ($d as $d1) {
                array_push($sub_data, $d1);
            }
            array_push($new_data, $sub_data);
        }

        foreach ($new_data as $k => $v) {

            if ($k !== 0) {
                //chequeo que el registro tenga un nombre seteado
                if (empty($v[0])) {
                    $this->errors[] = lang("El registro ") . $k . lang(" no tiene nombre");
                    continue;
                }
                //chequeo que el registro tenga una tolerancia seteada y sea numerica
                if (empty($v[1])) {
                    $this->errors[] = lang("El registro ") . $k . lang(" no tiene tolerancia");
                    continue;
                } else if (!is_numeric($v[1])) {
                    $this->errors[] = lang("El registro ") . $k . lang(" tiene un valor de tolerancia incorrecto");
                    continue;
                } else if ($v[1] < 0 || $v[1] > 100) {
                    $this->errors[] = lang("El registro ") . $k . lang(" tiene un valor de tolerancia fuera de rango");
                    continue;
                }

                // $class = $this->_table_name;

                $datos = array("id" => "", "name" => $v[0], "tolerance" => $v[1]);
                $instances[] = Pixel_selection_rule::new_from_array($datos);
                $cant_save++;
            }
        }

        if (!isset($this->errors)) {

            foreach ($instances as $inst) {
                $inst->save();
            }
            $this->success[] = $cant_save . lang(" datos importados con exito");
            // $this->error_string = NULL;
            return true;
        } else {
            // $this->error_string = true;
            return false;
        }
    }

}
