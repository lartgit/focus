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
class Dates extends Entity_Admin {

    public function __construct() {

        // Le mandamos al controller padre el nombre del controller y de la clase que administra
        parent::__construct('dates', 'Date');
    }

    /**
     * Index de la clase
     */
    public function index($success = FALSE) {
        $this->url_back = NULL;
        $class = $this->managed_class;
        $this->instances = $this->get_instances();

        foreach ($this->instances as $row) {
            $set_id = Pixel_set::find($row->set_id);
            $row->set_id = $set_id->name;
        }

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

            $this->instance->notice = lang('¿ Está seguro que desea borrar a la entidad :') . ' ' . $this->instance->date . ' ?';
        } else {
            if ($this->instance->is_deleteable()) {
                if ($this->instance->destroy()) {
                    redirect($this->url_index . '/1');
                } else {
                    $this->instance->notice = lang('Ocurrió un error al borrar');
                }
            } else {
                $this->instance->notice = lang("No es posible borrar la entidad:") . " " . $this->instance->name;
            }
        }

        $this->load_view_with_layout($this->delete_view_for($class));
    }

}
