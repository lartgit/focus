<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 *    Controller de Resultados Focus II.
 *    Este controller sera encargado de vizualizar y de obtener los datos para descargar
 * 
 *
 * @author Ariel Ramirez <ariel.ramirez@r2software.net>
 * @package Focus II
 */
class Process_functions_results extends Focus_base_controller {


    public function __construct()
    {
        // Le mandamos al controller padre el nombre del controller y de la clase que administra
        /*Esto es mentira porque si heredo de focus_base_controller*/
        //**-----------------CONTROLLER-----------MODEL-------//
        parent::__construct('Process_functions_results', 'Results_two');

        // $this->url_download = $this->url . '/download';

        $this->success = R2_session::flashdata('messages');
        $this->errors = R2_session::flashdata('err_messages');

        $this->url_get_columns = site_url(array("process_functions_results", "get_columns_for_process"));

        $this->url_download_files = site_url(array("process_functions_results","view"));

        $this->_view_list = 'process/list_process_function_result';

        $this->_view_list_grouped = 'process/list_process_function_result_grouped';

        $this->url_action = $this->url_process_results_two . '/filtered_results_by_process_id/';

        $this->url_ajax_read_dir = site_url(array("process_functions_results","files_in_folder"));

        $this->url_ajax_dt_to_shp = site_url(array("process_functions_results", "export_data_to_shp"));
        
        $this->url_dt_to_xls = site_url(array("process_functions_results", "export_to_csv"));

        $this->url_download_dir = site_url(array("process_functions_results", "download_dir"));
        
          #Cargo el modelo de procesos genericos
        $this->upFile = New R2_Upload_File();
    }

    /**
     * Index de la clase
     */
    public function index($_ = false)
    {
        $this->url_back = NULL;

        $this->get_data = $this->input->get();

        $this->process_id = '';
        $this->version_id = '';
        $this->headers = array();
        $this->aggregates = NULL;

        $this->process = Process_function::all_permitted();
        $this->versions = Process_function::get_versions();

        $this->instances = array();
        if(isset($this->get_data['version_id']) && isset($this->get_data['version_id'])) {
            $this->version_id = $this->get_data['version_id'];
        }

        if(isset($this->get_data['process_id']) && isset($this->get_data['process_id'])) {
            $this->instances = Results_two::get_index_data($this->get_data['process_id']);
            if (!empty($this->instances)) 
                $this->columns = array_keys(get_object_vars($this->instances[0]));
            
            $this->process_id = $this->get_data['process_id'];
            $proc_func = Process_function::find($this->process_id);
            $this->version_id = Process_result::find($proc_func->process_result_id)->version_id;
        }

        $this->load_view_with_layout($this->_view_list);
    }

    public function filtered_results_by_process_id()
    {
        $this->url_back = $this->url_process_results_two;
        $this->process_id = $this->input->post('process_id');
        $this->version_id = $this->input->post('version_id');
        $this->grouped = $this->input->post('grouped');
        $agg = $this->input->post();
        $this->aggregates = array();
        if(isset($agg['aggregates'])) {
            foreach ($agg['aggregates'] as $value) {
                $this->aggregates[$value['key']] = $value['value'];
            }
        }

        // $this->process = Process_function::all();
        $this->process = Process_function::all_permitted();
        $this->versions = Process_function::get_versions();
        
        // Aca elijo que funcion llamar en base a la combinacion de opciones seleccionadas
        $gr_field = !is_null($this->grouped) && in_array('field', $this->grouped);
        $gr_month = !is_null($this->grouped) && in_array('month', $this->grouped);

        if($gr_field && !$gr_month)
            $this->instances = Results_two::filtered_results_by_process_id_field($this->process_id, $this->aggregates);
        else if(!$gr_field && $gr_month)
            $this->instances = Results_two::filtered_results_by_process_id_month($this->process_id);
        else if($gr_field && $gr_month)
            $this->instances = Results_two::filtered_results_by_process_id_month_field($this->process_id);
        else
            $this->instances = Results_two::filtered_results_by_process_id($this->process_id);

        if (!empty($this->instances)) {
            $this->columns = array_keys(get_object_vars($this->instances[0]));
            $this->load_view_with_layout($this->_view_list);
            return;
        } else {
            $this->error_string = true;
            $this->errors[] = 'No existen datos para este proceso';
            $this->load_view_with_layout($this->_view_list);
            return;
        }
    }

