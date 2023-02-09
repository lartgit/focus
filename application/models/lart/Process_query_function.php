<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 * @author Yuri Zoolander 2016
 * @package Focus
 */
class Process_Query_Function extends R2_DbObject
{

    /**  Variables Static de Configuración del Model */
    protected static $_table_name = 'process_query_functions';
    protected static $_display_name = 'Consulta de Funciones';
    protected static $_plural_name = 'Consulta de Funciones';

    /** Variables Públicas del Model */
    public $status;
    public $user_id;
    public $start_process_at;
    public $end_process_at;
    public $description;
    public $procces_run;
    public $pixel_id;
    public $region_id;
    public $client_id;
    public $project_id;
    public $version_id;
    public $farm_id;
    public $group_name;
    public $field_id;
    public $use_concrete_id;
    public $date;
    public $date_from;
    public $date_to;
    public $group_field;
    public $group_month;
    public $aggregate_function;
    public $function_id;
    public $filter_description;

    /** Construct */
    public function __construct()
    {
        parent::__construct();

        $this->user_id = $this->session->userdata('userid');
    }

    public static function new_from_array($asociativeArray = array())
    {
        $new_instance = parent::new_from_array($asociativeArray);

        $new_instance->region_id = implode(",", isset($asociativeArray["region_id"]) ? $asociativeArray["region_id"] : array());
        $new_instance->client_id = implode(",", isset($asociativeArray["client_id"]) ? $asociativeArray["client_id"] : array());
        $new_instance->project_id = implode(",", isset($asociativeArray["project_id"]) ? $asociativeArray["project_id"] : array());
        $new_instance->version_id = implode(",", isset($asociativeArray["version_id"]) ? $asociativeArray["version_id"] : array());
        $new_instance->farm_id = implode(",", isset($asociativeArray["farm_id"]) ? $asociativeArray["farm_id"] : array());
        $new_instance->group_name = implode(",", isset($asociativeArray["group_name"]) ? $asociativeArray["group_name"] : array());
        $new_instance->field_id = implode(",", isset($asociativeArray["field_id"]) ? $asociativeArray["field_id"] : array());
        $new_instance->use_concrete_id = implode(",", isset($asociativeArray["use_concrete_id"]) ? $asociativeArray["use_concrete_id"] : array());
        $new_instance->function_id = implode(",", isset($asociativeArray["function_id"]) ? $asociativeArray["function_id"] : array());
        // var_dump(json_encode($asociativeArray), json_encode($new_instance));exit;

        //usuario de la session
        if (!isset($new_instance->user_id))
            $new_instance->user_id = get_instance()->user->id;
        //el status los creo como a procesar
        if (!isset($new_instance->status))
            $new_instance->status = 'pending';

        return $new_instance;
    }

    public static function get_index_data()
    {
        $ciObj = &get_instance();

        $ciObj->db->select(static::class_schema_name() . '.' . static::class_table_name() . '.*');
        $ciObj->db->select('users.name as user');
        // $ciObj->db->select("pi.centroid_x || ',' || pi.centroid_y as pixel_center");
        // $ciObj->db->select("string_agg(distinct fa.name || '(' || fa.id || ')', ',') as farms_name");
        // $ciObj->db->select("string_agg(distinct re.name || '(' || re.id || ')', ',') as regions_name");
        // $ciObj->db->select("string_agg(distinct cl.name || '(' || cl.id || ')', ',') as clients_name");
        // $ciObj->db->select("string_agg(distinct pr.name || '(' || pr.id || ')', ',') as projects_name");
        // $ciObj->db->select("string_agg(distinct ve.name || '(' || ve.id || ')', ',') as versions_name");
        // $ciObj->db->select("string_agg(distinct fi.name || '(' || fi.id || ')', ',') as fields_name");
        // $ciObj->db->select("string_agg(distinct uc.name || '(' || uc.id || ')', ',') as use_concretes_name");
        $ciObj->db->select("date_trunc('second', COALESCE(process_query_functions.end_process_at, NOW()) - process_query_functions.start_process_at) as time", false);

        // $ciObj->db->join('pixel pi', 'pi.id = pixel_id', "left");
        $ciObj->db->join('users', 'users.id = user_id', "left");
        // $ciObj->db->join('farms fa', 'fa.id::text = ANY(string_to_array(process_query_functions.farm_id, \',\'::text))', "left", false);
        // $ciObj->db->join('regions re', 're.id::text = ANY(string_to_array(process_query_functions.region_id, \',\'::text))', "left", false);
        // $ciObj->db->join('clients cl', 'cl.id::text = ANY(string_to_array(process_query_functions.client_id, \',\'::text))', "left", false);
        // $ciObj->db->join('projects pr', 'pr.id::text = ANY(string_to_array(process_query_functions.project_id, \',\'::text))', "left", false);
        // $ciObj->db->join('versions ve', 've.id::text = ANY(string_to_array(process_query_functions.version_id, \',\'::text))', "left", false);
        // $ciObj->db->join('fields fi', 'fi.id::text = ANY(string_to_array(process_query_functions.field_id, \',\'::text))', "left", false);
        // $ciObj->db->join('use_concretes uc', 'uc.id::text = ANY(string_to_array(process_query_functions.use_concrete_id, \',\'::text))', "left", false);
        // $ciObj->db->group_by('process_query_functions.id, users.id, pi.id');

        if ($ciObj->user->organization_id > 0) {
            $ciObj->db->where('organization_id', $ciObj->user->organization_id);
        }

        $ciObj->db->order_by(static::class_display_column());
        //var_dump($ciObj->db->get_compiled_select("process_query_functions pqf"));exit;
        $data['result'] = $ciObj->db->get(static::class_schema_name() . '.' . static::class_table_name())
            ->result(get_called_class());

        return $data;
    }

