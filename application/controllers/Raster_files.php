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
class Raster_Files extends Entity_Admin
{

    public function __construct()
    {
        // Le mandamos al controller padre el nombre del controller y de la clase que administra
        parent::__construct('raster_files', 'Raster_File');

        $this->success = R2_session::flashdata('messages');
        $this->errors = R2_session::flashdata('err_messages');

        $this->url_save_process = $this->url . '/save_process/';
        $this->url_save_process_massive = $this->url . '/save_process_massive/';
        $this->url_action = $this->url . '/save/';
        $this->url_ajax_read_dir = $this->url . '/files_in_folder/';

        #Cargo el modelo de procesos genericos
        $this->upFile = new R2_Upload_File();
        $this->load->helper('r2_formbuilder');
        $this->process_class = 'Raster_file';

        #URLS procesos.
        $this->url_new = $this->url . '/new_process/';
        $this->url_new_massive = $this->url . '/new_massive_process/';
        $this->url_show_import_log = $this->url . '/show_import_log';

        #ULR entidad que administro
        $this->url_index = $this->url . '/index';
        // $this->url_show_process = $this->url . '/show_process';
        $this->url_delete_process = $this->url . '/delete_process';
        $this->url_back = $this->url;

        //views
        $this->_view_upload = 'uploads/upload_files_raster';
        $this->_view_upload_massive = 'uploads/upload_files_raster_massive';
        $this->_delete_view = 'entities/confirm_delete';
        $this->_log_view = 'entities/list_import_log';
    }

    /**
     * Index de la clase
     */
    public function index($_ = NULL)
    {
        $this->url_back = NULL;
        $class = $this->managed_class;

        $filter = array();
        $image_type_id = $this->input->get('image_type_id');
        if ($image_type_id) $filter['image_type_id'] = $image_type_id;
        $this->instances = Raster_File::get_index_data($filter);

        $this->load_view_with_layout($this->list_view_for($class));
    }

    public function new_process()
    {
        if (!$this->user_can_add)
            redirect($this->index());

        $this->instance = new Raster_File;
        $this->imagen_types = Imagen_type::all();
        $this->sets = Pixel_set::all();
        $this->load_view_with_layout($this->_view_upload);
    }

    public function new_massive_process()
    {
        if (!$this->user_can_add)
            redirect($this->index());

        $this->instance = new Raster_File;
        $this->imagen_types = Imagen_type::all();
        $this->sets = Pixel_set::all();
        $this->load_view_with_layout($this->_view_upload_massive);
    }

    /*
     * Metodo uploads files
     * Description
     */

    public function files_in_folder()
    {

        $folder = $this->input->post('folder');

        if ($folder) {
            $files = $this->upFile->read_upload_folder($folder);
        } else {
            $files = $this->upFile->read_upload_folder();
        }

        echo json_encode($files);
    }

    /**
     * Graba los cambios en la instancia.
     */
    public function save_process()
    {

        $class = $this->process_class;

        $this->instance = $class::new_from_array($this->input->post());

        if ($this->instance->is_valid()) {
            $this->instance->save();
            R2_session::set_flashdata('messages', array('Cambios Guardados con éxito'));
            redirect($this->url_index);
        } else {
            $this->imagen_types = Imagen_type::all();
            $this->sets = Pixel_set::all();
            $this->load_view_with_layout($this->_view_upload);
        }
    }

    /**
     * Graba los cambios en la instancia.
     */
    public function save_process_massive()
    {

        $class = $this->process_class;

        $checked_files = $this->input->post('check_files');

        if (!$checked_files) {
            R2_session::set_flashdata('err_messages', array('Debe seleccionar algun archivo'));
            redirect($this->url_new_massive);
        }

        //esto es sólo para ver que completó los campos
        $this->instance = $class::new_from_array($this->input->post());
        if (!$this->instance->is_valid()) {
            $this->imagen_types = Imagen_type::all();
            $this->sets = Pixel_set::all();
            $this->errors = $this->instance->errors();
            $this->load_view_with_layout($this->_view_upload_massive);
        } else {
            foreach ($checked_files as $each_file) {
                $each_instance = $class::new_from_array($this->input->post());

                $each_instance->path = $each_instance->path . $each_file;
                if ($each_instance->is_valid()) {
                    $each_instance->save();
                }
            }
            R2_session::set_flashdata('messages', array('Cambios Guardados con éxito'));
            redirect($this->url_index);
        }
    }

    /**
     * Elimina una entidades
     * @param $class type <entity_class>
     */
    public function delete_process($id = NULL)
    {
        if (!is_null($id)) {
            if (!$this->id_is_valid($id)) {
                echo $this->error_code;
                return;
            }

            $class = $this->process_class;
            $this->instance = $class::find($id);

            if (!$this->instance)
                redirect($this->url_index);

            if (!$_POST) {
                $this->instance->notice = lang('¿ Está seguro que desea borrar a la entidad :') . ' ' . $this->instance->id . ' ?';
            } else {
                if ($this->instance->is_deleteable()) {

                    if ($this->instance->destroy()) {
                        R2_session::set_flashdata('messages', array('Registro eliminado con éxito'));
                        redirect($this->url_index);
                    } else {
                        $this->instance->notice = 'Ocurrió un error al borrar';
                    }
                } else
                    $this->instance->notice = "No es posible borrar el proceso";
            }
            $this->load_view_with_layout($this->_delete_view);
        } else {
            $ids = $this->input->post('ids');

            $ret = array();
            foreach ($ids as $value) {
                $class = $this->process_class;
                $this->instance = $class::find($value);
                if (!$this->instance) continue;

                if ($this->instance->is_deleteable()) {
                    if (!$this->instance->destroy()) {
                        $ret[$value] = 'Ocurrió un error al borrar';
                    }
                } else {
                    $ret[$value] = "No es posible borrar el proceso";
                }
            }

            if (empty($ret)) {
                R2_session::set_flashdata('messages', array('Registros eliminados con éxito'));
            } else {
                R2_session::set_flashdata('err_messages', $ret);
            }
        }
    }

    public function show_import_log($id)
    {
        $this->instances = Log_import_image::where(array('process_id' => $id));
        $this->load_view_with_layout($this->_log_view);
    }
}
