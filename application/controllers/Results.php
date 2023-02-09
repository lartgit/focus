<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 *    Controller de Downloads
 *
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class Results extends Focus_base_controller {

    public function __construct()
    {
        parent::__construct();
        //urls
        $this->url_download_process = $this->url_results . '/download_results';
        $this->url_show_process = $this->url_results . '/show_result/';

        $this->url_ajax_read_dir = $this->url_results . '/files_in_folder/';
        $this->url_ajax_read_shp = $this->url_results . '/reimport_shp/';
        $this->url_ajax_dt_to_shp = $this->url_results . '/datatable_to_shp/';

        #Cargo el modelo de procesos genericos
        $this->upFile = New R2_Upload_File();
        //views
        $this->main_view = '/process/proccesed_results';
        $this->show_view = '/process/show_result';
    }

    /**
     * Index de la clase
     */
    public function index($success = FALSE)
    {
        //$this->url_back = NULL;
        // $class = $this->managed_class;
        $this->instances = Process_Result::processed_results_list();

        //para el cartel de success!
        if ($success !== FALSE) {
            switch ($success) {
                case "1": $this->success[] = 'Descarga realizada con éxito';
                    break;
                default:
                    break;
            }
        }
        $this->load_view_with_layout($this->main_view);
    }

    /**
     * Index de la clase
     */
    public function show_result($process_id)
    {
        set_time_limit(0);

        //si el proceso que me viene existe, busco sus resultados
        $this->process_result = Process_Result::find($process_id);
        if ($this->process_result) {
            $this->load->model('lart/Result');

            $file_format = $this->input->post('input_file_format');
            if ($file_format) {
                //función que calcula los resultados
                switch ($file_format) {
                    case $file_format == "xls":
                        $file_name = "Result_".date('Y_m_d_H_i_s').".csv.gz";
                        $tmpdir = $this->config->item('upload_path') . "results/export";
                        $tmpname = $tmpdir . '/' . $file_name;

                        // La query es de Result::processed_results($process_id)
                        $query = "SET TimeZone = 'UTC'; COPY ( 
                            SELECT sel_user, result_id, sel_rule, latitud, longitud,
                                   intersect_idx * 100 as intersect_idx, field_name,
                                   field_date_from as field_from, field_date_to as field_to,
                                   farm_name, version_name, project_name, client_name,
                                   user_name, use_concrete_name as use_name, uses_date_from as use_from,
                                   uses_date_to as use_to
                            FROM result_focus1
                            WHERE process_id = $process_id
                        ) TO PROGRAM 'gzip > $tmpname ; chmod a+rwx $tmpname ; ' WITH CSV HEADER;";
                        $this->db->query($query);

                        header('Content-Type: application/csv+gzip');
                        header("Content-Disposition: attachement; filename=$file_name;");
                        header("Content-Length: " . filesize($tmpname));
                        $this->file_get_contents_chunked($tmpname, 1024*1024, function($str_array, &$handle, $i) { echo $str_array; });
                        @unlink($tmpname);

                        // $this->export_to_excel($this->Result->processed_results($process_id));
                        return;
                        break;
                }
            }

            $this->results = $this->Result->results_to_view($process_id);
            $this->process_id = $process_id;
        }
        //caso de error
        //para el cartel de success!
        /* if ($success !== FALSE) {
          switch ($success) {
          case "1": $this->success[] = 'Descarga realizada con éxito';
          break;
          default:
          break;
          }
          } */
        $this->load_view_with_layout($this->show_view);
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

    public function export_to_excel($data_xls)
    {
        $this->load->library('php_excel');

        $this->php_excel->loadTemplate("assets/templates/template-empty.xlsx");
        $this->php_excel->setActiveSheetIndexByName('datos');

        //cabecera del xls
        $header = array(
            lang('Seleccionado por el usuario'),
            lang('Seleccionado por la regla'),
            lang('Latitud'),
            lang('Longitud'),
            lang('Intersección'),
            lang('Campo'),
            lang('Lote'),
            lang('Lote Desde'),
            lang('Lote Hasta'),
            lang('Version'),
            lang('Proyecto'),
            lang('Cliente'),
            lang('Usuario'),
            lang('Uso'),
            lang('Uso Desde'),
            lang('Uso Hasta'),
            lang('Id Resultado')
        );
        $datos = array($header);
        $this->php_excel->writeArray($datos, 0, 0);

//      el orden de los campos.
        $order = array(
            'sel_user',
            'sel_rule',
            'latitud',
            'longitud',
            'intersect_idx',
            'farm_name',
            'field_name',
            'field_from',
            'field_to',
            'version_name',
            'project_name',
            'client_name',
            'user_name',
            'use_name',
            'use_from',
            'use_to',
            'result_id'
        );
        //Escribir datos de un array, desde que fila, desde que columna
//
        $this->php_excel->writeObjects($data_xls, $order, 1, 0);
//
        $this->php_excel->save("results.xlsx");
    }

    /*
     * Metodo uploads files
     * Description
     */
    public function files_in_folder()
    {
        $folder = $this->input->post('folder');

        if ($folder) {
            $files = $this->upFile->read_upload_folder($folder);
        } else {
            $files = $this->upFile->read_upload_folder();
        }

        echo json_encode($files);
    }

    public function datatable_to_shp()
    {
        $folder = $this->input->post('folder');
        $process_id = $this->input->post('process');
        //si el proceso existe
        if (Process_Result::find($process_id)) {
            $this->load->model('lart/Result');
            $ret = $this->Result->datatable_to_shp($process_id, $folder);
        }

        if ($ret) {
            echo 0;
        } else {
            echo 1;
        }
    }

    public function reimport_shp()
    {
        $file = $this->input->post('file');

        //si el proceso existe
        $this->load->model('lart/Result');
        $ret = $this->Result->reimport_shp($file);

        if ($ret) {
            echo 0;
        } else {
            echo 1;
        }
    }

}