    /**
     * Metodo que hace la descarga del archivo a shp
     */
    public function export_data_to_shp()
    {
        
        $agg = $this->input->post();
        $this->aggregates = array();
        if(isset($agg['aggregates'])) {
            foreach ($agg['aggregates'] as $value) {
                $this->aggregates[$value['key']] = $value['value'];
            }
        }
        
        $this->process_id = $this->input->post('process_id');
        $this->grouped = isset($this->aggregates['grouped'])?$this->aggregates['grouped']:null;

        $folder = $this->input->post('folder');

        // Aca elijo que funcion llamar en base a la combinacion de opciones seleccionadas
        $gr_field = !is_null($this->grouped) && in_array('field', $this->grouped);
        $gr_month = !is_null($this->grouped) && in_array('month', $this->grouped);

        if($gr_field && !$gr_month)
            $ret = Results_two::datatable_to_shp_field($this->process_id, $folder, $this->aggregates);        
        else if(!$gr_field && $gr_month)
            $ret = Results_two::datatable_to_shp_month($this->process_id, $folder);
        else if($gr_field && $gr_month)
            $ret = Results_two::datatable_to_shp_month_field($this->process_id, $folder);
        else
            $ret = Results_two::datatable_to_shp($this->process_id, $folder);

        if ($ret)
            echo 0;
        else 
            echo 1;
    }

    public function export_to_csv()
    {
        $agg = $this->input->get();
        $this->aggregates = array();
        if(isset($agg['aggregates'])) {
            foreach ($agg['aggregates'] as $value) {
                $this->aggregates[$value['key']] = $value['value'];
            }
        }

        $this->process_id = $this->input->get('process_id');
        $this->grouped = $this->input->get('grouped');

        $file_name = "Focus2_".date('Y_m_d_H_i_s').".csv.gz";
        $tmpdir = $this->config->item('upload_path') . "results/export";
        $tmpname = $tmpdir . '/' . $file_name;

        // var_dump($tmpdir);exit;
        // Chequeo del dir
        if(!file_exists($tmpdir)) {
            mkdir($tmpdir,0777,true);
            chmod($tmpdir, 0777); // string; incorrecto
        } else if(!is_dir($tmpdir)) {
            error_log('Path is not a directory: ' . $tmpdir);
            echo 'Path is not a directory: ' . $tmpdir;
            exit();
        } else if(!is_writable($tmpdir)) {
            error_log('Output file is not writable: ' . $tmpdir);
            echo 'Output file is not writable: ' . $tmpdir;
            exit();
        }

        // Aca elijo que funcion llamar en base a la combinacion de opciones seleccionadas
        $gr_field = !is_null($this->grouped) && in_array('field', $this->grouped);
        $gr_month = !is_null($this->grouped) && in_array('month', $this->grouped);

        if($gr_field && !$gr_month)
            Results_two::datatable_to_csv_field($this->process_id, $tmpname, $this->aggregates);
        else if(!$gr_field && $gr_month)
            Results_two::datatable_to_csv_month($this->process_id, $tmpname);
        else if($gr_field && $gr_month)
            Results_two::datatable_to_csv_month_field($this->process_id, $tmpname);
        else
            Results_two::datatable_to_csv($this->process_id, $tmpname);

        header('Content-Type: application/csv+gzip');
        header("Content-Disposition: attachement; filename=$file_name;");
        header("Content-Length: " . filesize($tmpname));
        $this->file_get_contents_chunked($tmpname, 1024*1024, function($str_array, &$handle, $i) { echo $str_array; });
        @unlink($tmpname);
    }

