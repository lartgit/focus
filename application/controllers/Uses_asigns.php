<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 *    Controller que maneja la Carga De lotess
 * @author ARamirez
 * @package Focus
 */
class Uses_asigns extends Focus_base_controller {

    /** Construct * */
    public function __construct() {
        parent::__construct();

        $this->upload1 = FALSE;
        $this->managed_class = 'import_data';

        $this->url_save_process = $this->url_process_uses . '/save_process/';

        $this->url_action = $this->url_process_uses . '/save/';


        $this->process_class = 'process_pixel';


        $this->url_ajax_read_dir = $this->url_process_fields . '/files_in_folder/';
        $this->url_ajax_version_project = $this->url_process_fields . '/versions_by_project/';
        $this->url_ajax_project_client = $this->url_process_fields . '/projects_by_client';

        #Cargo el modelo de procesos genericos
        // $this->upFile = New R2_Upload_File();
        #Form builder
        $this->load->helper('r2_formbuilder');

        #URLS procesos.
        $this->url_new = $this->url_process_uses . '/new_process/';

        #ULR entidad que administro
        $this->url_index = $this->url_process_uses . '/index';
        $this->url_show_process = $this->url_process_uses . '/show_process';
        $this->url_delete_process = $this->url_process_uses . '/delete_process';
        $this->url_show_log = $this->url_process_uses . '/show_import_log/';
        $this->url_back = $this->url_process_uses;

        //views
        $this->_view_upload = 'uploads/upload_uses';
        $this->_view_list = 'entities/list_process_uses';
        $this->_delete_view = 'entities/confirm_delete';
        
        $this->_log_view = 'entities/list_import_uses_log';


        $this->url_download_shp_format = $this->url_process_uses . '/download_shp_format/';
        
        $this->success = R2_session::flashdata('messages');
        $this->errors = R2_session::flashdata('err_messages');


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
        // $class = $this->process_class;

        // $this->url_back = NULL;
        // $this->dir = $this->upFile->read_upload_dir();

        $this->db->order_by('start_process_at IS NULL', 'DESC', FALSE);
        $this->db->order_by('start_process_at', 'DESC');
        $this->instances = Import_data::all_permitted();
        // //para el cartel de success!
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

        $this->instance = new Import_data;
        $this->form_content = form_content($this->instance);
        // $this->projects = Project::all_active();
        // $this->clients = Client::all_active();

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
    	
    	$config['upload_path']   = get_instance()->config->item('upload_path');
        $config['allowed_types'] = '*';    	
        $config['file_name']     = uniqid(true);
		// Import_data::do_import('usos');
        
        $this->load->library('upload', $config);
        if ( ! $this->upload->do_upload('user_file')) {
	        $this->instance = new Import_data;
	        $this->form_content = form_content($this->instance);
	        $this->errors = array('Debe seleccionar un archivo.');
        	$this->load_view_with_layout($this->_view_upload);
        } else {
            $upload_data = $this->upload->data();

            $data = $this->input->post();

	        $instance = Import_data::new_from_array(array(
	        	'client_id' => $data['client_id'],
	        	'version_id' => $data['version_id'],
	        	'project_id' => $data['project_id'],
	            'path' => $upload_data['full_path'],
	            'original_name' => $upload_data['client_name']
	        ));

        	$instance->save();

           	R2_session::set_flashdata('messages', array('Archivo importado con éxito.'));

            redirect($this->url_index);
        }
    }

    function import_parameters() {
        $config['upload_path'] = '/tmp';

        $config['allowed_types'] = '*';
        $config['file_name'] = uniqid(true);

        $this->load->library('upload', $config);
        if ( ! $this->upload->do_upload('user_file')) {
            R2_session::set_flashdata('err_messages', array(trim($this->upload->display_errors("", "\n"))));
        } else {
            $data = $this->upload->data();
            if(($ret = Parameter::import($data['full_path'])) === true)
                R2_session::set_flashdata('messages', array('Archivo importado con éxito.'));
            else if(is_array($ret))
                R2_session::set_flashdata('err_messages', $ret);
            else
                R2_session::set_flashdata('err_messages', array($ret));

            unlink($data['full_path']);
        }

        $this->get_data = $this->input->get();
        if(isset($this->get_data['map_id']) && isset($this->get_data['region_id'])) {
            redirect($this->url_index."?map_id=".$this->get_data['map_id']."&region_id=".$this->get_data['region_id']);
        } else {
            redirect($this->url_index);
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

    public function versions_by_project($id) {
        if(!is_numeric($id)) echo json_encode(array());
        else {
            $version = Version::where(array('project_id' => $id));
            echo json_encode($version);
        }
    }

    public function projects_by_client() {
        $client_id = $this->input->post('client');

        $projects = Project::where(array('client_id' => $client_id));

        echo json_encode($projects);
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

        $class = "Import_data";
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

    /**
     * Descarga de archivo template csv
     */
    public function download_shp_format()
    {
        #Instancio el helper para enviar el archivo.
        $this->load->helper('download');
        $data = file_get_contents('./focus/uploads/NuevoFormato.csv');
        // var_dump($data);exit();
        force_download('NuevoFormato.csv',$data);
    }


    public function show_import_log($id){

        $this->instances = Import_data::find($id);
		$this->uses_logs = json_decode($this->instances->comments);
		// var_dump($this->uses_logs);exit;
        $this->load_view_with_layout($this->_log_view);
    }    

}
