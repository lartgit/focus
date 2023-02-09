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
class Layer_types extends Entity_Admin {

    public function __construct() {

        // Le mandamos al controller padre el nombre del controller y de la clase que administra
        parent::__construct('layer_types', 'layer_type');
        $this->edit_view = 'entities/form_layers';
        
    }

    /**
     * Index de la clase
     */
    public function index($_ = false) {
        
        $this->url_back = NULL;
        $class = $this->managed_class;

        $this->get_data = $this->input->get();

        $this->images = Imagen_Type::all_permitted();

        if(isset($this->get_data['image_id']) ) {
            $this->instances = Layer_type::get_index_data(array(
                'layer_types.image_type_id' => $this->get_data['image_id']
            ));
        }
        if (!isset($this->instances))
            $this->instances = Layer_type::get_index_data();

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
        $this->imagen_types = Imagen_Type::all_permitted();
        $this->data_types = Parameter_type::all_permitted();
        $this->action_name = 'Agregar';
        
        $this->load_view_with_layout($this->edit_view);
    }

    /**
     * Graba los cambios en la instancia.
     */
    public function save() {

        $class = $this->managed_class;
        
        $this->instance = $class::new_from_array($_POST);
        $this->imagen_types = Imagen_Type::all_permitted();
        $this->data_types = Parameter_type::all_permitted();
        
        if ($this->instance->is_valid()) {            
        	// var_dump("is valid");exit;
            $this->instance->save();
            redirect($this->url_show . '/' . $this->instance->id . '/1');
        } else {
        	// var_dump("is valid 1");exit;
            //$this->form_content = form_content($this->instance);
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

        $this->show = TRUE;
        $this->instance = $class::find($id);
        $this->imagen_types = Imagen_Type::all_permitted();
        $this->data_types = Parameter_type::all_permitted();
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
        $class = $this->managed_class;
        $this->instance = $class::find($id);
        $this->imagen_types = Imagen_Type::all_permitted();
        $this->data_types = Parameter_type::all_permitted();
        $this->load_view_with_layout($this->edit_view);
    }
    
}

