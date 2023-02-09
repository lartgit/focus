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
class Use_Declareds extends Entity_Admin {

    public function __construct() {

        // Le mandamos al controller padre el nombre del controller y de la clase que administra
        parent::__construct('use_declareds', 'Use_Declared');

        $this->url_manage_use_concretes = $this->url . '/manage_use_concretes';

        $this->url_manage_use_concretes_edit = $this->url . '/manage_use_concretes_edit';


        // Permisions
        //$this->user_can_add = FALSE;
        //views
        $this->edit_view = 'entities/form_edit_use_declared';
    }

    /**
     * Maneja las relaciones muchos a muchos de usuarios - grupos de usuarios 
     * Específico para los User_Groups
     */
    public function manage_use_concretes($id, $concrete_id = NULL) {
        $class = $this->managed_class;
        $this->instance = $class::find($id);

        if ($concrete_id) {
            $this->instance->add_or_remove_concrete_by_id($concrete_id);
            redirect($this->url_manage_use_concretes . '/' . $id);
        }

        $this->form_content = form_content($this->instance, true);
        $this->load_view_with_layout('entities/concretes_by_declared');
    }

    /**
     * Edita la entidad user_groups
     * @param $class type <entity_class>
     */
    public function edit($id) {
        if (!$this->id_is_valid($id)) {
            echo $this->error_code;
            return;
        }
        $class = $this->managed_class;
        $this->instance = $class::find($id);
        $this->manage_use_concretes_edit($id);
        $this->form_content = form_content($this->instance);
        $this->load_view_with_layout($this->edit_view);
    }

    /**
     * Maneja las relaciones muchos a muchos de usuarios - grupos de usuarios 
     * Específico para edit
     */
    public function manage_use_concretes_edit($id, $concrete_id = NULL) {
        $class = $this->managed_class;
        $this->instance = $class::find($id);

        if ($concrete_id) {
            $this->instance->add_or_remove_concrete_by_id($concrete_id);
            redirect($this->url_edit . '/' . $id);
        }
    }

    public function delete($id) {

        if (!$this->id_is_valid($id)) {
            echo $this->error_code;
            return;
        }

        $class = $this->managed_class;
        $this->instance = $class::find($id);

        if (!$this->instance) {
            redirect($this->url_index);
        } else if (!$_POST) {
            //array_de_objetos relacionados
            $this->related_instances = $this->instance->related_with();

            $this->instance->notice = lang('¿ Está seguro que desea borrar a la entidad :') . ' ' . $this->instance->name . ' ?';
        } else {
            //if ($this->instance->is_deleteable()) {
            if ($this->instance->destroy()) {
                redirect($this->url_index . '/1');
            } else {
                $this->instance->notice = lang('Ocurrió un error al borrar');
            }
            //} else {
            //    $this->instance->notice = "No es posible borrar la entidad: " . $this->instance->name;
            //}
        }

        $this->load_view_with_layout($this->delete_view_for($class));
    }

}
