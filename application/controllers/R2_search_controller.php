<?php

if (!defined('BASEPATH')) {
    exit('No direct script access allowed');
}

class R2_search_controller extends R2_abstract_controller {

    public $_view_header = '/main/header';
    public $_view_footer = '/main/footer';
    public $_view_layout = '/main/layout';
    public $_view_side_menu = '/main/side_menu';
    public $_views_files_location = "./application/views/";

    public function __construct() {
        parent::__construct();
        // Inicializamos el soporte para las traducciones.
        $this->init_language_support();
        $this->load->model('r2/R2_search');
        $this->load->helper('r2_formbuilder');
        $this->url_show = $this->_url_site . '/r2_search_controller/show_obj/';
        $this->url_autocomplete = $this->_url_site . '/r2_search_controller/autocomplete';
        $this->url_search = $this->_url_site . '/r2_search_controller/';
    }

    public function index() {

        $this->instances = $this->R2_search->find_alike($this->input->post('search'));

        $this->load_view_with_layout('list_search');
    }

    public function autocomplete() {
        $search_string = $this->input->post('q');
        echo json_encode($this->R2_search->find_alike($search_string));
    }

    public function show_obj($id) {
        $values = explode('_', $id);

        $obj_class = $values[1];
        $object = $obj_class::find($values[0]);
        $this->show = TRUE;
        $this->instance = $object;

        $this->form_content = form_content($this->instance, $this->show);

        //para el cartel de success!
        $success = false;

        $this->class_name = $obj_class::class_display_name();
        echo "<h3>" . $this->class_name . "</h3> <br/>";
        echo $this->form_content;
    }

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

}
