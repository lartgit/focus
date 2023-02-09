<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 *    Controller que maneja la Carga De lotess
 * @author ARamirez
 * @package Focus
 */
class Process_Regions extends Focus_base_controller {

    public $list_view;
    public $list_view_process;
    public $user_can_add;
    public $user_can_delete;
    public $user_can_edit;
    public $_delete_view = 'entities/confirm_delete';
    public $delete_view = 'entities/confirm_delete';
    public $upFile;

    /** Construct * */
    public function __construct() {
        parent::__construct();

        $this->upFile = New R2_Upload_File();
        // Form builder
        $this->load->helper('r2_formbuilder');

        $this->upload = FALSE;
        $this->managed_class = 'region';
        $this->managed_process = 'process_region';
        $this->url_save = $this->url_process_regions . '/save/';
        $this->url_ajax_read_dir = $this->url_process_regions . '/files_in_folder/';
        $this->list_view = '/entities/list_regions';
        $this->list_view_process = '/entities/list_process_regions';

        $this->user_can_add = TRUE;
        $this->user_can_edit = TRUE;
        $this->user_can_delete = TRUE;

        $this->url_edit = $this->url_process_regions . '/edit';
        $this->url_save = $this->url_process_regions . '/save';
        $this->url_delete = $this->url_process_regions . '/delete';
        $this->url_show = $this->url_process_regions . '/show';

        $this->url_save_process = $this->url_process_regions . '/save_process';
        $this->url_delete_process = $this->url_process_regions . '/delete_process';
        $this->url_show_process = $this->url_process_regions . '/show_process';

        $this->url_index = $this->url_process_regions . '/index';
        $this->url_new = $this->url_process_regions . '/new_instances';
        $this->url_back = $this->url_index;

        $this->url_action = $this->url_save;

        $this->url_process_list = $this->url_process_regions . '/process_list';
        $this->url_back_to_process = $this->url_process_list;
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
        $class = $this->managed_class;
        $this->instances = $class::all_permitted();

        //para el cartel de success!
        if ($success !== FALSE) {
            switch ($success) {
                case "1": $this->success[] = 'Cambios Guardados con éxito';
                    break;
                default:
                    break;
            }
        }
        $this->load_view_with_layout($this->list_view);
    }

    public function new_instances() {
        //$this->url_back = true;
        $this->dir = $this->upFile->read_upload_dir();
        $this->upload = FALSE;
        // $class = 'Process_Field';
        $this->instance = new Process_Region;
        // $this->instances = Process_Field::all_permitted();
        //$this->form_content = form_content($this->instance);
        $this->load_view_with_layout('uploads/upload_files_regions');
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
    public function save() {

        $class = $this->managed_class;


        $this->instance = $class::new_from_array($this->input->post());

        if ($this->instance->is_valid()) {
            $this->instance->save();
            $this->show($this->instance->id, TRUE);
        } else {
            $this->form_content = form_content($this->instance);
            $this->load_view_with_layout('entities/form');
        }
    }

    /**
     * Muestra una entidad existente
     * @param $class type <entity_class>
     */
    public function show($id, $success = FALSE) {
        if (!$this->id_is_valid($id)) {
            echo $this->error_code;
            return;
        }

        $class = $this->managed_class;

        $this->show = TRUE;
        $this->instance = $class::find($id);
        $this->form_content = form_content($this->instance, TRUE);

        //para el cartel de success!
        if ($success !== FALSE) {
            switch ($success) {
                case "1": $this->success[] = 'Cambios Guardados con éxito';
                    break;
                default:
                    break;
            }
        }

        $this->load_view_with_layout('entities/form');
    }

    /**
     * Edita una entidades
     * @param $class type <entity_class>
     */
    public function edit($id) {
        if (!$this->id_is_valid($id)) {
            echo $this->error_code;
            return;
        }
        $class = $this->managed_class;
        $this->instance = $class::find($id);
        $this->form_content = form_content($this->instance);
        $this->load_view_with_layout('entities/form');
    }

    public function delete($id) {

        if (!$this->id_is_valid($id)) {
            echo $this->error_code;
            return;
        }

        $class = $this->managed_class;
        $this->instance = $class::find($id);

        if (!$this->instance) {
            redirect($this->url_index);
        } else if (!$_POST) {
            //array_de_objetos relacionados

            $this->related_instances = $this->instance->related_with();

            $this->instance->notice = '¿ Está seguro que desea borrar a la entidad : ' . $this->instance->name . ' ?';
        } else {
            //if ($this->instance->is_deleteable()) {

            if ($this->instance->destroy()) {
                redirect($this->url_index . '/1');
            } else {
                $this->instance->notice = 'Ocurrió un error al borrar';
            }
            //} else {
            //    $this->instance->notice = "No es posible borrar la entidad: " . $this->instance->name;
            //}
        }

        $this->load_view_with_layout($this->delete_view_for($class));
    }

    //Proccess
    /**
     * Graba los cambios en la instancia.
     */
    public function save_process() {

        $class = $this->managed_process;


        $this->instance = $class::new_from_array($this->input->post());

        if ($this->instance->is_valid()) {
            $this->instance->save();
            redirect($this->url_process_list . '/1');
        } else {
            $this->form_content = form_content($this->instance);
            $this->load_view_with_layout('uploads/upload_files_regions');
        }
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

        $class = $this->managed_process;

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

        $this->load_view_with_layout('uploads/upload_files');
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
        $class = $this->managed_process;
        $this->instance = $class::find($id);
        $this->form_content = form_content($this->instance);
        $this->load_view_with_layout('uploads/upload_files_regions');
    }

    public function process_list($success = null) {

        $class = $this->managed_process;
        $this->instances = $class::all_permitted();

        //Elimino path

        foreach ($this->instances as $row) {
//            $path = explode('/',$row->path);
//            $file_name = $path[count($path) - 1];
            $row->path = str_replace(get_instance()->config->item('upload_path'), '', $row->path);
            if (!isset($row->description)) {
                $row->description = "Proceso aún no iniciado";
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

        $this->load_view_with_layout($this->list_view_process);
    }

    /**
     * Elimina una entidad process
     * @param $class type <entity_class>
     */
    public function delete_process($id) {
        if (!$this->id_is_valid($id)) {
            echo $this->error_code;
            return;
        }

        $class = $this->managed_process;
        $this->instance = $class::find($id);

        if (!$this->instance)
            redirect($this->url_index);

        if (!$_POST) {
            $this->instance->notice = '¿ Está seguro que desea borrar a la entidad : ' . $this->instance->id . ' ?';
        } else {
            if ($this->instance->is_deleteable()) {

                if ($this->instance->destroy())
                    redirect($this->url_process_list . '/2');
                else
                    $this->instance->notice = 'Ocurrió un error al borrar';
            } else
                $this->instance->notice = "No es posible borrar el proceso";
        }
        $this->load_view_with_layout($this->_delete_view);
    }

}
