<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description of crea_base_controller
 *
 * @author Nico
 */
class Focus_base_controller extends R2_abstract_controller {

    public $_view_header = '/main/header';
    public $_view_footer = '/main/footer';
    public $_view_layout = '/main/layout';
    public $_view_side_menu = '/main/side_menu';
    public $_views_files_location = "./application/views/";

    public function __construct() {
        parent::__construct();

        // Control de acceso:
        $this->check_user_access();

        // Usuario
        $this->user = $this->_user_session->get_user_from_session_data();

        if ($this->is_developing_mode() and $this->user == NULL)
            $this->user = $this->_user_session->get_admin_user_for_devloping_mode();


        // Inicializamos el soporte para las traducciones.
        $this->init_language_support();

        // Urls Languages
        $this->url_language = $this->_url_site . '/language_admin/';
        $this->url_switch_lang = $this->_url_site . '/language_admin/switch_language/';
        $this->url_edit_lang = $this->_url_site . '/language_admin/edit_language/';
        $this->url_add_lang = $this->_url_site . '/language_admin/add_language/';


        // Application Urls
        $this->url_clients = site_url('clients');
        $this->url_projects = site_url('projects');
        $this->url_sub_projects = site_url('sub_projects');
        $this->url_versions = site_url('versions');
        $this->url_farms = site_url('farms');
        $this->url_users = site_url('users');
        $this->url_user_groups = site_url('user_groups');
        $this->url_pixel_sets = site_url('pixel_sets');
        $this->url_process_results = site_url('process_results');
        $this->url_downloads = site_url('downloads');
        $this->url_results = site_url('results');
        $this->url_process_fields = site_url('process_fields');
        $this->url_process_pixels = site_url('process_pixels');
        $this->url_process_regions = site_url('process_regions');
        $this->url_process_uses = site_url('uses_asigns');
        $this->url_parameters = site_url('parameters');
        $this->url_imagen_types = site_url('imagen_types');
        $this->url_layer_types = site_url('layer_types');
        $this->url_rasters_files = site_url('raster_files');
        $this->url_functions = site_url('functions');
        $this->url_process_functions = site_url('process_functions');
        $this->url_process_query_functions = site_url('process_query_functions');
        $this->url_test_python = site_url('Test_python');
        $this->url_process_results_two = site_url('process_functions_results');
        $this->url_raster_layer = site_url('raster_layers');
        $this->url_temp_exp_rules = site_url('temporal_expansion_rules');

        // Urls
        $this->url_entity_admin = $this->_url_site . '/' . strtolower(Entity_Admin::class_name()) . '/';
        $this->url_entity_manage = $this->url_entity_admin . '/manage/';
        $this->url_autocomplete = $this->_url_site . '/r2_search_controller/autocomplete';
        $this->url_search = $this->_url_site . '/r2_search_controller/';


        $this->url_ajax_read_dir = $this->url_process_fields . '/files_in_folder/';        
    }

    public function index() {
        $this->index_data = R2_Landing_Page::get_index_data();
        $this->load_view_with_layout('home');
    }

    /* ------------------------------------------------------------ */
    /* ---------- Protected Functions  ---------------------------  */
    /* ------------------------------------------------------------ */

    /**
     * Inicializa el soporte para lenguaje y traducciones.
     */
    protected function init_language_support() {
        //Soporte de Lenguajes
        if ($this->session->userdata('site_lang')) {
            $languague = $this->session->userdata('site_lang');
        } else {
            $languague = 'spanish';
            $this->session->set_userdata(array('site_lang' => $languague));
        }

        $this->lang->load('translations', $languague);

        $this->load->helper('r2_language');
    }

    /* ----------------------------------------------- */
    /* -------------  Protected Methods  ------------- */
    /* ----------------------------------------------- */

    /**
     * Chequea que la clase exista, sino redirige al login.
     * @param <string> $class
     * @return <boolean>
     */
    protected function check_class_parameter_is_valid($class) {
        if (!class_exists($class)) {
            if ($this->config->config['developing_mode'])
                throw new Exception('La clase: ' . $class . ' no existe.');
            else
                $this->redirect_to_login_page();
            return FALSE;
        }

        $this->class = $class;
        return TRUE;
    }

    protected function id_is_valid($id) {
        if (!(int) $id) {
            $this->error_code = "ERROR - invalid entity: '$id'";
            return FALSE;
        }

        return TRUE;
    }

    protected function list_view_for($class) {

        if (file_exists($this->_views_files_location . $this->list_view . "_" . strtolower($class) . ".php"))
            return $this->list_view . "_" . strtolower($class);
        else
            return $this->list_view;
    }

    protected function form_view_for($class) {
        if (file_exists($this->_views_files_location . $this->form_view . "_" . strtolower($class) . ".php"))
            return $this->form_view . "_" . strtolower($class);
        else
            return $this->form_view;
    }

    protected function delete_view_for($class) {
        if (file_exists($this->_views_files_location . $this->delete_view . "_" . strtolower($class) . ".php"))
            return $this->delete_view . "_" . strtolower($class);
        else
            return $this->delete_view;
    }

    /** Hereda de Abstract
     * Chequea los permisos de usuario, primero si est{a logueado y luego si tiene acceso al menu que quiere entrar
     *
     * @return boolean 
     */
    public function check_user_access() {
        parent::check_user_access();
        return $this->check_menu_acces();
    }

}
