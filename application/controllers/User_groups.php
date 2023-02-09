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
class User_Groups extends Entity_Admin {

    public function __construct() {

        // Le mandamos al controller padre el nombre del controller y de la clase que administra
        parent::__construct('user_groups', 'User_group');

        $this->url_manage_users = $this->url . '/manage_users';
        $this->url_manage_menus = $this->url . '/manage_menus';

        $this->url_manage_users_edit = $this->url . '/manage_users_edit';
        $this->url_manage_menus_edit = $this->url . '/manage_menus_edit';

        $this->edit_view = 'entities/form_edit_user_group';
        $this->delete_view = 'entities/confirm_delete_user_groups';
    }

    /**
     * Maneja las relaciones muchos a muchos de usuarios - grupos de usuarios
     * Específico para los User_Groups
     */
    public function manage_users($id, $user_id = NULL) {
        $class = $this->managed_class;
        $this->instance = $class::find($id);

        if ($user_id) {
            //El grupo admin se maneja distinto (columna is_admin de users)
            if($id == 1) {
                $user = User::find($user_id);
                if($user) {
                    $user->is_admin = ($user->is_admin==='t')?'f':'t';
                    $user->save();
                }
            } else
                $this->instance->add_or_remove_user_by_id($user_id);

            redirect($this->url_manage_users . '/' . $id);
        }

        $this->form_content = form_content($this->instance, true);
        $this->load_view_with_layout('entities/users_by_group');
    }

    /**
     * Maneja las relaciones muchos a muchos de menus - grupos de usuarios
     * Específico para los User_Groups
     */
    public function manage_menus($id, $user_id = NULL) {
        $class = $this->managed_class;
        $this->instance = $class::find($id);

        if ($user_id) {
            $this->instance->add_or_remove_menu_by_id($user_id);
            redirect($this->url_manage_menus . '/' . $id);
        }

        $this->form_content = form_content($this->instance, true);
        $this->load_view_with_layout('entities/menus_by_group');
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
        $this->manage_menus_edit($id);
        $this->manage_users_edit($id);
        $this->form_content = form_content($this->instance);
        $this->load_view_with_layout($this->edit_view);
    }

    /**
     * Maneja las relaciones muchos a muchos de usuarios - grupos de usuarios
     * Específico para edit
     */
    public function manage_users_edit($id, $user_id = NULL) {
        $class = $this->managed_class;
        $this->instance = $class::find($id);

        if ($user_id) {
            $this->instance->add_or_remove_user_by_id($user_id);
            redirect($this->url_edit . '/' . $id);
        }
    }

    /**
     * Maneja las relaciones muchos a muchos de menus - grupos de usuarios
     * Específico para la funci{on edit
     */
    public function manage_menus_edit($id, $user_id = NULL) {
        $class = $this->managed_class;
        $this->instance = $class::find($id);
        if ($user_id) {
            $this->instance->add_or_remove_menu_by_id($user_id);
            redirect($this->url_edit . '/' . $id);
        }
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
        } else if (!$_POST) {
            //array_de_objetos relacionados
            if ($this->instance->is_deleteable()) {
                $this->instance->notice = lang('¿ Está seguro que desea borrar a la entidad :') . ' ' . $this->instance->name . ' ?';
            } else {
                $this->related_instances = $this->instance->related_with();
                $this->instance->notice = lang("No es posible borrar la entidad:") . " " . $this->instance->name;
            }
        } else {
            if ($this->instance->destroy()) {
                redirect($this->url_index . '/1');
            } else {
                $this->instance->notice = lang('Ocurrió un error al borrar');
            }
        }

        $this->load_view_with_layout($this->delete_view);
    }

}
