<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 * @author Yuri Zoolander 2016
 * @package Focus
 */
class Process_Function extends R2_DbObject
{

    /**  Variables Static de Configuración del Model */
    protected static $_table_name = 'process_functions';
    protected static $_display_name = 'relacion_para_exportacion_2 ';
    protected static $_plural_name = 'procesos_de_relaciones_para_exportacion_2';

    /** Variables Públicas del Model */
    public $name;
    public $user_id;
    public $process_result_id;
    public $function_id;
    public $status;
    public $start_process_at;
    public $end_process_at;
    public $description;
    public $procces_run;
    public $map_id;

    /** Variables private */
    //private $farms;

    /** Construct */
    public function __construct()
    {
        parent::__construct();

        $this->user_id = $this->session->userdata('userid');
    }

    public function non_editable_variables()
    {
        $vars = array_merge(parent::non_editable_variables(), array('user_id', 'start_process_at', 'end_process_at', 'description', 'active', 'status', 'function_id', 'process_result_id', 'procces_run', 'map_id'));

        return $vars;
    }

    public function related_with()
    {
        return array();
    }

    public static function references_class()
    {
        return array(
            'process_result_id' => 'Result',
            'function_id' => 'Function_Creator'
        );
    }

    public static function new_from_array($asociativeArray = array())
    {
        $new_instance = parent::new_from_array($asociativeArray);
        //usuario de la session
        if (!isset($new_instance->user_id))
            $new_instance->user_id = get_instance()->user->id;
        //el status los creo como a procesar
        if (!isset($new_instance->status))
            $new_instance->status = 'pending';
        // Lo comento pero no se quien lo hizo ni para que sirver
        // $pr_id = Process_Result::find($new_instance->process_result_id);
        // if ($pr_id)
        //     $new_instance->date = $pr_id->date;

        return $new_instance;
    }


    //Acciones a hacer despues de guardar el objeto
    protected function after_save()
    {
        parent::after_save();
        self::desert();
    }


    /**
     * Metodo que verifica si hay datos en la db para la tabla many to many 
     * localities_by_group_localities
     * Si existen los borra y los vuelve a insertar.
     * Sino, los Inserta.
     * Este metodo se ejecuta en el after save de esta clase, como la variable localities es un array cuando hago new from
     * array no le da bola
     * 
     * @author Ariel Ramirez
     */
    protected function desert()
    {
        $many_groups = Date_by_process_f2::where(array('process_f2_id' => $this->id));
        if (empty($many_groups)) {
            self::create_many_to_many();
        } else {
            $tmp = $this->db->query("DELETE FROM date_by_process_f2 WHERE process_f2_id = {$this->id}");
            if ($tmp)
                self::create_many_to_many();
        }
    }

    /**
     * Para no duplicar codigo.
     * @author Ariel Ramirez     
     */
    protected function create_many_to_many()
    {
        $dates =  $this->input->post('date_column');
        //   if (isset($new_instance->birth_date))
        // $new_instance->birth_date = date('Y-m-d', strtotime($new_instance->birth_date));
        foreach ($dates as $each) {
            if (empty($each)) continue;
            $instance =  Date_by_process_f2::new_from_array(array('date' => date('Y-m-d', strtotime($each)), 'process_f2_id' => $this->id));
            $instance->save();
        }
    }

    public function validate()
    {

        //$old_date = $this->where(Array('set_id'=>$this->set_id,'date'=>  $this->date));
        //$tmp = static::find_named($this->name);
        //Caso nuevo reg
        if (!$this->process_result_id)
            //$this->errors[] = "Estos campos no pueden estar vacios";
            $this->errors("Proceso Focus 1 no puede estar vacio");
        else
            if (!Process_Result::find($this->process_result_id))
            $this->errors("El Proceso Focus 1 no es Valido");

        if (!$this->name)
            //$this->errors[] = "Estos campos no pueden estar vacios";
            $this->errors("Nombre no pueden estar vacio");

        if (!$this->function_id)
            //$this->errors[] = "Estos campos no pueden estar vacios";
            $this->errors("Función no puede estar vacio");
        else
            if (!Function_creator::find($this->function_id))
            $this->errors("El Proceso Focus 1 no es Valido");

        return parent::validate();
    }

    public function required_variables()
    {
        return array_merge(parent::required_variables(), array('name', 'function_id', 'process_result_id'));
    }

    public function function_name()
    {
        if (!isset($this->function_name))
            $this->function_name = Function_creator::find($this->function_id);
        if (!isset($this->function_name))
            return '';
        return $this->function_name->name;
    }

    public function process_result_name()
    {
        if (!isset($this->process_result_name))
            $this->process_result_name = Process_Result::find($this->process_result_id);
        return $this->process_result_name->name;
    }

    public function is_deleteable()
    {
        /*$proces_run = $this->where(array('id' => $this->id));

        if ($proces_run[0]->procces_run == 't') {
            return false;
        }*/

        return true;
    }

