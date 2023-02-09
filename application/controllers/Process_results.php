<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 *    Controller de process_results
 * 
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class Process_Results extends Entity_Admin
{

    public $url_select_versions = '';
    public $url_select_scenes = '';
    public $url_parcial_tree_by_client = '';

    public function __construct()
    {

        // Le mandamos al controller padre el nombre del controller y de la clase que administra
        parent::__construct('process_results', 'Process_Result');

        // Urls -> Actions
        $this->url_index = $this->url_process_results . '/index';
        $this->url_select_versions = $this->url_process_results . '/select_version_by_client/';
        $this->url_select_scenes = $this->url_process_results . '/select_scene_by_image_type/';
        $this->url_parcial_tree_by_client = $this->url_process_results . 'parcial_tree_by_client';

        // Permisions
        $this->user_can_add = $this->user->can_add($this->managed_class);
        $this->user_can_edit = $this->user->can_edit($this->managed_class);
        $this->user_can_delete = $this->user->can_delete($this->managed_class);
        $this->user_can_send_pass = $this->user->can_send_pass($this->managed_class);

        //views
        $this->edit_view = 'entities/form_process_results';
        $this->list_view = 'entities/list_process_results';
        $this->delete_view = 'entities/confirm_delete_process_results';

        // El arbolito.
        $this->load->model('lart/Project');
        $data = Project::all_permitted();
        $this->obj_tree = $this->Project->recursivit_projects($data);
    }

    /**
     * Index de la clase
     */
    public function index($success = FALSE)
    {
        $this->url_back = NULL;
        $class = $this->managed_class;
        $this->instances = $this->get_instances();
        foreach ($this->instances as $instance) {
            if (!isset($instance->description)) {
                $instance->description = 'Proceso aún no iniciado';
            }
        }

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
        $this->load_view_with_layout($this->list_view);
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

        $this->imagen_types = Imagen_type::all_permitted();
        $this->clients = Client::all_permitted();
        $this->versions = Version::all_active();
        $this->px_rules = Pixel_selection_rule::all_permitted();
        $this->action_name = 'Agregar';
        $this->load_view_with_layout($this->edit_view);
    }

    /**
     * Graba los cambios en la instancia.
     */
    public function save()
    {
        $class = $this->managed_class;

        $this->instance = $class::new_from_array($this->input->post());
        if ($this->instance->save()) {
            redirect($this->url_show . '/' . $this->instance->id . '/1');
        } else {
            $this->clients = Client::all_permitted();
            $this->imagen_types = Imagen_type::all_permitted();
            $this->versions = Version::all_active();
            $this->px_rules = Pixel_selection_rule::all_permitted();
            $this->action_name = 'Agregar';
            $this->load_view_with_layout($this->edit_view);
        }
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

        $this->clients = Client::all_permitted();
        $this->imagen_types = Imagen_type::all_permitted();
        $this->versions = Version::all_active();
        $this->px_rules = Pixel_selection_rule::all_permitted();

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

            $this->instance->notice = '¿ Está seguro que desea borrar a la entidad : ' . $this->instance->name . ' ?';
        } else {
            if ($this->instance->is_deleteable()) {
                if ($this->instance->destroy()) {
                    redirect($this->url_index . '/1');
                } else {
                    $this->instance->notice = 'Ocurrió un error al borrar';
                }
            } else {
                $this->instance->notice = "No es posible borrar la entidad: " . $this->instance->name;
            }
        }

        $this->load_view_with_layout($this->delete_view);
    }

    /*Devuelve el objeto versions filtrado por client*/
    public function select_version_by_client()
    {

        $client_id = $this->input->post('client');

        $data = Project::where(array('client_id' => $client_id));

        $this->obj_tree = $this->Project->recursivit_projects($data);

        $version['tree'] = $this->load->view('uploads/parcial_tree', $this, true);


        /*Arma el resultado de versiones.*/
        $this->load->model('lart/Process_result');

        $version['result'] = $this->Process_result->find_version_by_projects($client_id);

        echo json_encode($version);
    }

    /*Devuelve el objeto pixels set filtrado por imagen_tupy*/
    public function select_scene_by_image_type()
    {

        $image_type_id = $this->input->post('imagen_type');

        $scenes = Pixel_set::where(array('imagen_type_id' => $image_type_id));

        echo json_encode($scenes);
    }

    /*Devuelve la vista parcial en base al id del cliente */
    public function parcial_tree_by_client()
    {

        $image_type_id = $this->input->post('imagen_type');

        $scenes = Pixel_set::where(array('imagen_type_id' => $image_type_id));

        echo json_encode($scenes);
    }
}
