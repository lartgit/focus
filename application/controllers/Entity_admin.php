<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 *    Controller que permite administrar acciones de ABM's
 *    de entidades básicas.
 *
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class Entity_Admin extends Focus_base_controller {

    public $list_view = 'entities/list';
    public $form_view = 'entities/form';
    public $delete_view = 'entities/confirm_delete';
    public $class;

    public function __construct($controller_name = '', $managed_class = '') {
        parent::__construct();
        // ESTOS PARAMETROS SE DEBEN ENVIAR EN LAS SUBCLASSES EN EL CONSTRUCT
        $this->url = site_url($controller_name);
        $this->controller_name = $controller_name;
        $this->managed_class = $managed_class;

        // Urls -> Actions
        $this->url_index = $this->url . '/index';
        $this->url_show = $this->url . '/show';
        $this->url_new = $this->url . '/new_instance';
        $this->url_edit = $this->url . '/edit';
        $this->url_save = $this->url . '/save';
        $this->url_delete = $this->url . '/delete';
        $this->url_send_pass = $this->url . '/send_pass';

        // Urls -> buttons
        $this->url_action = $this->url_save;
        $this->url_back = $this->url_index;
        // Permisions
        $this->user_can_add = $this->user->can_add($this->managed_class);
        $this->user_can_edit = $this->user->can_edit($this->managed_class);
        $this->user_can_delete = $this->user->can_delete($this->managed_class);
        $this->user_can_send_pass = $this->user->can_send_pass($this->managed_class);

        // Form builder
        $this->load->helper('r2_formbuilder');
    }

    /**
     * Función para chequear que se armaron bien los links
     */
    public function test_links() {
        echo "url_index: " . $this->url_index . '<br>';
        echo "url_show: " . $this->url_show . '<br>';
        echo "url_new: " . $this->url_new . '<br>';
        echo "url_edit: " . $this->url_edit . '<br>';
        echo "url_delete: " . $this->url_delete . '<br>';
        echo "url_send_pass: " . $this->url_send_pass . '<br>';
        echo "url_save: " . $this->url_save . '<br>';
        echo "url_action: " . $this->url_action . '<br>';
        echo "url_back: " . $this->url_back . '<br>';
    }

    /**
     * Index de la clase
     */
    public function index($success = FALSE) {
        $this->url_back = NULL;
        $class = $this->managed_class;
        $this->instances = $this->get_instances();

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
     * Crea una nueva entidad
     * @param $class type <entity_class>
     */
    public function new_instance() {
        if (!$this->user_can_add)
            redirect($this->index());

        $this->instance = new $this->managed_class();
        $this->action_name = 'Agregar';
        $this->form_content = form_content($this->instance);
        $this->load_view_with_layout($this->form_view_for($this->managed_class));
    }

    /**
     * Graba los cambios en la instancia.
     */
    public function save() {

        $class = $this->managed_class;

        $this->instance = $class::new_from_array($_POST);

        if ($this->instance->is_valid()) {
            $this->instance->save();
            redirect($this->url_show . '/' . $this->instance->id . '/1');
        } else {
            $this->form_content = form_content($this->instance);
            $this->load_view_with_layout($this->form_view_for($class));
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
        $this->form_content = form_content($this->instance);
        $this->load_view_with_layout($this->form_view_for($class));
    }

    /**
     * Se agrega esta función para
     *   poder redefinirla en los controllers hijos
     */
    public function get_instances() {

        $class = $this->managed_class;
        return $class::all_permitted();
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

            $this->instance->notice = lang('¿ Está seguro que desea borrar a la entidad :') . ' ' . $this->instance->display_value() . ' ?';
        } else {
            if ($this->instance->is_deleteable()) {
                if ($this->instance->destroy()) {
                    $success = '2';
                    $this->index($success);
                    return false;
                } else {
                    $this->instance->notice = lang('Ocurrió un error al borrar');
                }
            } else {
                $this->instance->notice = lang("No es posible borrar la entidad:") . " " . $this->instance->name;
            }
        }

        $this->load_view_with_layout($this->delete_view_for($class));
    }

    /**
     * Específico para los usuarios
     */
    public function send_pass($id) {

        $this->_user_session->reset_passsword($id);
        $success = '2';
        $this->index($success);
    }

}
