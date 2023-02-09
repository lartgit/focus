<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class Result extends R2_DbObject
{

    /**  Variables Static de Configuración del Model */
    protected static $_table_name = 'results';
    protected static $_display_name = 'Relación para exportación ';
    protected static $_plural_name = 'Procesos de Relaciones para exportación';

    /** Variables Públicas del Model */
    public $name;
    public $user_id;
    public $version_id;
    public $set_id;
    public $pixel_selection_rules_id;
    public $start_process_at;
    public $end_process_at;
    public $description;

    //falta la Regla de asignación de usos

    /** Variables private */
    //private $farms;

    /** Construct */
    public function __construct()
    {
        parent::__construct();

        $this->user_id = $this->session->userdata('userid');
    }

    public function farms()
    {
        if (!isset($this->farms))
            $this->farms = Farm::where(array('version_id' => $this->id));

        return $this->farms;
    }

    public function related_with()
    {
        return array($this->farms());
    }

    public function is_deleteable()
    {
        return true;
    }

    /*
     * processed_results()
     * devuelve las relaciones de exportaci{on creadas por el usuario que ya fueron corridas y tienen fecha en la que fueron finalizadas
     */

    public function processed_results_list()
    {
        //$this->processed_results = Process_Result::where(Array('end_process_at !=' => null));
        //return $this->processed_results;
        $CI = get_instance();

        $this->db->select('process_results.*, pixel_selection_rules.name as px_rule_name, versions.name as version_name, imagen_types.name as imagen_type_name');
        $this->db->where("end_process_at = " . NULL);
        $this->db->join('pixel_selection_rules', 'pixel_selection_rules.id = process_results.pixel_selection_rules_id');
        $this->db->join('versions', 'versions.id = process_results.version_id');
        $this->db->join('imagen_types', 'imagen_types.id = process_results.imagen_type_id');
        $this->db->join('pixel_sets', 'pixel_sets.imagen_type_id = imagen_types.id');

        if ($CI->user->id > 0) {
            $this->db->join('projects', 'projects.id = versions.project_id');
            $this->db->join('clients', 'clients.id = process_results.client_id');
            $this->db->where('clients.organization_id', $CI->user->organization_id);
        }

        $res = $this->db->get('process_results')->result();

        return $res;
    }

    /*
     * donwload_processed_results()
     * devuelve
     * Si se modifica aca modificar en Results::show_result($process_id)
     */
    public function processed_results($process_id)
    {
        $ret = array();

        $query = $this->db->query("
            SELECT sel_user, result_id, sel_rule, latitud, longitud,
                   intersect_idx * 100 as intersect_idx, field_name,
                   field_date_from as field_from, field_date_to as field_to,
                   farm_name, version_name, project_name, client_name,
                   user_name, use_concrete_name as use_name, uses_date_from as use_from,
                   uses_date_to as use_to
            FROM result_focus1
            WHERE process_id = $process_id;
        ");

        return $query->result();
    }

    /*
     * results_to_view()
     * devuelve
     */
    public function results_to_view($process_id)
    {
        $ret = array();

        $query = $this->db->query("
          SELECT
            f.id as field_id,
            f.name as field_name,
            fa.id as farm_id,
            fa.name as farm_name,
            count(*) as count_pixel,
            (SELECT count(*) FROM declarations join declarations_concrete on declaration_id = declarations.id where f.id = field_id) as count_uses
          FROM results r
          LEFT JOIN fields f ON r.field_id = f.id
          LEFT JOIN farms fa ON f.farm_id = fa.id
          where r.process_id = $process_id
          group by f.id,f.name,fa.id,fa.name;");

        $ret['data'] = $query->result();

        $query = $this->db->query("
        SELECT
            view_process_results.version_name,
            view_process_results.project_name,
            view_process_results.client_name,
            view_process_results.user_name
          FROM view_process_results
          where view_process_results.id = $process_id;");

        $ret['info'] = $query->result()[0];

        return $ret;
    }

    public function datatable_to_shp($process_id, $folder)
    {

        $folder = trim($folder, '/');
        $name_process = Process_Result::find($process_id)->name;
        // var_dump($name_process);exit();
        $output = array();
        $return = '';
        $file_name = $this->user->name . uniqid('-') . '_' . $name_process . "_result";

        #Traemos los datos del archivo Config y Database para correr el proceso en el pgsql2shp
        $path = $this->config->item('upload_path') . $folder . '/';
        $dbname = $this->db->database;
        $dbusername = $this->db->username;
        $dbpassword = $this->db->password;
        $dbhost = $this->db->hostname;

        #Ejecutamos el comando pgsql2shp
        exec("cd '$path' && pgsql2shp -u '$dbusername' -h '$dbhost' -P '$dbpassword' -p 5432 -f '$file_name' '$dbname' \"SELECT pixel_id, sel_user, result_id, sel_rule, latitud, longitud, intersect_idx * 100 as intersect_idx, field_name, field_date_from as field_from, field_date_to as field_to, farm_name, version_name, project_name, client_name, user_name, use_concrete_name as use_name, uses_date_from as use_from, uses_date_to as use_to, the_geom FROM result_focus1 WHERE process_id = $process_id\" > /tmp/err 2>&1", $output, $return);

        #Retorno true o false y el error lo manejo en la view, para no pasar la salida standar de la terminal
        if ($return == 0) {
            return true;
        } else
            return false;
    }

    public function reimport_shp($file)
    {
        $script = BASEPATH . '../scripts/importacion_resultados/import_results.py';
        $file = $this->config->item('upload_path') . $file;
        $dbname = $this->db->database;
        $dbusername = $this->db->username;
        $dbpassword = $this->db->password;
        $dbhost = $this->db->hostname;

        #Ejecutamos el comando pgsql2shp
        exec("python3 '$script' '$dbname' '$dbusername' '$dbpassword' '$dbhost' '$file' > /tmp/err2 2>&1", $output, $return);

        if ($return == 0)
            return true;
        else
            return false;
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
