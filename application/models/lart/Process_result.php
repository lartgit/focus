<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class Process_Result extends R2_DbObject
{

    /**  Variables Static de Configuración del Model */
    protected static $_table_name = 'process_results';
    protected static $_display_name = 'relacion_para_exportacion ';
    protected static $_plural_name = 'procesos_de_relaciones_para_exportacion';

    /** Variables Públicas del Model */
    public $name;
    public $user_id;
    public $version_id;
    public $pixel_selection_rules_id;
    public $start_process_at;
    public $end_process_at;
    public $description;
    public $client_id;
    public $imagen_type_id;
    public $procces_run;
    public $set_id;

    //falta la Regla de asignación de usos

    /** Variables private */
    //private $farms;

    /** Construct */
    public function __construct()
    {
        parent::__construct();

        $this->user_id = $this->session->userdata('userid');
    }

    public function display_value()
    {
        return $this->name;
    }

    public function non_editable_variables()
    {
        $vars = array_merge(parent::non_editable_variables(), array('user_id', 'start_process_at', 'end_process_at', 'description', 'active', 'procces_run'));

        return $vars;
    }

    public function related_with()
    {
        $ps = Process_function::where(array('process_result_id' => $this->id));
        return array($ps);
    }

    public static function references_class()
    {
        return array(
            'version_id' => 'Version',
            'pixel_selection_rules_id' => 'Pixel_selection_rule',
            'client_id' => 'Client',
            'imagen_type_id' => 'Imagen_type',
            'set_id' => 'Pixel_set',
        );
    }

    public static function new_from_array($asociativeArray = array())
    {
        $new_instance = parent::new_from_array($asociativeArray);

        return $new_instance;
    }


    public function validate()
    {

        //$old_date = $this->where(Array('set_id'=>$this->set_id,'date'=>  $this->date));

        //$tmp = static::find_named($this->name);

        //Caso nuevo reg
        if (!$this->pixel_selection_rules_id) {
            //$this->errors[] = "Estos campos no pueden estar vacios";
            $this->errors("Regla de Selección de Píxeles no pueden estar vacio");
        }

        if (!$this->name) {
            //$this->errors[] = "Estos campos no pueden estar vacios";
            $this->errors("Nombre no pueden estar vacio");
        }

        if (!$this->version_id) {
            //$this->errors[] = "Estos campos no pueden estar vacios";
            $this->errors("Version no pueden estar vacio");
        }
        return parent::validate();
    }

    public function required_variables()
    {
        return array_merge(parent::required_variables(), array('name', 'version_id', 'pixel_selection_rules_id', 'set_id', 'client_id', 'imagen_type_id'));
    }

    public function farms()
    {
        if (!isset($this->farms))
            $this->farms = Farm::where(array('version_id' => $this->id));

        return $this->farms;
    }

    public function pixel_set_name()
    {
        if (!isset($this->pixel_set))
            $this->pixel_set = Pixel_Set::where(array('id' => $this->set_id));
        return $this->pixel_set[0]->name;
    }

    public function is_deleteable()
    {
        // $proces_run = $this->where(array('id' => $this->id));

        // if ($proces_run[0]->procces_run == 't' ) {
        // 	return false;
        // }

        return true;
    }

    /*
	* processed_results()
	* devuelve las relaciones de exportaci{on creadas por el usuario que ya fueron corridas y tienen fecha en la que fueron finalizadas 
	*/
    public static function processed_results_list()
    {
        //$this->processed_results = Process_Result::where(Array('end_process_at !=' => null));

        //return $this->processed_results;
        $CI = get_instance();

        $CI->db->select('process_results.*');
        $CI->db->select('pixel_selection_rules.name as px_rule_name');
        $CI->db->select('versions.name as version_name');
        $CI->db->select('imagen_types.name as imagen_type_name', false);
        $CI->db->select('pixel_sets.name as pixel_set_name', false);
        $CI->db->select('projects.name as proy_name');
        $CI->db->select('clients.name as cli_name');
        $CI->db->select('(select count(*) from results where process_id = process_results.id) as row_count');
        $CI->db->where("end_process_at is not ", "NULL", false);
        $CI->db->join('pixel_selection_rules', 'pixel_selection_rules.id = process_results.pixel_selection_rules_id');
        $CI->db->join('versions', 'versions.id = process_results.version_id');
        $CI->db->join('projects', 'projects.id = versions.project_id');
        $CI->db->join('clients', 'clients.id = process_results.client_id');

        if ($CI->user->id > 0)
            $CI->db->where('clients.organization_id', $CI->user->organization_id);

        $CI->db->join('imagen_types', 'imagen_types.id = process_results.imagen_type_id');
        $CI->db->join('pixel_sets', 'pixel_sets.id = process_results.set_id');
        $CI->db->group_by('process_results.id, pixel_selection_rules.id, versions.id, projects.id, clients.id, imagen_types.id, pixel_sets.id');
        $res = $CI->db->get('process_results')->result();

        return $res;
    }

    public function find_version_by_projects($client_id)
    {
        return $this->db->query("select projects.name as proyname, versions.id, versions.name from clients
			join projects on clients.id = projects.client_id
			join versions on projects.id = versions.project_id
			where clients.id = $client_id")->result();
    }

    public static function all_permitted()
    {
        $CI = get_instance();

        if (!in_array($CI->user->id, User::$_SuperUsers)) {
            $CI->db->join('users', 'users.id = user_id');
            $CI->db->where('organization_id', $CI->user->organization_id);
        }

        return parent::all_permitted();
    }
}
