<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 *    Controller de Clients
 *
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class Fields extends Entity_Admin {

    public $list_view = 'entities/list_fields';

    public function __construct()
    {
        // Le mandamos al controller padre el nombre del controller y de la clase que administra
        parent::__construct('fields', 'Field');

        $this->url_new = $this->_url_site . '/process_fields/new_process_field/';
        $this->url_action = $this->url . '/filtered_fields_by/';

        $this->url_ajax_read_dir = $this->url . '/files_in_folder/';

        $this->url_ajax_dt_to_shp = $this->url . '/datatable_to_shp/';

        #Cargo el modelo de procesos genericos
        $this->upFile = New R2_Upload_File();

        #Cargo el modelo de la clase
        $this->model = new $this->managed_class;
    }

    public function index($success = FALSE)
    {
        $this->url_back = NULL;

        //$this->farms = Farm::all_permitted();
        $this->farms = Farm::all_permitted_filtered(null);

        //var_dump($this->farms);
        $this->farms_id = array();

        $class = $this->managed_class;
        
        $this->instances = $this->model->all_limited();

        //para el cartel de success!
        if ($success !== FALSE) {
            switch ($success) {
                case "1": $this->success[] = 'Cambios Guardados con éxito';
                    break;
                case "2": $this->success[] = 'Registro eliminado con éxito';
                    break;
                default:
                    break;
            }
        }

        $this->load_view_with_layout($this->list_view_for($class));

    }

    public function filtered_fields_by()
    {
        $this->date = $this->input->post('date');
        $this->farms_id = $this->input->post('farm_id');
        //si viene vacio lo convierto en array()
        if(!$this->farms_id)
            $this->farms_id = array();
        $this->farms = Farm::all_permitted_filtered(null);
        $this->instances = $this->model->filter_fields_by($this->date, $this->farms_id);

        if (!empty($this->instances)) {
            $this->load_view_with_layout($this->list_view_for('field'));
            return;
        } else {
            $this->error_string = true;
            $this->errors[] = 'No existen datos para este periodo';
            $this->load_view_with_layout($this->list_view_for('field'));
            return;
        }
    }

    public function datatable_to_shp()
    {
        $date = $this->input->post('date');
        $folder = $this->input->post('folder');
        $farms = $this->input->post('farm_id');

        if ($date !== FALSE && $date !== '')
            $date = date('Y-m-d H:i:s', strtotime($date));

        $ret = $this->model->datatable_to_shp($date, $folder, $farms);

        if ($ret) {
            echo 0;
        } else {
            echo 1;
        }
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

    public function use_download()
    {
        $this->clients = Client::all_active();
        $this->load_view_with_layout("fields/use_download");
    }

    public function download()
    {
        $version_id = $this->input->post('version_id');

        if(!$version_id) {
            echo 'La version es requerida';
            return;
        }

        $version = Version::find($version_id);
        $project = Project::find($version->project_id);
        $client = Client::find($project->client_id);

        $qry = Field::get_use_query($version_id);

        header("Content-Type: text/plain");
        header("Content-Disposition: attachment;filename=".$client->name."_".$project->name."_".$version->name.".csv");

        $df = fopen("php://output", 'w');
        fputs($df, $bom =( chr(0xEF) . chr(0xBB) . chr(0xBF) ));

        fputcsv($df, array(/*'CLIENT', 'PROJECT', 'VERSION',*/ 'GRUPO', 'CAMPO', 'LOTE', 'FECHA', 'USODESDE', 'USOHASTA', 'USO'), ';');
        while ($row = $qry->unbuffered_row())
        {
            fputcsv($df, array(/*$row->client, $row->project, $row->version,*/ $row->grupo, $row->campo, $row->lote, $row->fecha, $row->usodesde, $row->usohasta, $row->uso), ';');
        }
        fclose($df);
    }
}
