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
class Temporal_expansion_rules extends Entity_Admin {

    public $upFile;
    public $regions;
    public $uses_declared;
    public $uses_concret;
    public $select_concretes;

    public function __construct() {

        // Le mandamos al controller padre el nombre del controller y de la clase que administra
        parent::__construct('temporal_expansion_rules', 'Temporal_expansion_rule');
        $this->upFile = new R2_Upload_File();
        $this->url_upload = $this->url . '/upload_file';
        $this->url_import = $this->url . '/upload_view';
        $this->import_view = 'uploads/upload_rules';
        $this->edit_view = 'entities/form_temporal_expansion_rules';
        $this->list_view = 'entities/list_temporal_expansion_rules';
        $this->select_concretes = $this->url . '/select_concret_by_declared/';
        $this->url_download = $this->url . "/download";
    }

    /**
     * Index de la clase
     */
    public function index($success = FALSE) {
        $this->url_back = NULL;
        $class = $this->managed_class;
        
        $this->get_data = $this->input->POST();
        
        if (isset($this->get_data['limit_rows']))
            $this->filter_limit = $this->get_data['limit_rows'];
        else
            $this->filter_limit = 200;

        $this->instances = $class::all_permitted_filtered($this->filter_limit);

        foreach ($this->instances as $row) {
            $use_declared = Use_declared::find($row->use_declared_id);
            $row->use_declared_id = $use_declared->name;
            $use_concret = Use_concret::find($row->use_concrete_id);
            $row->use_concrete_id = $use_concret->name;
        }

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

    /**
     * Graba los cambios en la instancia.
     */
    public function save() {

        $class = $this->managed_class;

        $this->instance = $class::new_from_array($_POST);
        $this->regions = Region::all_permitted();
        $this->uses_declared = Use_Declared::all_permitted();

        if ($this->instance->is_valid()) {
            $this->instance->save();
            redirect($this->url_show . '/' . $this->instance->id . '/1');
        } else {
            $this->load_view_with_layout($this->edit_view);
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
        $this->regions = Region::all_permitted();
        $this->uses_declared = Use_Declared::all_permitted();

        $this->show = TRUE;
        $this->instance = $class::find($id);

        //para el cartel de success!
        if ($success !== FALSE) {
            switch ($success) {
                case "1": $this->success[] = 'Cambios Guardados con éxito';
                    break;
                default:
                    break;
            }
        }

        $this->load_view_with_layout($this->edit_view);
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

        $this->regions = Region::all_permitted();
        $this->uses_declared = Use_Declared::all_permitted();
        $class = $this->managed_class;
        $this->instance = $class::find($id);

        //$this->form_content = form_content($this->instance);
        $this->load_view_with_layout($this->edit_view);
    }

    /**
     * Permite borrar una entidad.
     * @param $class type <entity_class>
     */
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

            $this->instance->notice = lang('¿ Está seguro que desea borrar a la entidad :') . ' ' . $this->instance->id . ' ?';
        } else {
            if ($this->instance->is_deleteable()) {
                if ($this->instance->destroy()) {
                    redirect($this->url_index . '/1');
                } else {
                    $this->instance->notice = lang('Ocurrió un error al borrar');
                }
            } else {
                $this->instance->notice = lang("No es posible borrar la entidad:") . " " . $this->instance->id;
            }
        }

        $this->load_view_with_layout($this->delete_view_for($class));
    }

    public function new_instance() {

        $this->instance = new $this->managed_class();
        $this->regions = Region::all_permitted();

        $this->uses_declared = Use_Declared::all_permitted();
        $this->action_name = 'Agregar';
        //$this->form_content = form_content($this->instance);
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

        $this->load->model('lart/' . $this->managed_class);

        $check_xls = $this->Temporal_expansion_rule->validate_excel($data);

        if ($check_xls) {
            $this->error_string = NULL;
            $this->success = $this->Temporal_expansion_rule->success;
        } else {
            $this->error_string = true;
            $this->errors = $this->Temporal_expansion_rule->errors;
        }

        $this->load_view_with_layout($this->import_view);
        return;
    }

    public function select_concret_by_declared($id) {

        $concretes = Concretes_by_Declared::where(array('declared_id' => $id));
        $all_concretes = array();
        foreach ($concretes as $concret) {
            $all_concretes[] = Use_concret::find($concret->concrete_id);
        }

        echo json_encode($all_concretes);
    }

    public function download() {

        $templates = "assets/templates/template_temporal_expansion_rules.xlsx";

        $this->load->library('php_excel');

        $data_xls = $this->get_instances();

        foreach ($data_xls as $row) {
            $region = Region::find($row->region_id);
            $row->region_id = $region->name;
            $use_declaration = Use_declared::find($row->use_declared_id);

            $row->use_declared_id = $use_declaration->name;
            $use_concrete = Use_concret::find($row->use_concrete_id);
            $row->use_concrete_id = $use_concrete->name;
        }

//        #En el ultimo elemento del array tengo los nombres de columna
//        #y el orden de los campos.
        $orden = array('region_id', 'use_declared_id', 'use_concrete_id', 'declaration_month', 'month_from', 'month_to');

        $this->php_excel->loadTemplate($templates);

        //Escribir datos de un array, desde que fila, desde que columna
//
        $this->php_excel->writeObjects($data_xls, $orden, 1, 0);
//
        $this->php_excel->save("output.xlsx");
    }

}
