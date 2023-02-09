<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 *    Controller de Clients
 *
 * @author NArias
 * @package Focus
 */
class Farms extends Entity_Admin {

    public function __construct() {

        // Le mandamos al controller padre el nombre del controller y de la clase que administra
        parent::__construct('farms', 'Farm');
        $this->show = FALSE;

        //Instancio el model
        $this->load->model('lart/' . $this->managed_class);
        $this->load->model('lart/Project');

        $projects = Project::all_active();
        $this->obj_tree = $this->Farm->recursivit_projects($projects);
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
        if (!$this->user_can_add)
            redirect($this->index());

        $this->instance = new $this->managed_class();
        $this->action_name = 'Agregar';
        $this->form_content = form_content($this->instance);
        $this->load_view_with_layout($this->form_view_for($this->managed_class));
    }

}
