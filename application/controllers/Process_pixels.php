<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 *    Controller que maneja la Carga De lotess
 * @author ARamirez
 * @package Focus
 */
class Process_Pixels extends Focus_base_controller {

    /** Construct * */
    public function __construct() {
        parent::__construct();
        $this->upload = FALSE;
        $this->managed_class = 'pixel';

        $this->url_save_process = $this->url_process_pixels . '/save_process/';

        $this->url_action = $this->url_process_pixels . '/save/';

        $this->url_ajax_read_dir = $this->url_process_pixels . '/files_in_folder/';

        $this->process_class = 'process_pixel';

        #Cargo el modelo de procesos genericos
        $this->upFile = New R2_Upload_File();
        #Form builder
        $this->load->helper('r2_formbuilder');

        #URLS procesos.
        $this->url_new = $this->url_process_pixels . '/new_process/';

        #ULR entidad que administro
        $this->url_index = $this->url_process_pixels . '/index';
        $this->url_show_process = $this->url_process_pixels . '/show_process';
        $this->url_delete_process = $this->url_process_pixels . '/delete_process';
        $this->url_back = $this->url_process_pixels;

        //views
        $this->_view_upload = 'uploads/upload_files_pixel';
        $this->_view_list = 'entities/list_process_pixels';
        $this->_delete_view = 'entities/confirm_delete';


        // Permisions
        $this->user_can_add = $this->user->can_add($this->process_class);
        $this->user_can_edit = $this->user->can_edit(FALSE);
        $this->user_can_delete = $this->user->can_delete($this->process_class);
        $this->user_can_send_pass = $this->user->can_send_pass($this->process_class);
    }

    /* ------------------------------------------------------------ */
    /* ---------- Public Functions  ------------------------------- */
    /* ------------------------------------------------------------ */

    /**
     * Una nueva instancia de los que voy a Subir
     * @param
     */
    public function index($success = null) {
        $class = $this->process_class;

        $this->url_back = NULL;
        $this->dir = $this->upFile->read_upload_dir();


        $this->instances = $class::all_permitted();
        //para el cartel de success!
        if ($success !== FALSE) {
            switch ($success) {
                case "1": $this->success[] = 'Proceso Guardado con éxito';
                    break;
                case "2": $this->success[] = 'Proceso Eliminado con éxito';
                    break;
                default:
                    break;
            }
        }
        $this->load_view_with_layout($this->_view_list);
    }

    public function new_process() {
        if (!$this->user_can_add)
            redirect($this->index());

        $this->instance = new Process_Pixel;
        $this->sets = Pixel_set::all();
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


        $this->instance = $class::new_from_array($this->input->post());

        if ($this->instance->is_valid()) {
            $this->instance->save();
            redirect($this->url_index . '/1');
        } else {
            $this->form_content = form_content($this->instance);
            $this->load_view_with_layout($this->_view_upload);
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

        $this->load_view_with_layout('uploads/upload_files');
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
                    redirect($this->url_index . '/2');
                else
                    $this->instance->notice = lang('Ocurrió un error al borrar');
            } else
                $this->instance->notice = lang("No es posible borrar el proceso");
        }
        $this->load_view_with_layout($this->_delete_view);
    }

}
