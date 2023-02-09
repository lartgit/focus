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
class Regions extends Entity_Admin {

    public function __construct() {

        // Le mandamos al controller padre el nombre del controller y de la clase que administra
        parent::__construct('regions', 'region');
        // $this->show = FALSE;
        #Cargo el modelo de la clase
        $this->model = new $this->managed_class;
    }

    /**
     * Crea una nueva entidad
     * @param $class type <entity_class>
     */
    public function index($success = FALSE) {
        $this->url_action = $this->url . '/filtered_regions_by_map_id/';    	
        $this->url_back = NULL;
        $class = $this->managed_class;
        $this->maps = Map::all_permitted();
        $this->instances = $this->get_instances();

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



    public function filtered_regions_by_map_id()
    {

        $this->url_action = $this->url . '/filtered_regions_by_map_id/';
        $this->map_id = $this->input->post('map_id');
        $this->maps = Map::all_permitted();

        $this->instances = $this->model->filtered_regions_by_map_id($this->map_id);

        if (!empty($this->instances)) {
            $this->load_view_with_layout($this->list_view_for($this->managed_class));
            return;
        } else {
            $this->error_string = true;
            $this->errors[] = 'No existen datos para este map_id';
            $this->load_view_with_layout($this->list_view_for($this->managed_class));
            return;
        }
    }

}
