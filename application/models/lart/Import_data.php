<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 * @author NArias
 * @package DataAnalytics
 */

class Import_data extends R2_DbObject
{

    /**  Variables Static de Configuración del Model */
    protected static $_table_name = 'import_data';
    protected static $_display_name = 'Importacion de Usos';
    protected static $_plural_name = 'Importacion de Usos';
    protected static $_display_column = 'original_name';

    /** Variables Públicas del Model */
    public $path;
    public $start_process_at;
    public $end_process_at;
    public $result;
    public $model_name;
    public $original_name;
    public $comments;
    public $version_id;
    public $client_id;
    public $project_id;

    public static $_import_errors = array();

    /** Construct */
    public function __construct()
    {
        parent::__construct();
    }

    public function required_variables()
    {
        return array_merge(parent::required_variables(), array('client_id', 'project_id', 'version_id'));
    }

    public static function references_class()
    {
        return array('client_id' => 'Client', 'project_id' => 'Project', 'version_id' => 'Version');
        // return array('client_id' => 'Client', 'project_id' => 'Project','version_id' => 'Version', 'user_id' => 'User');
    }

    public function non_editable_variables()
    {
        return array_merge(parent::non_editable_variables(), array('start_process_at', 'end_process_at', 'path', 'model_name', 'comments', 'path', 'original_name', 'result'));
    }


    public static function do_import($model_name)
    {
        $CI = get_instance();
        $CI->load->helper('string');

        $config['upload_path']   = get_instance()->config->item('upload_path');
        $config['file_name']     = $model_name . '_' . time() . '_' . random_string('numeric', 5);
        $config['allowed_types'] = '*';

        $CI->load->library('upload', $config);
        if (!isset($_FILES['import_file'])) {
            return 'No File To Upload or File too big.';
        } else if (!$CI->upload->do_upload('import_file')) {
            return $CI->upload->display_errors();
        }

        $upload_data = $CI->upload->data();
        $model = $CI->managed_class;

        $file_name = $upload_data['full_path'];

        $data = $CI->input->post();

        $instance = static::new_from_array(array(
            'client_id' => $data['client_id'],
            'version_id' => $data['version_id'],
            'project_id' => $data['project_id'],
            'path' => $file_name,
            'original_name' => $upload_data['client_name'],
            'model_name' => $model_name
        ));
        $instance->save();
        return true;
    }

