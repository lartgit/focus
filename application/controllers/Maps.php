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
class Maps extends Entity_Admin {

    public function __construct() {

        // Le mandamos al controller padre el nombre del controller y de la clase que administra
        parent::__construct('maps', 'map');
        // $this->show = FALSE;

        //Instancio el model
        // $this->load->model('lart/' . $this->managed_class);
        // $this->load->model('lart/Project');

        // $projects = Project::all_active();
        // $this->obj_tree = $this->Farm->recursivit_projects($projects);
        $this->url_map_to_shp = $this->url . '/region_map_to_shp';
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

    /**
     * 
     */
    public function region_map_to_shp()
    {
        $folder = $this->input->post('folder');
        $map_id = $this->input->post('map_id');

        $this->instance = new $this->managed_class();
        $ret = $this->instance->region_map_to_shp($folder, $map_id);

        if ($ret) {
            echo 0;
        } else {
            echo 1;
        }
    }
}
?>
