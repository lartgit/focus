<?php

if (!defined('BASEPATH'))
   exit('No direct script access allowed');

/**
 * Description:
 *    Controller de Versions
 * 
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class Versions extends Entity_Admin {

    public $edit_view = 'entities/form_version';

   public function __construct() {
      // Le mandamos al controller padre el nombre del controller y de la clase que administra
      parent::__construct('versions','Version');

      $this->load->model('lart/Project');
      $this->url_ajax_client_project = $this->url_projects . '/clients_by_project';
      $data = Project::all_permitted();
      $this->obj_tree = $this->Project->recursivit_projects($data); 
      $this->show = FALSE;
   }

   
    /**
     * Index de la clase
     */
    public function index($success = FALSE) {
        $this->url_back = NULL;
        $class = $this->managed_class;
        $this->instances = $this->get_instances();
        
        // $data = Project::all_permitted();
        // $this->obj_tree = $this->Project->recursivit_projects($data); 

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
        $this->load_view_with_layout('entities/list_versions');
    }

    /**
     * Crea una nueva entidad
     * @param $class type <entity_class>
     */
    public function new_instance() {
        if (!$this->user_can_add) {
            redirect($this->index());
        }


        $this->instance = new $this->managed_class();
        $this->action_name = 'Agregar';
        $this->projects = Project::all_active();
        $this->clients = Client::all_active();


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


        $class = $this->managed_class;
        $this->instance = $class::find($id);
        //$this->form_content = form_content($this->instance);
        $this->projects = Project::all_active();
        $this->clients = Client::all_active();
        $this->client_project = Project::find($this->instance->project_id);

        $this->load_view_with_layout($this->edit_view);
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
        $this->projects = Project::all_active();
        $this->clients = Client::all_active();
        $this->client_project = Project::find($this->instance->project_id);

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
     * Graba los cambios en la instancia.
     */
    public function save() {

        $class = $this->managed_class;

        $this->instance = $class::new_from_array($this->input->post());
        $this->projects = Project::all_active();
        $this->clients = Client::all_active();

        if ($this->instance->is_valid()) {
            $this->instance->save();
            redirect($this->url_show . '/' . $this->instance->id . '/1');
        } else {

            $this->load_view_with_layout($this->edit_view);
        }
    }

}