    public static function do_import_from_csv($file_name, $version_id)
    {
        $CI = get_instance();

        $CI->load->library('CSVReader');
        // $CI->csvreader->p_NamedFields = false;
        $data = $CI->csvreader->open_file($file_name);
        if ($data === False) {
            return array("El archivo " . $file_name . " no puede abrirse");
        }

        //validate datetime range

        $seen_ranges = array();

        foreach ($data as $row => $value) {
            $use_ok = FALSE;
            $date_ok = FALSE;

            if (!isset($value['GRUPO']))    return array("No existe la columna: GRUPO");
            if (!isset($value['CAMPO']))    return array("No existe la columna: CAMPO");
            if (!isset($value['LOTE']))     return array("No existe la columna: LOTE");
            if (!isset($value['FECHA']))    return array("No existe la columna: FECHA");
            if (!isset($value['USODESDE'])) return array("No existe la columna: USODESDE");
            if (!isset($value['USOHASTA'])) return array("No existe la columna: USOHASTA");
            if (!isset($value['USO']))      return array("No existe la columna: USO");

            $data_array = array();

            $gruop = $value['GRUPO'];
            $farm = $value['CAMPO'];
            $field = $value['LOTE'];

            $date_declaration = DateTime::createFromFormat("d/m/Y", $value['FECHA']);
            $date_uses_from = DateTime::createFromFormat("d/m/Y", $value['USODESDE']);
            $date_uses_to = DateTime::createFromFormat("d/m/Y", $value['USOHASTA']);
            $use_concrete = $value['USO'];

            if ($value['FECHA'] != '') {
                if ($date_declaration !== FALSE) {
                    $date_declaration = $date_declaration->format('Y-m-d');
                    if (substr($date_declaration, 0,2) == '00') {
                        static::$_import_errors[] = "La fecha '$date_declaration' es invalida. Fila: " . ( $row + 2 ) . ".";
                        continue;
                    }
                    $date_ok = TRUE;
                } else {
                    static::$_import_errors[] = "La fecha de declaracion es invalida o no coincide con el formato dd/mm/YYYY. Fila: " . ($row + 2) . ".";
                }
            } else {
                static::$_import_errors[] = "La fecha de declaracion es obligatoria. Formato dd/mm/YYYY. Fila: " . ($row + 2) . ".";
            }

            if ($date_uses_from !== FALSE) {
                $date_uses_from = $date_uses_from->format('Y-m-d');         
                if (substr($date_uses_from, 0,2) == '00') {
                    static::$_import_errors[] = "La fecha '$date_uses_from' es invalida. Fila: " . ( $row + 2 ) . ".";
                    continue;
                }
            }

            if ($date_uses_to !== FALSE) {
                $date_uses_to = $date_uses_to->format('Y-m-d');
                if (substr($date_uses_to, 0,2) == '00') {
                    static::$_import_errors[] = "La fecha '$date_uses_to' es invalida. Fila: " . ( $row + 2 ) . ".";
                    continue;
                }
            }

            if (!isset($seen_ranges[$value['GRUPO'] . $value['CAMPO'] . $value['LOTE']]))
                $seen_ranges[$value['GRUPO'] . $value['CAMPO'] . $value['LOTE']] = array();

            $str_date_uses_from = $date_uses_from !== FALSE ? "'$date_uses_from'" : 'NULL';
            $str_date_uses_to = $date_uses_to !== FALSE ? "'$date_uses_to'" : 'NULL';
            $res = $CI->db->query("SELECT $str_date_uses_from > $str_date_uses_to as is_inverted")->result();

            if (count($res) && $res[0]->is_inverted == 't') {
                static::$_import_errors[] = "El rango de fechas ('$date_uses_from', '$date_uses_to') esta invertido. Fila: " . ($row + 2) . ".";
                continue;
            }
            foreach ($seen_ranges[$value['GRUPO'] . $value['CAMPO'] . $value['LOTE']] as $range) {

                $str_range_from = $range[0] !== FALSE ? "'$range[0]'" : 'NULL';
                $str_range_to = $range[1] !== FALSE ? "'$range[1]'" : 'NULL';


                $res = $CI->db->query("SELECT tsrange($str_range_from, $str_range_to, '[]') && tsrange($str_date_uses_from, $str_date_uses_to, '[]') as has_intersection")->result();

                if (count($res) && $res[0]->has_intersection == 't') {
                    static::$_import_errors[] = "El rango de fechas ('$date_uses_from', '$date_uses_to') coincide con un rango de fechas ya visto en el archivo ('" . $range[0] . "', '" . $range[1] . "'). Fila: " . ($row + 2) . ".";
                }
            }

            $seen_ranges[$value['GRUPO'] . $value['CAMPO'] . $value['LOTE']][] = array($date_uses_from, $date_uses_to);

            if ($use_concrete == '') {
                static::$_import_errors[] = "EL USO Es obligatorio para la asignacion Fila: " . ($row + 2) . ".";
            } else {
                $use = Use_concret::where(array('upper("name")' => "upper('$use_concrete')"), false);

                if (!count($use)) {
                    static::$_import_errors[] = "EL USO {$value['USO']} no se encontro para la asignacion Fila: " . ($row + 2) . ".";
                } else {
                    $use_ok = TRUE;
                    $use_concrete = $use[0]->id;
                }
            }

            if ($gruop == '') {
                static::$_import_errors[] = "GRUPO Es obligatorio para la asignacion Fila: " . ($row + 2) . ".";
            }

            if ($field == '') {
                static::$_import_errors[] = "LOTE Es obligatorio para la asignacion Fila: " . ($row + 2) . ".";
            }

            if ($farm == '') {
                static::$_import_errors[] = "CAMPO Es obligatorio para la asignacion Fila: " . ($row + 2) . ".";
            }

            $field_data = Uses_asign::check_field_exists($farm, $field, $gruop, $version_id);

            if (!$field_data) {
                static::$_import_errors[] = "No existe un registro para el GRUPO CAMPO LOTE Fila: " . ($row + 2) . ".";
            } else if ($field_data && $date_ok && $use_ok) {
                Uses_asign::get_field_id_and_asign_uses($farm, $field, $gruop, $version_id, $date_declaration, $use_concrete, $date_uses_from, $date_uses_to);
            }
        }

        $CI->csvreader->close_file();

        if (count(static::$_import_errors)) {
            return static::$_import_errors;
        }

        return true;
    }



    public function set_result_successfull_with_warnings()
    {
        $this->result = "Success with Warnings";
    }


    public function set_result_successfull()
    {
        $this->result = "Success";
    }

    public function set_result_with_error($error_string)
    {
        $this->result = $error_string;
    }

    public function result_with_html_display()
    {

        if ($this->result == "")
            return "";

        if ($this->result == "Success")
            return '<i class="fa fa-thumbs-o-up" style="color:darkgreen" aria-hidden="true"></i>&nbsp'
                . $this->result;

        if ($this->result == "Success with Warnings")
            return '<i class="fa fa-exclamation-triangle" style="color:lightcoral" aria-hidden="true"></i>&nbsp'
                . $this->result;

        if ($this->result == "Success with Warnings")
            return '<i class="fa fa-times" style="color:darkred" aria-hidden="true"></i>&nbsp'
                . $this->result;
    }

    public static function all_permitted()
    {
        $CI = get_instance();

        if (!in_array($CI->user->id, User::$_SuperUsers)) {
            $CI->db->select('import_data.*');
            $CI->db->join("clients", "clients.id = import_data.client_id");
            $CI->db->where('organization_id', $CI->user->organization_id);
        }

        return parent::all_permitted();
    }
}
