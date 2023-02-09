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
class Users extends Entity_Admin {

    public function __construct() {

        // Le mandamos al controller padre el nombre del controller y de la clase que administra
        parent::__construct('users', 'User');
        $this->url_index = $this->url . '/users/index';
        $this->list_view = 'entities/list_users';
    }

    public function index($success = FALSE) {
        $this->url_back = NULL;
        $class = $this->managed_class;
        $this->instances = $this->get_instances();

        //para el cartel de success!
        if ($success !== FALSE) {
            switch ($success) {
                case "1": $this->success[] = 'Cambios Guardados con éxito';
                    break;
                case "2": $this->success[] = 'Contraseña blanqueada con éxito, se envio un e-mail al usuario.';
                    break;                    
                default:
                    break;
            }
        }
        $this->load_view_with_layout($this->list_view);
    }

}