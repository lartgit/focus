<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class Parameter extends R2_DbObject
{

    /**  Variables Static de Configuración del Model */
    protected static $_table_name = 'parameters';
    protected static $_display_name = 'Parámetro';
    protected static $_plural_name = 'Parámetros';
    protected static $_display_column = 'parameter_type_id';

    /** Variables Públicas del Model */
    public $map_id;
    public $region_id;
    public $use_id;
    public $month;
    public $parameter_type_id;
    public $value;
    public $priority;

    public static $_import_errors;
    /** Variables private */
    // public $versions;

    /** Construct */
    public function __construct()
    {
        parent::__construct();
    }

    public function related_with()
    {
        return NULL;
    }

    public static function references_class()
    {
        return array(
            'map_id' => 'Map',
            'region_id' => 'Map_region',
            'use_id' => 'Use_concret',
            'parameter_type_id' => 'Parameter_Type'
        );
    }

    public function required_variables()
    {
        return array_merge(parent::required_variables(), array('parameter_type_id', 'map_id', 'region_id', 'priority'));
    }

    public function non_editable_variables()
    {
        return array_merge(parent::non_editable_variables(), array('map_id', 'region_id'));
    }

    public function is_deleteable()
    {
        //    if ( issempty( $this->pixels_field_use() ) )
        return true;
        //   else
        //       return false;
    }

    public function validate()
    {
        $parameter_type = Parameter_Type::find($this->parameter_type_id);
        if (!$parameter_type) {
            return array("El tipo de parametro no existe");
        }

        $format_type = Format_Type::where(array('id' => $parameter_type->format_type_id));
        if (count($format_type) && $format_type[0]->id == Format_Type::$Numeric) {
            // aca tengo que comprobar si es un numero
            if (!is_numeric($this->value)) {
                return array("El valor ingresado no corresponde con el formato establecido (numerico)");
            }
        }

        return parent::validate();
    }

    public static function get_index_data($filters = array())
    {
        $CI = get_instance();

        $map_id = $region_id = -1;
        $search = '';
        if (isset($filters['map_id'])) $map_id = $filters['map_id'];
        if (isset($filters['region_id'])) $region_id = $filters['region_id'];
        if (isset($filters['search'])) $search = $filters['search'];

        $add_where = '';
        if ($CI->user->id > 0) $add_where = "AND organization_id = " . $CI->user->organization_id;

        return $CI->db->query("
            SELECT parameters.*, maps.name as map_name, regions.name as region_name, use_concretes.name as use_name, parameter_types.name as parameter_type_name
            FROM parameters
            JOIN parameter_types ON parameter_types.id = parameter_type_id
            JOIN maps ON maps.id = parameters.map_id
            JOIN regions ON regions.id = region_id
            LEFT JOIN use_concretes ON use_concretes.id = use_id
            WHERE 
            ($map_id = -1 OR parameters.map_id = $map_id) AND
            ($region_id = -1 OR parameters.region_id = $region_id) AND
            (
                '$search' = '' OR
                lower(maps.name) LIKE lower('%$search%') OR
                lower(regions.name) LIKE lower('%$search%') OR
                lower(parameter_types.name) LIKE lower('%$search%') OR
                lower(use_concretes.name) LIKE lower('%$search%')
            )
            $add_where
        ")->result(get_called_class());
    }

    public static function import($file_name)
    {
        $CI = get_instance();

        $CI->load->library('CSVReader');
        $data = $CI->csvreader->open_file($file_name);
        if ($data === False) {
            return "El archivo " . $file_name . " no puede abrirse";
        }

        foreach ($data as $row => $value) {
            // mapa
            // region
            // uso
            // mes
            // parametro
            // valor
            if (!isset($value['region']))    return "No existe la columna: 'region'";
            if (!isset($value['mapa']))      return "No existe la columna: 'mapa'";
            if (!isset($value['uso']))       return "No existe la columna: 'uso'";
            if (!isset($value['mes']))       return "No existe la columna: 'mes'";
            if (!isset($value['parametro'])) return "No existe la columna: 'parametro'";
            if (!isset($value['valor']))     return "No existe la columna: 'valor'";
            if (!isset($value['prioridad'])) return "No existe la columna: 'prioridad'";

            $data_array = array();

            $mapa = Map::where(array('name' => $value['mapa']));
            if (!count($mapa)) {
                static::$_import_errors[] = "Mapa con nombre: '{$value['mapa']}' no encontrado en fila " . ($row + 2);
                continue;
            }
            $data_array['map_id'] = $mapa[0]->primary_key_value();

            $region = Region::where(array('name' => $value['region'], 'map_id' => $mapa[0]->primary_key_value()));
            if (!count($region)) {
                static::$_import_errors[] = "Map_region con nombre '{$value['region']}' y map_id '" . $mapa[0]->primary_key_value() . "' no encontrado en fila " . ($row + 2);
                continue;
            }
            $data_array['region_id'] = $region[0]->primary_key_value();

            $uso = NULL;
            if (!empty($value['uso']) && $value['uso'] !== '*' && $value['uso'] !== '%') {
                $uso = Use_concret::where(array('name' => $value['uso']));
                if (!count($uso)) {
                    static::$_import_errors[] = "Uso concreto con nombre '{$value['uso']}' no encontrado en fila " . ($row + 2);
                    continue;
                }
            }
            $data_array['use_id'] = $uso ? $uso[0]->primary_key_value() : NULL;

            $mes = NULL;
            if ($value['mes'] !== '*') {
                $mes = intval($value['mes']);
            }
            $data_array['month'] = $mes;

            $parameter_type = Parameter_Type::where(array('name' => $value['parametro']));
            if (!count($parameter_type)) {
                $parameter_type = Parameter_Type::new_from_array(array('name' => $value['parametro']));
                if (!$parameter_type->save()) {
                    static::$_import_errors[] = "No se pudo insertar el parameter_type '{$value['parametro']}' en fila " . ($row + 2);
                    continue;
                }
            }
            $data_array['parameter_type_id'] = is_array($parameter_type) ? $parameter_type[0]->primary_key_value() : $parameter_type->primary_key_value();

            $format_type = Format_Type::where(array('id' => is_array($parameter_type) ? $parameter_type[0]->format_type_id : $parameter_type->format_type_id));
            if (count($format_type) && $format_type[0]->id == Format_Type::$Numeric) {
                // aca tengo que comprobar si es un numero
                if (!is_numeric($value['valor'])) {
                    static::$_import_errors[] = "El valor ingresado no corresponde con el formato establecido (numerico) en fila " . ($row + 2);
                    continue;
                }
            }

            $data_array['value'] = $value['valor'];

            if (empty($value['prioridad'])) {
                static::$_import_errors[] = "Prioridad no puede estar vacio. Encontrado en fila " . ($row + 2);
                continue;
            }

            $data_array['priority'] = intval($value['prioridad']);

            if ($data_array['priority'] <= 0) {
                $data_array['priority'] = 1;
            }

            //Me fijo si ya existe ese parametro
            $param = static::where(array(
                'map_id' => $data_array['map_id'],
                'region_id' => $data_array['region_id'],
                'use_id' => $data_array['use_id'],
                'parameter_type_id' => $data_array['parameter_type_id'],
                'month' => $data_array['month'],
            ));

            if (count($param)) {
                $param = $param[0];

                $param->value = $data_array['value'];
                $param->priority = $data_array['priority'];
                $param->save();
            } else {
                $instance = static::new_from_array($data_array);
                $instance->save();
            }
        }

        $CI->csvreader->close_file();

        if (count(static::$_import_errors)) return static::$_import_errors;
        return true;
    }

    public static function all_permitted()
    {
        $CI = get_instance();

        if (!in_array($CI->user->id, User::$_SuperUsers)) {
            $CI->db->join('regions', 'regions.id = region_id');
            $CI->db->join('maps', 'maps.id = map_id');
            $CI->db->where('organization_id', $CI->user->organization_id);
        }

        return parent::all_permitted();
    }
}
