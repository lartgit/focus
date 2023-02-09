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
class Process_Functions extends Entity_Admin
{

    /** Construct * */
    public function __construct()
    {
        parent::__construct();
        $this->upload = FALSE;
        $this->managed_class = 'process_function';

        //$this->url_save_function = $this->url_process_functions . '/save/';
        //urls complementarias
        $this->url_download_function = $this->url_functions . '/download_function';
        $this->url_show_process_focus_1 = $this->url_results . '/show_result/';
        $this->url_download_log = $this->url_process_functions . '/download_log/';
        $this->url_download_results = $this->url_process_functions . '/download_results/';

        //ajax
        $this->url_ajax_datatables = $this->url_process_functions . '/index_datatable';

        #Cargo el modelo de procesos genericos
        #Form builder
        $this->load->helper('r2_formbuilder');

        #URLS procesos.
        $this->url_new = $this->url_process_functions . '/new_process/';

        #ULR entidad que administro
        $this->url_index = $this->url_process_functions . '/index';
        $this->url_delete_function = $this->url_process_functions . '/delete';
        $this->url_edit_function = $this->url_process_functions . '/edit';
        $this->url_back = $this->url_process_functions;
        $this->url_action = $this->url_process_functions . '/save/';
        $this->url_show_log = $this->url_process_functions . '/download_log';



        //views      
        $this->_view_list = 'process/list_process_function';
        $this->_form_view = 'process/form_process_function';
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

        $data = $class::get_index_data();
        $this->filters = $data['filters'];

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
        $user_ids = $this->input->post('user_filter');
        $process_ids = $this->input->post('process_filter');
        $function_ids = $this->input->post('function_filter');
        $statuses = $this->input->post('status_filter');

        $filters = array();
        if ($user_ids)
            $filters['user_id'] = $user_ids;
        if ($process_ids)
            $filters['process_result_id'] = $process_ids;
        if ($function_ids)
            $filters['function_id'] = $function_ids;
        if ($statuses)
            $filters['status'] = $statuses;

        /* if (!$user_ids || count($user_ids) === 0)
          $this->instances = array();
          else {
          $class = $this->managed_class;
          $this->instances = $class::index(null, null, $client_ids);
          } */

        $class = $this->managed_class;

        $this->db->order_by("id", "desc");
        $data = $class::get_index_data($filters);

        $this->instances = $data['result'];

        foreach ($this->instances as $i) {
            $tmp = json_decode($i->description);
            if ($i->description && is_null($tmp)) {
                $i->description_html = "<b>$i->description</b>";
            } else {
                $url = site_url(["process_functions", "get_progress_for_process", "$i->id"]);
                $i->description_html = <<<HTML
                    <div class="meter" id="$i->id">
                        <div></div>
                        <span style="width:0"></span>
                    </div>
                    <script>
                        (function() {
                            var interval = setInterval(() => {
                                $.ajax("$url", {
                                    "dataType": "json"
                                }).then((res) => {
                                    $("#status_$i->id").html(res["status"]);
                                    $("#time_$i->id").html("<b>"+(res["process_time"]?res["process_time"]:"")+"</b>");
                                    
                                    if(!res["description"]) return;
                                    if(typeof(res["description"]) === 'string') {
                                        $("#$i->id").parent().html("<b>"+res["description"]+"</b>");
                                        clearInterval(interval);
                                        return;
                                    }
                                    $("#$i->id > span").animate({
                                        "width": Math.min(res["description"].done / res["description"].total * 100, 100) + '%'
                                    })
                                    if(res["description"].total == 0) $("#$i->id > div").text("0%");
                                    else {
                                        $("#$i->id > div").text(Math.min(100 * res["description"].done / res["description"].total, 100).toFixed(2) + '%');
                                        $("#$i->id").prop('title', res["description"].done +" / "+ res["description"].total);
                                    }
                                })
                            }, 10000);
                        })();
                    </script>
HTML;
            }
        }

        $this->load->view('process/list_process_function_datatable', (array) $this);
    }

