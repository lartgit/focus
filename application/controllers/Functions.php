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
class Functions extends Entity_Admin {

    /** Construct * */
    public function __construct()
    {
        parent::__construct();
        $this->upload = FALSE;
        $this->managed_class = 'function_creator';

        $this->url_save_function = $this->url_functions . '/save_function/';
        $this->url_get_template = $this->url_functions . '/download_model/';

        $this->url_action = $this->url_functions . '/save/';

        $this->url_ajax_read_dir = $this->url_functions . '/files_in_folder/';

        //$this->process_class = 'process_pixel';
        #Cargo el modelo de procesos genericos
        $this->upFile = New R2_Upload_File();
        #Form builder
        $this->load->helper('r2_formbuilder');

        #URLS procesos.
        $this->url_new = $this->url_functions . '/new_function/';
        $this->url_new_from_basic_template = $this->url_functions . '/new_function_from_template/';

        #ULR entidad que administro
        $this->url_index = $this->url_functions . '/index';
        $this->url_download_function = $this->url_functions . '/download_function';
        $this->url_delete_function = $this->url_functions . '/delete_function';
        $this->url_edit_function = $this->url_functions . '/edit_function';
        $this->url_back = $this->url_functions;

        //views
        $this->_view_upload = 'uploads/upload_functions';
        $this->_view_list = 'entities/list_functions';
        $this->_delete_view = 'entities/confirm_delete';
        $this->_view_create_function = 'function/index';


        $this->url_ajax = $this->url_functions . '/set_python_file_tmp_to_valid';
        $this->url_ajax_python_save = $this->url_functions . '/save_python_valid_python_file';
        $this->url_ajax_get_python_file = $this->url_functions . '/get_python_data';
        $this->url_test_python = $this->url_functions;
        // Esto esta harcoded por el momento pero deberiamos ponerlo en algun lugar d configuracion
        // Ariel
        $this->basic_template_url =  "/var/www/html/scripts/focus2_process/basic_template.py";
        
        $this->var_private_dir = "/var/www/html/scripts/focus2_process/user_fxs/";
        
        // Aca cargamos los errores o mensajes de exito si es que lo hay
        $this->success = R2_session::flashdata('messages');
        $this->errors = R2_session::flashdata('err_messages');

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
        $class = $this->managed_class;

        $this->url_back = NULL;
        $this->dir = $this->upFile->read_upload_dir();
        
        $this->get_data = $this->input->get();
        $this->instances = array();

        if(isset($this->get_data['fx_id'])) {
            $this->url_back = $this->url_functions;     
            $this->function_id = $this->get_data['fx_id'];
            $this->instance = $class::find($this->function_id);
            $this->column_names = explode(",",$this->instance->column_name);
            $this->load_view_with_layout($this->_view_create_function);
            return;
        }

        $this->instances = $class::all_permitted();

        /*************************************
        // ESTO NO VA MAS!!! Malo, caca, fuera!
        // PROHIBIDO!
        // Utilzar R2_sesscion::flashdata()
        **************************************/
        //para el cartel de success!
        // if ($success !== FALSE) {
        //     switch ($success) {
        //         case "1": $this->success[] = 'Función Guardada con éxito';
        //             break;
        //         case "2": $this->success[] = 'Función Eliminada con éxito';
        //             break;
        //         default:
        //             break;
        //     }
        // }

        /*************************************
        // 
        **************************************/        

        $this->load_view_with_layout($this->_view_list);
    }

    public function new_function()
    {
        if (!$this->user_can_add)
            redirect($this->url_index);
        $class = $this->managed_class;

        $this->instance = new $class;
        $this->form_content = form_content($this->instance);
        $this->load_view_with_layout($this->_view_upload);
    }

    /**
     * Methodo description
     * Este metodo crea una nueva funcion desde el template que
     * definimos nosotros como basico
     * Donde tiene los siguientes 3 metodos
     * init
     * execute
     * deinit
     * @author CAR <ariel.ramirez@r2soft>
     * @package Functions.php
     */
    public function new_function_from_template(){
        $this->basic_template_data = file_get_contents($this->basic_template_url);
        $this->load_view_with_layout($this->_view_create_function);
    }


    /*
     * Metodo uploads files
     * Description
     */

    public function files_in_folder()
    {
        $folder = $this->input->post('folder');

        if ($folder) 
            $files = $this->upFile->read_upload_folder($folder);
        else 
            $files = $this->upFile->read_upload_folder();

        echo json_encode($files);
    }

    /**
     * Graba los cambios en la instancia.
     */
    public function save_function()
    {

        $class = $this->managed_class;

        $this->instance = $class::new_from_array($this->input->post());
        if ($this->instance->is_valid()) {
            $this->instance->save();

            $unique_id = uniqid();
            $file  =  $this->var_private_dir . $unique_id . "_" .  $this->instance->name .".py";
            
            $file_data = file_get_contents($this->instance->path);

            if (file_put_contents($file,$file_data) === FALSE) {
                echo "fallo al guardar";
                exit;
            }

            $this->instance->fx_saved_name = $unique_id . "_" .  $this->instance->name;
            $this->instance->save();

            R2_session::set_flashdata('messages', array('Función Guardada con éxito.'));
            redirect($this->url_index);
        } else {
            $this->load_view_with_layout($this->_view_upload);
        }
    }

