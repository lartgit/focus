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
class Pixel_selection_rules extends Entity_Admin {

    public $upFile;

    public function __construct() {

        // Le mandamos al controller padre el nombre del controller y de la clase que administra
        parent::__construct('pixel_selection_rules', 'Pixel_selection_rule');
        $this->upFile = new R2_Upload_File();
        $this->url_upload = $this->url . '/upload_file';
        $this->url_import = $this->url . '/upload_view';
        $this->import_view = 'uploads/upload_rules';
        $this->edit_view = 'entities/form_pixel_selection_rules';
    }

    public function new_instance() {

        $this->instance = new $this->managed_class();
        $this->action_name = 'Agregar';
        $this->form_content = form_content($this->instance);
        $this->load_view_with_layout($this->edit_view);
    }

    public function upload_view() {
        $this->upload = TRUE;
        $this->load_view_with_layout($this->import_view);
    }

    public function upload_file() {
        // Se intenta realizar el upload del archivo.
        $file = $this->upFile->file_import($this->config->item('upload_path'), 'csv|xls|xlsx', true);

        if (!$file) {
            $this->error_string = true;
            $this->errors[] = $this->upload->display_errors();
            $this->load_view_with_layout($this->import_view);
            return;
        }

        $data = $this->upFile->read_import_file();
        
        if (!$data) {
            $this->error_string = true;
            $this->errors = $this->upFile->errors;
            $this->load_view_with_layout($this->import_view);
            return;
        }

        $check_file = $this->load->model('lart/'. $this->managed_class);


        $check_file = $this->Pixel_selection_rule->validate_excel_file($data);


        if ($check_file) {
            $this->error_string = NULL;
            $this->success = $this->Pixel_selection_rule->success;
        }else{
            $this->error_string = true;
            $this->errors = $this->Pixel_selection_rule->errors;
        }

        $this->load_view_with_layout($this->import_view);
        return;
    }

}
