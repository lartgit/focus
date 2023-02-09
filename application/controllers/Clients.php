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
class Clients extends Entity_Admin {

    public function __construct() {

        // Le mandamos al controller padre el nombre del controller y de la clase que administra
        parent::__construct('clients', 'Client');
        $this->url_delete = $this->url . '/delete';
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
            $this->related_instances = $this->instance->related_with();

            $this->instance->notice = lang('¿ Está seguro que desea borrar a la entidad :') . ' ' . $this->instance->name . ' ?';
        } else {
            //if ($this->instance->is_deleteable()) {
            if ($this->instance->destroy()) {
                redirect($this->url_index . '/2');
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
