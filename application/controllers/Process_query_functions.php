<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 *    Controller de Functions
 * 
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class Process_Query_Functions extends Entity_Admin
{

    /** Construct * */
    public function __construct()
    {
        parent::__construct();
        $this->upload = FALSE;
        $this->managed_class = 'process_query_function';

        //$this->url_save_function = $this->url_process_query_functions . '/save/';
        //urls complementarias
        $this->url_download_function = $this->url_functions . '/download_function';
        $this->url_show_process_focus_1 = $this->url_results . '/show_result/';
        $this->url_download_log = $this->url_process_query_functions . '/download_log/';
        $this->url_download_results = $this->url_process_query_functions . '/download_results';

        //ajax
        $this->url_ajax_datatables = $this->url_process_query_functions . '/index_datatable';

        #Cargo el modelo de procesos genericos
        #Form builder
        $this->load->helper('r2_formbuilder');

        #URLS procesos.
        $this->url_new = $this->url_process_query_functions . '/new_process/';

        #ULR entidad que administro
        $this->url_index = $this->url_process_query_functions . '/index';
        $this->url_delete_function = $this->url_process_query_functions . '/delete';
        $this->url_edit_function = $this->url_process_query_functions . '/edit';
        $this->url_back = $this->url_process_query_functions;
        $this->url_action = $this->url_process_query_functions . '/save/';
        $this->url_show_log = $this->url_process_query_functions . '/download_log';



        //views      
        $this->_view_list = 'process_query_functions/index';
        $this->_form_view = 'process_query_functions/form';
        $this->_delete_view = 'entities/confirm_delete';
        $this->rasters_groups = Raster_group::all();
        // Permisions
        /* $this->user_can_add = $this->user->can_add($this->managed_class);
          $this->user_can_edit = $this->user->can_edit(FALSE);
          $this->user_can_delete = $this->user->can_delete($this->managed_class);
          $this->user_can_send_pass = $this->user->can_send_pass($this->managed_class); */
    }

    /* ------------------------------------------------------------ */
    /* ---------- Public Functions  ------------------------------- */
    /* ------------------------------------------------------------ */

    /**
     * Una nueva instancia de los que voy a Subir
     * @param
     */
    public function index($success = null)
    {
        $this->url_report = site_url(array('process_functions', 'get_process_report'));

        $class = $this->managed_class;

        $this->url_back = NULL;

        //para el cartel de success!
        if ($success !== FALSE) {
            switch ($success) {
                case "1":
                    $this->success[] = 'Función Guardada con éxito';
                    break;
                case "2":
                    $this->success[] = 'Función Eliminada con éxito';
                    break;
                default:
                    break;
            }
        }
        $this->load_view_with_layout($this->_view_list);
    }

    public function index_datatable()
    {
        $class = $this->managed_class;

        $data = $class::get_index_data();

        $this->instances = $data['result'];

        foreach ($this->instances as $value) {
            $value->date_str = "";
            if (isset($value->date)) {
                $value->date_str = DateTime::createFromFormat("Y-m-d H:i:s", $value->date)->format("d-m-Y");
            }
            if (isset($value->date_from)) {
                $value->date_str = DateTime::createFromFormat("Y-m-d H:i:s", $value->date_from)->format("d-m-Y");
            }
            if (isset($value->date_to)) {
                $value->date_str .= " - " . DateTime::createFromFormat("Y-m-d H:i:s", $value->date_to)->format("d-m-Y");
            }

            $groups = explode(",", $value->group_name);
            $value->group = implode(",", array_map(function ($a) {
                $parts = explode("/", $a);
                if (isset($parts[1])) return $parts[1];
                return "";
            }, $groups));

            $value->created_at_str = DateTime::createFromFormat("Y-m-d H:i:s.u", $value->created_at)->format("d-m-Y H:i:s");

            $this->db->where("process_query_function_id", $value->id);
            $logs = $this->db->get("log.process_query_function_logs")->result();
            $value->has_logs = count($logs) != 0;
            $value->file_exists = file_exists($this->config->item("function_query_tmp_dir") . $value->get_file_name());
        }

        $this->load->view('process_query_functions/index_datatable', (array) $this);
    }

    public function query()
    {
        $this->load_view_with_layout("process_query_functions/query");
    }

    public function update_filter_description($id = null)
    {
        if (!$id) {
            $instances = Process_Query_Function::all();
            foreach ($instances as $value) {
                $value->save();
            }
        } else {
            $instance = Process_Query_Function::find($id);
            $instance->save();
        }
    }

    public function new_process()
    {
        if (!$this->user_can_add)
            redirect($this->index());
        $class = $this->managed_class;
        $this->instance = new Process_Query_Function();
        $this->instance->map_id = array();

        $this->farms = Farm::all_permitted();
        $this->maps = Map::all_permitted();
        $this->clients = Client::all_permitted();
        $this->functions = Function_creator::all_permitted();
        $this->use_concretes = Use_Concret::all_permitted();

        $this->load_view_with_layout($this->_form_view);
    }

    public function regions($map_id = false)
    {
        if (!$map_id) {
            echo "[]";
            return;
        }
        $this->db->select("regions.id, regions.name || ' (' || regions.id || ')' as name", false);
        $this->db->where_in("map_id", explode("_", $map_id));
        echo json_encode(Region::all_permitted());
    }

    public function projects($client_id = false)
    {
        if (!$client_id) {
            echo "[]";
            return;
        }
        $this->db->select("clients.id, clients.name || ' (' || clients.id || ')' as name", false);
        $this->db->where_in("client_id", explode("_", $client_id));
        echo json_encode(Project::all_permitted());
    }

    public function versions($project_id = false)
    {
        if (!$project_id) {
            echo "[]";
            return;
        }
        $this->db->select("versions.id, versions.name || ' (' || versions.id || ')' as name", false);
        $this->db->where_in("project_id", explode("_", $project_id));
        echo json_encode(Version::all_permitted());
    }

    public function farms($version_id = false)
    {
        if (!$version_id) {
            echo "[]";
            return;
        }
        $this->db->select("farms.id, farms.name || ' (' || farms.id || ')' as name", false);
        $this->db->where_in("version_id", explode("_", $version_id));
        echo json_encode(Farm::all_permitted());
    }

    public function groups($farm_id = false)
    {
        if (!$farm_id) {
            echo "[]";
            return;
        }
        $this->db
            ->where_in("farm_id", explode("_", $farm_id))
            ->distinct()
            ->select("farm_id || '/' || group_name as id, group_name ||' (' || farm_id || ')' as name", false);
        echo json_encode(Field::all_permitted());
    }

    public function fields()
    {
        $ids = $this->input->get("ids");
        if (!$ids) {
            echo "[]";
            return;
        }

        $farms_groups = explode('_', $ids);
        foreach ($farms_groups as $value) {
            list($farm_id, $group_name) = explode('/', $value);
            $this->db->or_where("(farm_id = $farm_id and group_name = '$group_name')", null, false);
        }

        $this->db
            ->distinct()
            ->select("fields.id, name ||' (' || fields.id || ')' as name", false);
        echo json_encode(Field::all_permitted());
    }

    /**
     * Graba los cambios en la instancia.
     */
    public function save()
    {
        $class = $this->managed_class;
        $this->instance = $class::new_from_array($this->input->post());

        $tmp = DateTime::createFromFormat("d-m-Y", $this->instance->date);
        $this->instance->date = $tmp ? $tmp->format("Y-m-d") : NULL;
        $tmp = DateTime::createFromFormat("d-m-Y", $this->instance->date_from);
        $this->instance->date_from = $tmp ? $tmp->format("Y-m-d") : NULL;
        $tmp = DateTime::createFromFormat("d-m-Y", $this->instance->date_to);
        $this->instance->date_to = $tmp ? $tmp->format("Y-m-d") : NULL;

        $this->instance->map_id = array();
        if ($this->input->post("region_id")) {
            $r = Region::where(array("id in" => "(" . join(",", $this->input->post("region_id")) . ")"), false);
            $this->instance->map_id = array_map(function ($r) {
                return $r->map_id;
            }, $r);
        }

        if ($this->instance->is_valid()) {
            $this->instance->save();
            redirect($this->url_index . '/1');
        } else {
            $this->farms = Farm::all_permitted();
            $this->maps = Map::all_permitted();
            $this->clients = Client::all_permitted();
            $this->functions = Function_creator::all_permitted();
            $this->use_concretes = Use_Concret::all_permitted();
            $this->errors = $this->instance->errors();

            $this->load_view_with_layout($this->_form_view);
        }
    }

    function remove($id)
    {
        $instance = Process_Query_Function::find($id);
        $file_name = $instance->get_file_name();
        $file_path = $this->config->item("function_query_tmp_dir") . $file_name;

        if ($instance->destroy()) {
            @unlink($file_path);
        }

        echo "true";
    }

    public function get_log($id)
    {
        $logs = $this->db->query("
            SELECT *
            FROM log.process_query_function_logs
            WHERE process_query_function_id = $id
            ORDER BY created_at asc")->result();
        echo json_encode($logs);
    }

    public function download_results($id)
    {
        $item = Process_Query_Function::find($id);
        if (!$item)
            redirect($this->url_index);

        $file_name = $item->get_file_name();
        $file_path = $this->config->item("function_query_tmp_dir") . $file_name;

        if (!file_exists($file_path)) return;

        header("Content-Type: application/octet-stream");
        header("Content-Disposition: attachment; filename=$file_name");
        header("Expires: 0");
        header("Cache-Control: must-revalidate");
        header("Pragma: public");
        header("Content-Length: " . filesize($file_path));
        $this->file_get_contents_chunked($file_path, 1024 * 1024, function ($str_array, &$handle, $i) {
            echo $str_array;
        });
    }

    public function calculate_process()
    {
        set_time_limit(30);
        $filters = $this->input->post();
        echo Process_query_function::get_process_count($filters);
    }

    public function get_image_dates()
    {
        $image_type = $this->input->get('image_type_id');
        $date_from = $this->input->get('date_from');
        $date_to = $this->input->get('date_to');

        if (!$image_type || empty($image_type)) return;

        $ret = Imagen_Type::get_dates_for($image_type, $date_from, $date_to);

        echo json_encode(array_map(function ($elem) {
            return $elem->image_date;
        }, $ret), JSON_NUMERIC_CHECK);
    }

    public function get_process_report()
    {
        $report = Process_function::GetReport();

        if (count($report) == 0) return;

        $date = date('YmdHis', time() - 3 * 60 * 60); // -3 hours

        header("Content-Type: application/csv");
        header("Content-Disposition: attachment; filename=Reporte_Proceso_Funciones_$date.csv");
        header("Pragma: no-cache");

        $columns = array_keys((array)$report[0]);

        foreach ($columns as $column) {
            echo '"' . $column . '"';

            if ($column !== end($columns)) {
                echo ",";
            }
        }

        echo "\n";

        foreach ($report as $row) {
            foreach ($columns as $column) {
                echo '"' . $row->$column . '"';

                if ($column !== end($columns)) {
                    echo ",";
                } else {
                    echo "\n";
                }
            }
        }
    }
}