    /**
     * Edita una entidad existente
     * @param $class type <entity_class>
     */
    public function edit_function($id, $success = FALSE)
    {
        if (!$this->id_is_valid($id)) {
            echo $this->error_code;
            return;
        }

        $class = $this->managed_class;
        $this->instance = $class::find($id);
        // Esta magia es porque los nombres estan concatenados por coma en la base de datos
        // Consultar con AR. por cualquier duda.
        $this->column_names = explode(",",$this->instance->column_name);
        $this->load_view_with_layout($this->_view_upload);
    }

    /**
     * Elimina una entidades
     * @param $class type <entity_class>
     */
    public function delete_function($id)
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

                if ($this->instance->destroy()){
                    R2_session::set_flashdata('messages', array('Función Eliminada con éxito.'));
                    redirect($this->url_index);                 
                }else{
                    $this->instance->notice = lang('Ocurrió un error al borrar');
                }
            } else
                $this->instance->notice = lang("No es posible borrar el proceso");
        }
        $this->load_view_with_layout($this->_delete_view);
    }

    public function download_function($id)
    {
        $item = Function_creator::find($id);
        if (!$item)
            redirect($this->url_index);
        #Instancio el helper para enviar el archivo.
        $this->load->helper('download');

        $data = file_get_contents('./scripts/focus2_process/user_fxs/'.$item->fx_saved_name.'.py');
        force_download($item->name.'.py', $data);
    }

    public function download_model()
    {
        #Instancio el helper para enviar el archivo.
        $this->load->helper('download');
        $data = file_get_contents($this->basic_template_url);
        force_download('template_basico.py', $data);
    }


    //****************************************************************************
    //     Funciones para validacion de python
    //  
    //****************************************************************************

    public function check_python_validity(){
        // Escapamos los comandos que le vamos a enviar al bash
        $command = escapeshellcmd('/var/www/html/uploads/tests_py/test.py');
        $output = shell_exec("python $command");

        return $output;
       }
 
    public function set_python_file_tmp_to_valid(){

        $data =  $this->input->post('prm1');
        $file  = '/var/www/html/uploads/tests_py/test_tmp.py';

        $ok = @file_put_contents($file,$data);

        if(!$ok) {
            echo "Cannot write file $file";
            $this->db->trans_rollback();
            return;
        }

        $ret = $this->check_python_validity();
        $string = trim(preg_replace('/\s\s+/', ' ', $ret));
        echo $string;
        @unlink($file);
    }


    public function get_python_data(){
        $data =  $this->input->post();
        $fx_row = Function_creator::where(array('id' => $data['fx_id']));
		
        if(!count($fx_row) || !file_exists($fx_row[0]->path)) {
        	echo '';
        	return;
        }

        $file_data = file_get_contents('./scripts/focus2_process/user_fxs/'.$fx_row[0]->fx_saved_name.'.py');

        echo $file_data;
    }   

    /**
    * Guarda el archivo python
    */
    public function save_python_valid_python_file(){

        $this->db->trans_begin();
        $data =  $this->input->post();
        //los datos viene por post pero como requestquerystring o RQS :)
        // parse_str(urldecode($data['frm']),$varData);
	    $varData = $data;

        $txt = '';
        $update = FALSE;
        $arrRET = array("status" => false,
                        "redirect" => false,
                        "error_msg" => false,
                        "success_msg" => false,
                        "url_redirect" => false);
        
        // Aca tengo que agregar un chequeo de si el archivo es valido.
        if (true) {
            #  llamar a un script python que valide todo. antes de guardar.
            #  ahora la validacion que tengo es por ajax y tengo que modificar um par de cosas 
            # para que sea compatible 
        }

        if (isset($data['dataFx']) && $data['dataFx'] != '') {
            $txt = $data['dataFx'];
        }

        if (isset($data['fx_id']) && $data['fx_id'] != '') {
            $instance = Function_creator::where(array('id' => $data['fx_id']))[0];
            $instance->name = $varData['name'];
            $instance->description = $varData['description'];
            $instance->column_name = join(",", $varData['column_name']);
            $file = $this->var_private_dir . $instance->fx_saved_name . '.py';
            $file_shared_fd = $instance->path;
            $update = TRUE;
        } else {
            $unique_id = uniqid();
            $file = $this->var_private_dir . $unique_id . "_" .  $varData['name'] .".py";
            $file_shared_fd = $this->config->item('upload_path') . $varData['name'] .".py";

            $instance = Function_creator::new_from_array(
                array('name' => $varData['name'],
                      'path' => $varData['name'] . '.py',
                      'description' => $varData['description'],
                      'fx_saved_name' => $unique_id . "_" .  $varData['name'],
                      'column_name' => join(",",$varData['column_name'])
                )
            );
            $instance->add_config("check",true);
        }
        
        if ($instance->is_valid()) {
            $instance->save();
            //file_put_contents($file_shared_fd,$txt);
        }else{
            echo json_encode($instance->errors());
            $this->db->trans_rollback();
            return;
        }

        // Quizas habria que usar un try catch y manejarlo de otra manera
        if(file_exists($file) && !is_writeable($file)) {
            echo "Cannot write file $file";
            $this->db->trans_rollback();
            return;
        }
        if(file_exists($file_shared_fd) && !is_writeable($file_shared_fd)) {
            echo "Cannot write file $file_shared_fd";
            $this->db->trans_rollback();
            return;
        }

        $tmp = file_put_contents($file,$txt);
        $tmp_upload = file_put_contents($file_shared_fd, $txt);
        if ($tmp === FALSE) {
            echo json_encode("No se puede guardar el archivo.");
            $this->db->trans_rollback();
            return FALSE;
        }

        $this->db->trans_commit();
        echo 'true';
    }

}
