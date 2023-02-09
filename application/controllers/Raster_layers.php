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
class Raster_Layers extends Entity_Admin {

    public function __construct() {
        // Le mandamos al controller padre el nombre del controller y de la clase que administra
        parent::__construct('raster_layers', 'Raster_Layer');
        
        $this->user_can_add = FALSE;
        $this->user_can_edit = FALSE;
    }

    /**
     * Index de la clase
     */
    public function index($_ = false) {
        $this->url_back = NULL;
        $class = $this->managed_class;

        $this->get_data = $this->input->POST();
        
        if (isset($this->get_data['limit_rows']))
            $this->filter_limit = $this->get_data['limit_rows'];
        else
            $this->filter_limit = 200;
        
        $this->instances = Raster_Layer::get_index_data($this->filter_limit);

        $this->load_view_with_layout($this->list_view_for($class));
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
        $this->instance->count_pixels = Raster_Layer::count_pixel_values($id);
        $raster = Raster_file::find($this->instance->raster_file_id);
        $layer = Layer_type::find($this->instance->layer_type_id);
        $this->instance->raster_file_name = isset($raster) ? $raster->path : '';
        $this->instance->layer_type_name = isset($layer) ? $layer->name : '';
        //para el cartel de success!
        if ($success !== FALSE) {
            switch ($success) {
                case "1": $this->success[] = 'Cambios Guardados con éxito';
                    break;
                default:
                    break;
            }
        }

        $this->load_view_with_layout($this->form_view_for($class));
        
    }    
    
    
    
}

