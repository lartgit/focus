<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 *    Controller que maneja la Carga De lotes
 * @author ARamirez
 * @package Focus
 */
class Process_Fields extends Focus_base_controller {

    /** Construct * */
    public function __construct() {
        parent::__construct();
        $this->upload = FALSE;
        $this->managed_class = 'field';

        $this->url_action = $this->url_process_fields . '/save/';
        $this->url_back = $this->url_process_fields;

        $this->url_ajax_read_dir = $this->url_process_fields . '/files_in_folder/';
        $this->url_ajax_version_project = $this->url_process_fields . '/versions_by_project/';
        $this->url_ajax_project_client = $this->url_process_fields . '/projects_by_client';

        //views
        $this->_view_upload = 'uploads/upload_files_fields';
        $this->_delete_view = 'entities/confirm_delete';
        $this->_log_view = 'entities/list_import_log';

        $this->process_class = 'process_field';
        #Cargo el modelo de procesos genericos
        $this->upFile = New R2_Upload_File();
        #Form builder
        $this->load->helper('r2_formbuilder');

        #URLS procesos.
        $this->url_new = $this->url_process_fields . '/new_process_field/';
        $this->url_save_process = $this->url_process_fields . '/save_process/';
        $this->url_delete_process = $this->url_process_fields . '/delete_process';
        $this->url_show_process = $this->url_process_fields . '/show_process';
        $this->url_show_import_log = $this->url_process_fields . '/show_import_log';
        
        // Permisions
        $this->user_can_add = $this->user->can_add($this->managed_class);
        $this->user_can_edit = $this->user->can_edit($this->managed_class);
        $this->user_can_delete = $this->user->can_delete($this->managed_class);
        $this->user_can_send_pass = $this->user->can_send_pass($this->managed_class);

        $this->load->model('lart/Project');
        $data = Project::all_permitted();
        $this->obj_tree = $this->Project->recursivit_projects($data);

        $this->templates = array(1 => 'FormatoMiniAgri.dbf',2 => 'FormatoCrea.dbf');
        $this->url_download_shp_format = $this->url_process_fields . '/download_shp_format/';
    }

    /* ------------------------------------------------------------ */
    /* ---------- Public Functions  ------------------------------- */
    /* ------------------------------------------------------------ */

    /**
     * Una nueva instancia de los que voy a Subir
     * @param
     */
    public function index($success = null) {
        $this->url_back = NULL;
        $this->dir = $this->upFile->read_upload_dir();
        $class = $this->process_class;

        $this->instances = Process_Field::all_permitted();
        foreach ($this->instances as $instance) {
            if (!isset($instance->description)) {
                $instance->description = 'Proceso aún no iniciado';
            }
        }

        //para el cartel de success!
        if ($success !== FALSE) {
            switch ($success) {
                case "1": $this->success[] = 'Proceso Cargado con éxito';
                    break;
                case "2": $this->success[] = 'Proceso Eliminado con éxito';
                    break;
                default:
                    break;
            }
        }

        $this->load_view_with_layout('entities/list_process_field');
    }

    /**
     * @param $segmento identifica si el alta es
     * MINIAGRI | CREA
     * 
     * MINIAGRI = 1
     * CREA = 2
     */
    public function new_process_field($segmento) {
        if (!$this->user_can_add)
            redirect($this->index());
        	
        $this->segmento_title = "";


        $this->segmento = $segmento;
        $this->instance = new Process_Field;
        $this->form_content = form_content($this->instance);
        $this->load_view_with_layout($this->_view_upload);
    }

    /*
     * Metodo uploads files
     * Description
     */

    public function files_in_folder() {

        $folder = $this->input->post('folder');

        if ($folder) {
            $files = $this->upFile->read_upload_folder($folder);
        } else {
            $files = $this->upFile->read_upload_folder();
        }

        echo json_encode($files);
    }

