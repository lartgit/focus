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
class User_profiles extends Entity_Admin {

   public function __construct() {
      // Le mandamos al controller padre el nombre del controller y de la clase que administra
    parent::__construct('user_profiles','User_profile');
    $this->url_edit = $this->url . '/edit_profile/';

   }
   
   // public function index($success = FALSE) {
   //     redirect(base_url());
   // }
   

    /**
     * Muestra una entidad existente
     * @param $class type <entity_class>
     */
    public function show($id = null, $success = FALSE) {
        $user_id = $this->session->userdata('user')->id;
        if (!$this->id_is_valid($id)) {
            echo $this->error_code;
            return;
        }

        $class = $this->managed_class;

        $this->show = TRUE;
        $this->instance = $class::find($user_id);
        //$this->form_content->show = $this->show;
        $this->form_content = form_content($this->instance, $this->show);

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

    /**
     * Reeimplentado para no enviar el id de usuario 
     * y no se pueda acceder por url
     * @param $class type <entity_class>
     */
    public function edit($id = NULL) {

        $this->edit_profile();
    }

    /**
     * Edita una entidades
     * @param $class type <entity_class>
     */
    public function edit_profile() {
        $user_id = $this->session->userdata('user')->id;
        if (!$this->id_is_valid($user_id)) {
            echo $this->error_code;
            return;
        }
        $class = $this->managed_class;

        $this->instance = $class::find($user_id);
        $this->form_content = form_content($this->instance);
        $this->load_view_with_layout($this->form_view_for($class));
    }

}