    public static function all_permitted()
    {
        $CI = get_instance();

        if (!in_array($CI->user->id, User::$_SuperUsers)) {
            $CI->db->join('users', 'users.id = process_query_functions.user_id');
            $CI->db->where('organization_id', $CI->user->organization_id);
        }

        return parent::all_permitted();
    }

    public function get_file_name()
    {
        $user_name = $this->db
            ->select("name")
            ->join("process_query_functions", "process_query_functions.user_id = users.id")
            ->where("process_query_functions.id", $this->id)
            ->get("users")
            ->row()->name;
        $created_at = DateTime::createFromFormat("Y-m-d H:i:s.u", $this->created_at);
        $file_name = $this->id . "_" . str_replace(" ", "_", $user_name) . "_" . $created_at->format("Ymd_His") . ".csv";
        return $file_name;
    }

    /**
     * Valida la instancia llenando $this->errors con los errores encontrados
     *
     */
    protected function validate()
    {
        if (
            !$this->region_id && !$this->pixel_id && !$this->client_id && !$this->client_id && !$this->project_id &&
            !$this->version_id && !$this->farm_id && !$this->group_name && !$this->field_id && !$this->use_concrete_id
        ) {
            $this->errors("Se necesita al menos un filtro espacial");
        }

        if (!$this->date && !$this->date_from && !$this->date_to) {
            $this->errors("Se necesita al menos un filtro temporal");
        }

        if ($this->date && ($this->date_from || $this->date_to)) {
            $this->errors("El filtro <b>Fecha puntual</b> y los filtros <b>Desde</b> y <b>Hasta</b> son excluyentes");
        }

        if ($this->date_from && $this->date_to && $this->date_from > $this->date_to) {
            $this->errors("El filtro Desde no puede ser mayor a Hasta");
        }

        if ($this->pixel_id) {
            $pixel = Pixel::find($this->pixel_id);
            if (!$pixel) {
                $this->errors("El pixel seleccionado no existe");
            }
        }

        return parent::validate();
    }

    public static function get_process_count($filters)
    {
        $CI = get_instance();

        if (isset($filters["pixel_id"]) && $filters["pixel_id"] != "") {
            $CI->db->where("rf1.pixel_id", $filters["pixel_id"]);
        }
        if (isset($filters["region_id"]) && $filters["region_id"] != "") {
            $CI->db->where_in("re.id", $filters["region_id"]);
        }
        if (isset($filters["client_id"]) && $filters["client_id"] != "") {
            $CI->db->where_in("clients.id", $filters["client_id"]);
        }
        if (isset($filters["project_id"]) && $filters["project_id"] != "") {
            $CI->db->where_in("projects.id", $filters["project_id"]);
        }
        if (isset($filters["version_id"]) && $filters["version_id"] != "") {
            $CI->db->where_in("v.id", $filters["version_id"]);
        }
        if (isset($filters["farm_id"]) && $filters["farm_id"] != "") {
            $CI->db->where_in("fa.id", $filters["farm_id"]);
        }
        if (isset($filters["group_name"]) && $filters["group_name"] != "") {
            $groups = [];
            foreach ($filters["group_name"] as $group) {
                list($farm_id, $group_name) = explode("/", $group);
                $groups[] = $group_name;
            }
            $CI->db->where_in("fi.group_name", $groups);
        }
        if (isset($filters["field_id"]) && $filters["field_id"] != "") {
            $CI->db->where_in("fi.id", $filters["field_id"]);
        }
        if (isset($filters["use_concrete_id"]) && $filters["use_concrete_id"] != "") {
            $CI->db->where_in("rf1.use_concrete_id", $filters["use_concrete_id"]);
        }
        if (isset($filters["function_id"]) && $filters["function_id"] != "") {
            $CI->db->where_in("pf.function_id", $filters["function_id"]);
        }
        if (isset($filters["date"]) && $filters["date"] != "") {
            $CI->db->where("dbpf2.date::timestamp", "'$filters[date]'", false);
        }
        if (isset($filters["date_from"]) && isset($filters["date_to"]) && $filters["date_from"] != "" && $filters["date_to"] != "") {
            $CI->db->where("dbpf2.date::timestamp <@ tsrange('" . $filters["date_from"] . "'::timestamp, '" . $filters["date_to"] . "'::timestamp, '[]')", null, false);
        }

        $qry = $CI->db
            ->distinct()
            ->select("pf.id")
            ->join("date_by_process_f2 dbpf2", "dbpf2.process_f2_id = pf.id")
            ->join("regions re", "re.map_id = pf.map_id")
            ->join("process_results pr", "pr.id = pf.process_result_id")
            ->join("versions v", "v.id = pr.version_id", "left")
            ->join("farms fa", "v.id = fa.version_id", "left")
            ->join("fields fi", "fa.id = fi.farm_id AND tsrange(fi.date_from, fi.date_to) @> dbpf2.\"date\"::timestamp", "left")
            ->join("projects", "projects.id = v.project_id", "left")
            ->join("clients", "clients.id = projects.client_id", "left")
            ->join("result_focus1 rf1", "rf1.farm_id = fa.id AND fi.id = rf1.field_id", "left");
        //var_dump($CI->db->get_compiled_select("process_functions pf"));exit;

        return count($qry->get("process_functions pf")->result());
    }