    /**
     * Graba los cambios en la instancia.
     */
    public function save_process() {

        $class = $this->process_class;

        $data = $this->input->post();

        $segmento = $data['import_from'];
        
        if ($segmento == "1")
        	$this->segmento_title = "MINIAGRI";
        else
        	$this->segmento_title = "CREA";

        $this->segmento = $segmento;
        
        
        $this->instance = $class::new_from_array($data);

        if ($this->instance->is_valid()) {
            //obtengo los farms asociados a la version
            $farms = Farm::where(array('version_id' => $data['version_id']));
            $cant_farms = count($farms);

            if (!isset($data['is_validate']) && $cant_farms > 0) {
                //Si la version tiene farms asociadas muestro pantalla de confirmación
                $obj = Version::find($data['version_id']);
                $this->form_data = $this->input->post();

                $this->instance->notice = 'Se borraran ' . $cant_farms . ' Farms de la versión ' . $obj->name . ' junto con sus lotes y datos asociados. ¿Está seguro?';
                $this->load_view_with_layout('entities/confirm_delete_fields');
            } else if ($cant_farms === 0 || $data['is_validate']) {
                //si el usuario confirma el borrado, se procede a borrar las farms y todos los lotes asociados, y se guarda el nuevo proceso.
                $this->delete($data['version_id']);
                $this->instance->save();
                redirect($this->url_process_fields . '/index/1');
            }
        } else {
            $this->form_content = form_content($this->instance);
            $this->load_view_with_layout($this->_view_upload);
        }
    }

    /**
     * Edita una entidades
     * @param $class type <entity_class>
     */
    public function edit_process($id) {
        if (!$this->id_is_valid($id)) {
            echo $this->error_code;
            return;
        }
        $class = $this->process_class;
        $this->instance = $class::find($id);
        $this->form_content = form_content($this->instance);
        $this->load_view_with_layout('uploads/upload_files_fields');
    }

    public function delete($id) {
        
        
        $farms = Farm::where(array('version_id' => $id));

        foreach ($farms as $farm) {
            $farm->destroy();
        }

    }

    public function versions_by_project($id) {
        if(!is_numeric($id)) echo json_encode(array());
        else {
            $version = Version::where(array('project_id' => $id));
            // $all_concretes = array();
            // foreach ($concretes as $concret) {
            //     $all_concretes[] = Use_concret::find($concret->id);
            // }
            echo json_encode($version);
        }
    }

    public function projects_by_client() {
        $client_id = $this->input->post('client');

        $projects = Project::where(array('client_id' => $client_id));

        echo json_encode($projects);
    }

    /**
     * Muestra una entidad existente
     * @param $class type <entity_class>
     */
    public function show_process($id, $success = FALSE) {
        if (!$this->id_is_valid($id)) {
            echo $this->error_code;
            return;
        }

        $class = $this->process_class;

        $this->show = TRUE;
        $this->instance = $class::find($id);
        $this->form_content = form_content($this->instance, $this->show);

        //para el cartel de success!
        if ($success !== FALSE) {
            switch ($success) {
                case "1": $this->success[] = 'Cambios Guardados con éxito';
                    break;
                default:
                    break;
            }
        }

        $this->load_view_with_layout($this->_view_upload);
    }

    /**
     * Elimina una entidades
     * @param $class type <entity_class>
     */
    public function delete_process($id) {
        if (!$this->id_is_valid($id)) {
            echo $this->error_code;
            return;
        }

        $class = $this->process_class;
        $this->instance = $class::find($id);

        if (!$this->instance)
            redirect($this->url_index);

        if (!$_POST) {
            $this->instance->notice = lang('¿ Está seguro que desea borrar a la entidad :') . ' ' . $this->instance->id . ' ?';
        } else {
            if ($this->instance->is_deleteable()) {

                if ($this->instance->destroy())
                    redirect($this->url_process_fields . '/index/2');
                else
                    $this->instance->notice = lang('Ocurrió un error al borrar');
            } else
                $this->instance->notice = lang("No es posible borrar el proceso");
        }
        $this->load_view_with_layout($this->_delete_view);
    }

    public function download_shp_format($format)
    {
        #Instancio el helper para enviar el archivo.
        $this->load->helper('download');
        $data = file_get_contents($this->config->item('upload_path').$this->templates[$format]);
        // var_dump($data);exit();
        force_download($this->templates[$format],$data); 
    } 

    public function show_import_log($id){

        $this->instances = Log_import_field::where(array('process_id' => $id));
        $this->load_view_with_layout($this->_log_view);

    }

}
