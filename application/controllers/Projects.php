<?php

if (!defined('BASEPATH')) {
    exit('No direct script access allowed');
}

/**
 * Description:
 *    Controller de Projects
 *
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class Projects extends Entity_Admin {

    public $list_view = 'entities/list_projects';
    public $edit_view = 'entities/form_project';
    public $obj_tree;

    public function __construct() {
        // Le mandamos al controller padre el nombre del controller y de la clase que administra
        parent::__construct('projects', 'Project');

        $this->url_ajax_client_project = $this->url . '/clients_by_project';
        $this->url_ajax_project_client = $this->url . '/projects_by_client';
        $this->show = FALSE;

        //Instancio el model
        $this->load->model('lart/' . $this->managed_class);
    }

    /**
     * Index de la clase
     */
    public function index($success = FALSE) {
        $this->url_back = NULL;
        $class = $this->managed_class;
        $this->instances = $this->get_instances();

        $this->obj_tree = $this->Project->recursivit_projects($this->instances);

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

    /**
     * Crea una nueva entidad
     * @param $class type <entity_class>
     */
    public function new_instance() {
        if (!$this->user_can_add) {
            redirect($this->index());
        }

        $this->instances = $this->get_instances();
        // var_dump($this->instances);exit();
        $this->obj_tree = $this->Project->recursivit_projects($this->instances);

        $this->instance = new $this->managed_class();
        $this->action_name = 'Agregar';
        $this->projects = Project::all_active();
        $this->clients = Client::all_active();

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
        $this->instances = $this->get_instances();
        $this->obj_tree = $this->Project->recursivit_projects($this->instances);
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

        $this->instances = $this->get_instances();
        $this->obj_tree = $this->Project->recursivit_projects($this->instances);

        $this->show = TRUE;
        $this->instance = $class::find($id);
        $this->projects = Project::all_active();
        $this->clients = Client::all_active();
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
        $this->instances = $this->get_instances();

        $this->obj_tree = $this->Project->recursivit_projects($this->instances);

        $class = $this->managed_class;
        $this->instance = $class::find($id);
        //$this->form_content = form_content($this->instance);
        $this->projects = Project::all_active();
        $this->clients = Client::all_active();
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
        } else if (!$this->input->post()) {
            //array_de_objetos relacionados
            $this->related_instances = $this->instance->related_with();

            $this->instance->notice = lang('¿ Está seguro que desea borrar a la entidad :') . ' ' . $this->instance->name . ' ?';
        } else {

            if ($this->instance->destroy()) {
                $success = '2';
                $this->index($success);
                return false;
            } else {
                $this->instance->notice = lang('Ocurrió un error al borrar');
            }
        }

        $this->load_view_with_layout($this->delete_view_for($class));
    }

    public function clients_by_project() {
        $client_id = $this->input->post('client');
        $div_id = $this->input->post('div_id');
        $this->instances = $this->get_instances();
        $this->obj_tree = $this->Project->recursivit_projects($this->instances);
        $projects['projects'] = Project::where(array('client_id' => $client_id));
        $projects['p'] = (new $this->managed_class())->spit_tree($this->obj_tree, $div_id, $client_id);

        echo json_encode($projects);
    }

    public function projects_by_client() {
        $client_id = $this->input->post('client');

        $projects = Project::where(array('client_id' => $client_id));

        echo json_encode($projects);
    }

    public function versions()
    {
        $project_id = $this->input->post('project_id');

        $versions = Version::where(array('project_id' => $project_id));

        echo json_encode($versions);

    }

}