    public function get_progress_for_process($id)
    {
        $this->db->select("*, date_trunc('second', COALESCE(process_functions.end_process_at, NOW()) - process_functions.start_process_at) as time", false);
        $process = Process_Function::find($id);
        $tmp = json_decode($process->description);
        if ($process->description && is_null($tmp)) {
            $tmp = $process->description;
        }

        echo json_encode(array(
            "status" => $process->status,
            "description" => $tmp,
            "process_time" => $process->time
        ));
    }

    public function new_process()
    {
        if (!$this->user_can_add)
            redirect($this->index());
        $class = $this->managed_class;

        $this->get_image_dates_url = site_url(array('process_functions', 'get_image_dates'));
        $this->instance = new $class;
        $this->functions = Function_creator::all_permitted();
        $process_results = new Process_Result;
        $this->process_results = $process_results->processed_results_list();
        $this->image_types = Imagen_Type::all();
        $this->maps = Map::all_permitted();
        $this->form_content = form_content($this->instance);
        $this->load_view_with_layout($this->_form_view);
    }

    /**
     * Graba los cambios en la instancia.
     */
    public function save()
    {

        $class = $this->managed_class;

        $this->instance = $class::new_from_array($this->input->post());
        // var_dump($this->input->post(),$this->instance);exit;

        if ($this->instance->is_valid()) {
            $this->instance->save();
            redirect($this->url_index . '/1');
        } else {
            $this->functions = Function_creator::all_permitted();
            $process_results = new Process_Result;
            $this->get_image_dates_url = site_url(array('process_functions', 'get_image_dates'));
            $this->process_results = $process_results->processed_results_list();
            $this->form_content = form_content($this->instance);
            $this->image_types = Imagen_Type::all();
            $this->maps = Map::all_permitted();
            $this->load_view_with_layout($this->_form_view);
        }
    }

    /**
     * Elimina una entidades
     * @param $class type <entity_class>
     */
    public function delete($id)
    {
        if (!$this->id_is_valid($id)) {
            echo $this->error_code;
            return;
        }

        $class = $this->managed_class;
        $this->instance = $class::find($id);

        if (!$this->instance)
            redirect($this->url_index);

        if (!$_POST) {
            $this->instance->notice = lang('¿ Está seguro que desea borrar a la entidad :') . ' ' . $this->instance->name . ' ?';
        } else {
            if ($this->instance->is_deleteable()) {

                if ($this->instance->destroy())
                    redirect($this->url_index . '/2');
                else
                    $this->instance->notice = lang('Ocurrió un error al borrar');
            } else
                $this->instance->notice = lang("No es posible borrar el proceso");
        }
        $this->load_view_with_layout($this->_delete_view);
    }

    public function download_log($id)
    {
        $logs = Log_Process_Function::where(array('process_function_id' => $id));
        // if (!$logs)
        //     redirect($this->url_index);
        $pf = Process_Function::find($id);
        $glue = "\n";
        $text = $pf->name . $glue;
        $text .= $pf->ts . ' ' . $pf->description . $glue;
        foreach ($logs as $each) {
            $text .= $each->description . $glue;
        }

        $file_name_and_location = $this->config->item('upload_path') . 'log.txt';
        $handle = fopen($file_name_and_location, "w");
        fwrite($handle, $text);
        fclose($handle);

        header('Content-Type: application/octet-stream');
        header('Content-Disposition: attachment; filename=log.txt');
        header('Expires: 0');
        header('Cache-Control: must-revalidate');
        header('Pragma: public');
        header('Content-Length: ' . filesize($file_name_and_location));
        readfile($file_name_and_location);
        exit;
    }

    public function download_results($id)
    {
        //$item = Function_Result::find($id);
        //if (!$item)
            redirect($this->url_index);
        #Instancio el helper para enviar el archivo.
        //$this->load->helper('download');

        //$data = file_get_contents($item->path);
        //force_download($item->name . '.py', $data);
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