    protected function before_save()
    {
        $this->filter_description = $this->get_filter_description();
        return parent::before_save();
    }

    function get_filter_description()
    {
        $ret = "";

        if (isset($this->pixel_id) && $this->pixel_id != "") {
            $qry = $this->db->query("SELECT pi.centroid_x || ',' || pi.centroid_y description FROM pixel pi where id = $this->pixel_id")->row();

            $ret .= "<b>Pixel</b> " . $qry->description . " ($this->pixel_id)<br/>";
        }

        if (isset($this->region_id) && $this->region_id != "") $ret .= "<b>Regiones</b>: " . $this->get_names("regions", $this->region_id) . "<br/>";
        if (isset($this->use_concrete_id) && $this->use_concrete_id != "") $ret .= "<b>Usos Concreto</b>: " . $this->get_names("use_concretes", $this->use_concrete_id) . "<br/>";
        if (isset($this->client_id) && $this->client_id != "") $ret .= "<b>Clientes</b>: " . $this->get_names("clients", $this->client_id) . "<br/>";
        if (isset($this->project_id) && $this->project_id != "") $ret .= "<b>Proyectos</b>: " . $this->get_names("projects", $this->project_id) . "<br/>";
        if (isset($this->version_id) && $this->version_id != "") $ret .= "<b>Versiones</b>: " . $this->get_names("versions", $this->version_id) . "<br/>";
        if (isset($this->farm_id) && $this->farm_id != "") $ret .= "<b>Campos</b>: " . $this->get_names("farms", $this->farm_id) . "<br/>";
        if (isset($this->groups) && $this->group != "") $ret .= "<b>Grupos</b>: $this->group<br/>";
        if (isset($this->field_id) && $this->field_id != "") $ret .= "<b>Lotes</b>: " . $this->get_names("fields", $this->field_id) . "<br/>";
        if (isset($this->function_id) && $this->function_id != "") $ret .= "<b>Funciones</b>: " . $this->get_names("functions", $this->function_id) . "<br/>";

        $dateStr = "";


        if (isset($this->date) && $this->date != "") {
            $dt = DateTime::createFromFormat("Y-m-d", $this->date);
            if(!$dt) $dt = DateTime::createFromFormat("Y-m-d H:i:s", $this->date);
            if ($dt) $dateStr .= $dt->format("d-m-Y");
        }
        if (isset($this->date_from) && $this->date_from != "") {
            $dt = DateTime::createFromFormat("Y-m-d H:i:s", $this->date_from);
            if(!$dt) $dt = DateTime::createFromFormat("Y-m-d H:i:s", $this->date_from);
            if ($dt) $dateStr .= $dt->format("d-m-Y");
        }
        if (isset($this->date_to) && $this->date_to != "") {
            $dt = DateTime::createFromFormat("Y-m-d", $this->date_to);
            if(!$dt) $dt = DateTime::createFromFormat("Y-m-d H:i:s", $this->date_to);
            if ($dt) $dateStr .= " - " . $dt->format("d-m-Y");
        }
        if ($dateStr) $ret .= "<b>Fecha</b>: $dateStr";

        $group = [];
        if ($this->group_month) {
            $group[] = "Mes";
        }
        if ($this->group_field) {
            $group[] = "Lote(" . $this->aggregate_function . ")";
        }
        if (count($group) != 0) {
            $ret .= "<br><b>Agrupacion:</b>: " . join(" - ", $group);
        }

        return $ret;
    }

    private function get_names($table, $ids)
    {
        $qry = $this->db->query("SELECT name FROM $table WHERE id in ($ids);");
        return join(", ", array_map(function ($x) {
            return $x->name;
        }, $qry->result()));
    }
}