    public static function get_index_data($filters = array())
    {
        $ciObj = &get_instance();

        //recorro los filtros que me llegaron por la key
        foreach ($filters as $key => $each) {
            $ciObj->db->where_in($key, $each);
        }
        //$ciObj->db->where_in('process_result_id', $filters['process_result_id']);

        $ciObj->db->select(static::class_schema_name() . '.' . static::class_table_name() . '.*');
        $ciObj->db->select('users.name as user');
        $ciObj->db->select("date_trunc('second', COALESCE(process_functions.end_process_at, NOW()) - process_functions.start_process_at) as time", false);
        $ciObj->db->join('users', 'users.id = user_id');
        if ($ciObj->user->organization_id > 0) {
            $ciObj->db->where('organization_id', $ciObj->user->organization_id);
        }
        $data['result'] =  $ciObj->db
            ->order_by(static::class_display_column())
            ->get(static::class_schema_name() . '.' . static::class_table_name())
            ->result(get_called_class());

        //filtros
        $users = array();
        $statuses = array();
        $functions = array();
        $process_results = array();

        //recorro para separar los filtros
        foreach ($data['result'] as $value) {
            $users[] = $value->user_id;
            $functions[] = $value->function_id;
            $process_results[] = $value->process_result_id;
            $statuses[] = $value->status;
        }

        //busco cada tabla
        //les hago un unique a los array
        if (count($users)) $ciObj->db->where_in('users.id', array_unique($users));
        $new_filters['users'] = User::all();

        if (count($functions)) $ciObj->db->where_in('functions.id', array_unique($functions));
        $new_filters['functions'] = Function_creator::all_permitted();

        if (count($process_results)) $ciObj->db->where_in('process_results.id', array_unique($process_results));
        $new_filters['process_results'] = Process_Result::all_permitted();

        $new_filters['statuses'] = array_unique($statuses);

        $data['filters'] = $new_filters;

        return $data;
    }

    public static function all_permitted()
    {
        $CI = get_instance();

        if (!in_array($CI->user->id, User::$_SuperUsers)) {
            $CI->db->join('users', 'users.id = process_functions.user_id');
            $CI->db->where('organization_id', $CI->user->organization_id);
        }

        return parent::all_permitted();
    }

    public static function get_versions()
    {
        $CI = get_instance();

        $where = "";
        if ($CI->user->id > 0) {
            $where = "WHERE organization_id = " . $CI->user->organization_id;
        }

        $query = "
            SELECT DISTINCT versions.id, string_agg(a.name, ' / ') || ' / ' || versions.name as name
              FROM process_functions 
              JOIN process_results ON process_results.id = process_functions.process_result_id
              JOIN versions ON versions.id = process_results.version_id
              JOIN clients ON clients.id = process_results.client_id
              JOIN LATERAL (
                WITH recursive prj AS (
                    SELECT p1.* FROM projects p1 WHERE p1.id = versions.project_id
                    UNION ALL
                    SELECT p2.* FROM projects p2 JOIN prj ON prj.parent_id = p2.id
                )
                SELECT * FROM prj
              ) a ON true
            $where
            GROUP BY process_functions.id, process_results.id, versions.id
        ";

        return $CI->db->query($query)->result();
    }

    public static function process_for_version($version_id)
    {
        $CI = get_instance();

        if ($version_id) {
            $CI->db->select("process_functions.*");
            $CI->db->join("process_results", "process_results.id = process_functions.process_result_id");
            $CI->db->where("version_id", $version_id);
        }

        return static::all_permitted();
    }

    public static function GetReport()
    {
        $CI = get_instance();

        return $CI->db->query('
            SELECT
                process_functions.id,
                process_functions.process_result_id,
                process_functions.status,
                process_functions.name,
                process_functions.start_process_at,
                process_functions.end_process_at,
                date_trunc(\'second\', COALESCE(process_functions.end_process_at, NOW()) - process_functions.start_process_at) as time,
                process_results."name" result_f1_name,
                "functions"."name" function_name,
                users."name" user_name,
                maps.name map_name,
                count_f1.count f1_rows,
                count_dates.count dates_selected,
                count_f1.count * count_dates.count data_estimates
            FROM process_functions
            CROSS JOIN LATERAL(
                SELECT count(*) FROM result_focus1 WHERE result_focus1.process_id = process_functions.process_result_id AND COALESCE(result_focus1.sel_user, result_focus1.sel_rule)
            ) count_f1
            CROSS JOIN LATERAL(
                SELECT count(*) FROM date_by_process_f2 WHERE date_by_process_f2.process_f2_id = process_functions.id
            ) count_dates
            LEFT JOIN "functions" ON process_functions.function_id = "functions".id
            LEFT JOIN users ON process_functions.user_id = users.id
            LEFT JOIN process_results ON process_functions.process_result_id = process_results.id
            LEFT JOIN maps ON process_functions.map_id = maps.id
            ORDER BY id DESC
        ')->result();
    }
}
