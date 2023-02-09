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
class Parameters extends Entity_Admin {

    public function __construct() {
        // Le mandamos al controller padre el nombre del controller y de la clase que administra
        parent::__construct('parameters', 'Parameter');

        $this->url_download = $this->url . '/download';

        $this->success = R2_session::flashdata('messages');
        $this->errors = R2_session::flashdata('err_messages');

        $this->url_regions = $this->url . "/get_regions";
        $this->url_export_parameters = $this->url . "/export_parameters";
        $this->url_import_parameters = $this->url . "/import_parameters";
    }

    /**
     * Index de la clase
     */
    public function index($_ = false) {
        $this->url_back = NULL;
        $class = $this->managed_class;

        $this->get_data = $this->input->get();

        $this->maps = Map::all_permitted();

        $this->instances = array();

        if((!isset($this->get_data['map_id']) || $this->get_data['map_id'] == -1) && 
           (!isset($this->get_data['region_id']) || $this->get_data['region_id'] == -1) && 
           (!isset($this->get_data['search']) || $this->get_data['search'] == '')) {
            $this->errors[] = "Debe seleccionar algun filtro";
        } else {
            //Si quieren, eventualmente, que se muestre todo al inicio borrar el if de arriba y dejar solo esta linea.
            $this->instances = Parameter::get_index_data($this->get_data);
        }

        $this->load_view_with_layout($this->list_view_for($class));
    }

    /**
     * Permite borrar una entidad.
     * @param $class type <entity_class>
     */
    public function delete($id = NULL) {
        if(!is_null($id)) {
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

                $this->instance->notice = lang('¿ Está seguro que desea borrar a la entidad :') . ' ' . $this->instance->primary_key_value() . ' ?';
            } else {
                if ($this->instance->is_deleteable()) {
                    if ($this->instance->destroy()) {
                        R2_session::set_flashdata('messages', array('Cambios Guardados con éxito'));
                        redirect($this->url_index.'?map_id='.$this->instance->map_id.'&region_id='.$this->instance->region_id);
                    } else {
                        $this->instance->notice = lang('Ocurrió un error al borrar');
                    }
                } else {
                    $this->instance->notice = lang("No es posible borrar la entidad:") . " " . $this->instance->name;
                }
            }

            $this->url_back = $this->url_index . "?map_id=".$this->instance->map_id."&region_id=".$this->instance->region_id;
            $this->load_view_with_layout($this->delete_view_for($class));
        } else {
            $ids = $this->input->post('ids');

            $ret = array();
            foreach ($ids as $value) {
                $class = $this->managed_class;
                $this->instance = $class::find($value);
                if(!$this->instance) continue;

                if ($this->instance->is_deleteable()) {
                    if (!$this->instance->destroy()) {
                        $ret[$value] = lang('Ocurrió un error al borrar');
                    }
                } else {
                    $ret[$value] = lang("No es posible borrar el proceso");
                }
            }

            if(empty($ret)) {
                // R2_session::set_flashdata('messages', array('Registros eliminados con éxito'));
            } else {
                R2_session::set_flashdata('errors', json_encode($ret));
            }
        }
    }

    function get_regions() {
        $data = $this->input->get();

        $ret = array();
        if(isset($data['map_id'])) {
            $this->db->select('id');
            $this->db->select('name');
            $this->db->select('ts');
            $this->db->select('created_at');
            $ret = Region::where(array('map_id' => $data['map_id']));
        }

        header('Content-Type: application/json');
        echo json_encode($ret);
    }

    function export_parameters() {
        $this->get_data = $this->input->get();

        $this->instances = array();
        $this->instances = Parameter::get_index_data($this->get_data);

        $ret = array(array("mapa", "region", "uso", "mes", "parametro", "valor", "prioridad"));
        foreach ($this->instances as $instance) {
            $ret[] = array(
                $instance->map_name,
                $instance->region_name,
                $instance->use_name,
                $instance->month,
                $instance->parameter_type_name,
                $instance->value,
                $instance->priority
            );
        }

        header("Content-Type: text/plain");
        header("Content-Disposition: attachment;filename=parameters.csv");

        $df = fopen("php://output", 'w');
        fputs($df, $bom =( chr(0xEF) . chr(0xBB) . chr(0xBF) ));
        foreach ($ret as $row) {
            fputcsv($df, $row, ';');
        }
        fclose($df);
    }

    function import_parameters() {
        $config['upload_path'] = '/tmp';
        $config['allowed_types'] = '*';
        $config['file_name'] = uniqid(true);

        $this->load->library('upload', $config);
        if ( ! $this->upload->do_upload('user_file')) {
            R2_session::set_flashdata('err_messages', array(trim($this->upload->display_errors("", "\n"))));
        } else {
            $data = $this->upload->data();
            if(($ret = Parameter::import($data['full_path'])) === true)
                R2_session::set_flashdata('messages', array('Archivo importado con éxito.'));
            else if(is_array($ret))
                R2_session::set_flashdata('err_messages', $ret);
            else
                R2_session::set_flashdata('err_messages', array($ret));

            unlink($data['full_path']);
        }

        redirect($this->url_index);
    }

    /**
     * Crea una nueva entidad
     * @param $class type <entity_class>
     */
    public function new_instance() {
        if (!$this->user_can_add)
            redirect($this->index());

        $this->get_data = $this->input->get();

        if(!isset($this->get_data['map_id']) || !isset($this->get_data['region_id']))
            redirect($this->url_index);
        $this->map_id = $this->get_data['map_id'];
        $this->region_id = $this->get_data['region_id'];

        $this->instance = new $this->managed_class();
        $this->action_name = 'Agregar';
        $this->form_content = form_content($this->instance);
        $this->url_back = $this->url_index . "?map_id=".$this->get_data['map_id']."&region_id=".$this->get_data['region_id'];
        $this->load_view_with_layout($this->form_view_for($this->managed_class));
    }

    /**
     * \reimpl
     */
    public function save() {

        $class = $this->managed_class;

        $this->instance = $class::new_from_array($_POST);

        if ($this->instance->is_valid()) {
            $this->instance->save();
            redirect($this->url_show . '/' . $this->instance->id . '/1');
        } else {
            $this->map_id = $this->instance->map_id;
            $this->region_id = $this->instance->region_id;
            $this->form_content = form_content($this->instance);
            $this->load_view_with_layout($this->form_view_for($class));
        }
    }

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

        $this->map_id = $this->instance->map_id;
        $this->region_id = $this->instance->region_id;

        //para el cartel de success!
        if ($success !== FALSE) {
            switch ($success) {
                case "1": $this->success[] = 'Cambios Guardados con éxito';
                    break;
                default:
                    break;
            }
        }

        $this->url_back = $this->url_index . "?map_id=".$this->instance->map_id."&region_id=".$this->instance->region_id;
        $this->load_view_with_layout($this->form_view_for($class));
    }

    public function edit($id) {
        if (!$this->id_is_valid($id)) {
            echo $this->error_code;
            return;
        }
        $class = $this->managed_class;
        $this->instance = $class::find($id);
        $this->map_id = $this->instance->map_id;
        $this->region_id = $this->instance->region_id;
        $this->form_content = form_content($this->instance);

        $this->url_back = $this->url_index . "?map_id=".$this->instance->map_id."&region_id=".$this->instance->region_id;
        $this->load_view_with_layout($this->form_view_for($class));
    }
}
