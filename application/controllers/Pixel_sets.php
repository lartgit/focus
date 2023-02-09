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
class Pixel_sets extends Entity_Admin
{

    public function __construct()
    {

        // Le mandamos al controller padre el nombre del controller y de la clase que administra
        parent::__construct('pixel_sets', 'Pixel_Set');
        $this->edit_view = 'entities/form_edit_pixel_sets';
    }

    /**
     * Crea una nueva entidad
     * @param $class type <entity_class>
     */
    public function new_instance()
    {
        if (!$this->user_can_add)
            redirect($this->index());

        $this->instance = new $this->managed_class();
        $this->action_name = 'Agregar';
        $this->imagen_types = Imagen_Type::all_permitted();
        $this->load_view_with_layout($this->edit_view);
    }

    /**
     * Muestra una entidad existente
     * @param $class type <entity_class>
     */
    public function show($id, $success = FALSE)
    {
        if (!$this->id_is_valid($id)) {
            echo $this->error_code;
            return;
        }

        $class = $this->managed_class;

        $this->show = TRUE;
        $this->instance = $class::find($id);
        $this->imagen_types = Imagen_Type::all_permitted();
        //para el cartel de success!
        if ($success !== FALSE) {
            switch ($success) {
                case "1":
                    $this->success[] = 'Cambios Guardados con éxito';
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
    public function edit($id)
    {
        if (!$this->id_is_valid($id)) {
            echo $this->error_code;
            return;
        }
        $class = $this->managed_class;
        $this->instance = $class::find($id);
        $this->imagen_types = Imagen_Type::all_permitted();
        $this->load_view_with_layout($this->edit_view);
    }

    /**
     * Permite borrar una entidad.
     * @param $class type <entity_class>
     */
    public function delete($id)
    {

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
                $success = '1';
                $this->index($success);
                return false;
            } else {
                $this->instance->notice = lang('Ocurrió un error al borrar');
            }
            //} else {
            //    $this->instance->notice = lang("No es posible borrar la entidad:") . " " . $this->instance->name;
            //}
        }

        $this->load_view_with_layout($this->delete_view_for($class));
    }

    public function for_imagen_type()
    {
        $imagen_type_id = $this->input->get("imagen_type_id");
        if (!$imagen_type_id) {
            echo "[]";
            return;
        }

        $this->db->where("imagen_type_id", $imagen_type_id);
        Pixel_set::all_active();
    }
}
