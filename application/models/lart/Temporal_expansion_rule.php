<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class Temporal_expansion_rule extends R2_DbObject
{

    /**  Variables Static de Configuraci�n del Model */
    protected static $_table_name = 'temporal_expansion_rules';
    protected static $_display_name = 'Regla de Expansion Temporal';
    protected static $_plural_name = 'Reglas de Expansion Temporal';
    protected static $_display_column = 'id';
    // Para la importacion de los usos a los fields
    public static $import_errors = array();

    /** Variables P�blicas del Model */
    public $region_id;
    public $use_declared_id;
    public $use_concrete_id;
    public $declaration_month;
    public $month_from;
    public $month_to;
    public $errors;
    public $success;

    //public $inactive_reason;
    /** Construct */
    public function __construct()
    {
        parent::__construct();
        $this->add_config("month_to_max", 12);
        $this->add_config("month_to_min", 0);
        $this->add_config("month_from_max", 12);
        $this->add_config("month_from_min", 0);
        $this->add_config("declaration_month_max", 12);
        $this->add_config("declaration_month_min", 1);
    }


    public function FunctionName()
    {
    }

    public function required_variables()
    {
        return array_merge(parent::required_variables(), array('region_id', 'use_declared_id', 'use_concrete_id', 'declaration_month', 'month_from', 'month_to'));
    }

    public function related_with()
    {
        return null;
    }

    public static function references_class()
    {
        return array('use_declared_id' => 'Use_declared', 'use_concrete_id' => 'Use_concret', 'region_id' => 'Region');
    }

    public function is_deleteable()
    {

        return true;
    }

    public function validate()
    {
        $this->db->where("region_id", $this->region_id);
        $this->db->where("use_concrete_id", $this->use_concrete_id);
        $this->db->where("use_declared_id", $this->use_declared_id);
        $this->db->where("declaration_month", $this->declaration_month);
        $res = static::all();

        if (count($res) > 0) {
            $this->errors("Duplicate key ('region', 'use_declared', 'use_concrete', 'declaration_month')");
        }
        return parent::validate();
    }

    public function validate_excel($data)
    {
        $CI = get_instance();
        $cant_save = 0;
        $instances = array();

        //Elimino los datos null que me vevolvio el archivo excel
        foreach ($data as $key => &$row) {
            $row = array_filter($row, function ($cell) {
                return !is_null($cell);
            });
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

        foreach ($data as $k => $v) {
            if ($k !== 0) {

                //chequeo que el registro tenga una regi�n
                if (empty($v[0]) || $v[0] === '') {
                    $this->errors[] = "El registro " . $k . " no tiene regi&oacute;n";
                    continue;
                }

                if (is_numeric($v[0])) {
                    // $this->errors[] = "El registro " . $k . " tiene regi&oacute;n invalida";
                    // continue;
                    $v[0] = (string)$v[0];
                }

                //chequeo que el registro tenga una region existente para la organizacion del usuario
                $CI->db->select('regions.*');
                $CI->db->join('maps', 'maps.id = map_id');
                if ($CI->user->id > 0) {
                    $CI->db->where(array('organization_id' => $CI->user->organization_id)); // esto se sigue usando?
                }
                $region = Region::where(array('regions.name' => $v[0]));

                if (!$region) {
                    $this->errors[] = "El registro " . $k . " tiene regi&oacute;n invalida";
                    continue;
                }

                //chequeo que el registro tenga un uso declarado seteado
                if (empty($v[1])) {
                    $this->errors[] = "El registro " . $k . " no tiene uso declarado";
                    continue;
                }

                //chequeo que el registro tenga un uso declarado existente
                $use_declared = Use_declared::where_in('name', $v[1]);

                if (!$use_declared) {
                    $this->errors[] = "El registro " . $k . " tiene un uso declarado invalido";
                    continue;
                }

                //chequeo que el registro tenga un uso concreto seteado
                if (empty($v[2])) {
                    $this->errors[] = "El registro " . $k . " no tiene uso concreto";
                    continue;
                }

                //chequeo que el registro tenga un uso concreto existente
                $use_concret = Use_concret::where_in('name', $v[2]);

                if (!$use_concret) {
                    $this->errors[] = "El registro " . $k . " tiene un uso concreto invalido";
                    continue;
                }

                //chequeo que el registro tenga los valores de los meses
                if (empty($v[3])) {
                    $this->errors[] = "El registro " . $k . " no tiene mes declarado";
                    continue;
                } else if (!is_numeric($v[3]) && ($v[3] < 1 || $v[3] > 12)) {
                    $this->errors[] = "El registro " . $k . " tiene un valor de mes declarado incorrecto";
                    continue;
                }

                if (empty($v[4]) && $v[4] !== 0.0) {
                    //                    $this->errors[] = "El registro ") . $k . " no tiene mes desde");
                    //                    continue;
                } else if (!is_numeric($v[4])) {
                    $this->errors[] = "El registro " . $k . " tiene un valor de mes desde incorrecto";
                    continue;
                }

                if (empty($v[5]) && $v[4] !== 0.0) {
                    //                    $this->errors[] = "El registro " . $k . " no tiene mes hasta";
                    //                    continue;
                } else if (!is_numeric($v[5])) {
                    $this->errors[] = "El registro " . $k . " tiene un valor de mes hasta incorrecto";
                    continue;
                }

                $name_region = $region[0]->name;
                $name_use_declared = $use_declared[0]->name;
                $name_use_concret = $use_concret[0]->name;

                $id_region = $region[0]->id;
                $id_use_declared = $use_declared[0]->id;
                $id_use_concret = $use_concret[0]->id;

                //chequeo que la regla no este repetida
                $exists = self::where(array(
                    'region_id' => $id_region, 'use_declared_id' => $id_use_declared,
                    'use_concrete_id' => $id_use_concret, 'declaration_month' => $v[3]
                ));

                if (count($exists) !== 0) {
                    $this->errors[] = "La regla: region: $name_region, use_declared: $name_use_declared, use_concrete: $name_use_concret, declaration_month: $v[3] ya existe.";
                    continue;
                }

                $datos = array("id" => "", "region_id" => $id_region, "use_declared_id" => $id_use_declared, "use_concrete_id" => $id_use_concret, "declaration_month" => $v[3], "month_from" => $v[4], "month_to" => $v[5]);
                $instances[] = Temporal_expansion_rule::new_from_array($datos);
                $cant_save++;
            }
        }

        if (!isset($this->errors)) {

            foreach ($instances as $inst) {
                $inst->save();
            }
            $this->success[] = $cant_save . " dato(s) importado(s) con &eacute;xito";
            return true;
        } else {
            return false;
        }
    }

    public static function all_permitted()
    {
        $CI = get_instance();

        // Dejo esto afuera porque lo necesito par ver el map id.
        $CI->db->select('maps.name as map_name');
        $CI->db->select('regions.name as region_name');
        $CI->db->join('regions', 'regions.id = region_id');
        $CI->db->join('maps', 'maps.id = map_id');

        if (!in_array($CI->user->id, User::$_SuperUsers)) {
            $CI->db->where('organization_id', $CI->user->organization_id);
        }

        return parent::all_permitted();
    }


    //extiendo all_permited para agregarle un filtro de limit
    public static function all_permitted_filtered($limit)
    {
        $CI = get_instance();

        if ($limit) {
            $CI->db->limit($limit);
        }

        $CI->db->order_by('ts', 'DESC');

        return static::all_permitted();
    }
}