    // No la usamos por problemas de tamaño.
    // AR
    public function export_to_excel()
    {
        $process_id = $this->input->get('process_id');
        $head_and_result = Results_two::datatable_to_xls($process_id);
        
        $this->load->library('php_excel');
        $this->php_excel->loadTemplate("assets/templates/template-empty.xlsx");
        $this->php_excel->setActiveSheetIndexByName('datos');

        //cabecera del xls
        $header = array(
            'Fecha',
            'Latitud',
            'Longitud',
            'Intersección',
            'Lote',
            'Lote Desde',
            'Lote Hasta',
            'Campo',
            'Uso',
            'Uso desde',
            'Uso hasta',
        );
        $header = array_merge($header,$head_and_result[0]);

        $datos = array($header);
        $this->php_excel->writeArray($datos, 0, 0);

        // el orden de los campos.
        $order = array(
            'date',
            'latitud',
            'longitud',
            'intersect_idx',
            'field_name',
            'field_date_from',
            'field_date_to',
            'farm_name',
            'use_concrete_name',
            'uses_date_from',
            'uses_date_to',
        );
        $order = array_merge($order, $head_and_result[0] );

        //Escribir datos de un array, desde que fila, desde que columna
        $this->php_excel->writeObjects($head_and_result[1], $order, 1, 0);
        $this->php_excel->save("results.xlsx");
    }

    public function file_get_contents_chunked($file,$chunk_size,$callback)
    {
        try {
            $handle = fopen($file, "r");
            $i = 0;
            while (!feof($handle)) {
                call_user_func_array($callback,array(fread($handle,$chunk_size),&$handle,$i));
                $i++;
            }

            fclose($handle);
        } catch(Exception $e) {
            trigger_error("file_get_contents_chunked::" . $e->getMessage(),E_USER_NOTICE);
            return false;
        }

        return true;
    }

    public function get_columns_for_process()
    {
        $process_id = $this->input->post('process_id');
        if(!$process_id) return;

        $keys = Results_two::get_table_headers($process_id);

        echo json_encode($keys);
    }

    /*
     * Metodo uploads files
     * Description
     */
    public function files_in_folder()
    {
        $folder = $this->input->post('folder');

        if ($folder) {
            $files = $this->upFile->read_upload_folder($folder, false);
        } else {
            $files = $this->upFile->read_upload_folder(NULL, false);
        }

        echo json_encode($files);
    }

    public function view()
    {
        $this->url_back = $this->url_process_results_two;
        $this->current_dir = $this->input->get('current_dir');
        if($this->current_dir) $this->current_dir = urldecode($this->current_dir);
        $this->load_view_with_layout('/shp_csv_export/index');
    }

    public function download_dir()
    {
        set_time_limit(0);

        $this->current_dir = $this->input->get('current_dir');
        if(!$this->current_dir) return;

        $real_path = $this->config->item('upload_path').$this->current_dir;

        $tmp_name = tempnam('/tmp', 'F2DD_');

        if ($handle = opendir($real_path))  
        {
            $zip = new ZipArchive();

            if ($zip->open($tmp_name, ZIPARCHIVE::CREATE)!==TRUE) 
            {
                exit("cannot open <$tmp_name>\n");
            }

            while (false !== ($file = readdir($handle)))
            {
                if(!is_dir($real_path.'/'.$file)) {
                    $zip->addFile($real_path.'/'.$file, $file);
                }
            }

            closedir($handle);
            $zip->close();
        }

        $new_name = str_replace(array(' ', '/'), '_', trim($this->current_dir, '/'));
        if($new_name == "") $new_name = 'root';

        $this->load->helper('download');
        force_download($new_name.'.zip', file_get_contents($tmp_name));

        @unlink($tmp_name);
    }

    public function process_for_version($version_id = NULL) {
        echo json_encode(Process_function::process_for_version($version_id));
    }

}

