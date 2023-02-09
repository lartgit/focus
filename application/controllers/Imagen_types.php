<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 *    Controller de User_Groups
 * 
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class Imagen_Types extends Entity_Admin {

    public function __construct() {

        // Le mandamos al controller padre el nombre del controller y de la clase que administra
        parent::__construct('imagen_types', 'Imagen_Type');

        $this->url_manage_data_types = $this->url . '/manage_data_types';

        $this->url_manage_data_types_edit = $this->url . '/manage_data_types_edit';

       //views
        $this->list_view = 'entities/list_imagen_types';
    }
    
    /**
     * Index de la clase
     */
    public function index($success = FALSE) {
        $this->url_back = NULL;
        $class = $this->managed_class;
        $this->instances = Imagen_Type::get_index_data();

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
}
