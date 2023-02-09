<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

class Business_objects_translations extends Entity_Admin {

    public $current_lang;
    public $languages;

    public function __construct() {

        // Le mandamos al controller padre el nombre del controller y de la clase que administra
        parent::__construct('business_objects_translations', 'R2_Business_Objects_Translations');
        $this->url_translations = $this->url . '/show_translations/';
        $this->view_list_translations = '/entities/list_business_objects_translation_2';
        $this->current_lang = $this->session->userdata('site_lang') . '_translation';
        $this->languages = [];
        $this->url_change_language = $this->url . '/change_language';
        $this->url_edit = $this->url . '/edit_translation';
        $this->url_action = $this->url . '/save_translation';
        $this->url_show = $this->url . '/show_translation';
    }

    /**
     * Index de la clase
     */
    public function index($selected_lang = '', $success = FALSE) {
        if ($selected_lang) {
            $this->current_lang = $selected_lang;
        }
        $this->url_back = false;
        $class = $this->managed_class;
        $this->instances = (new $class())->not_translate_rows($this->current_lang);
        $this->languages = $this->get_columns($class);

        //para el cartel de success!
        if ($success !== FALSE) {
            switch ($success) {
                case "1": $this->success[] = 'Cambios Guardados con éxito';
                    break;
                default:
                    break;
            }
        }
        $this->load_view_with_layout($this->list_view_for($class));
    }

    /**
     * Graba los cambios en la instancia.
     */
    public function save_translation($selected_lang) {
        $this->current_lang = $selected_lang;
        $class = $this->managed_class;

        $this->instance = $class::new_from_array($this->input->post());

        if ($this->instance->is_valid()) {
            $this->instance->save();
            $this->instance->update_lang_file($this->current_lang);
            redirect($this->url_show . '/' . $this->instance->id . '/' . $this->current_lang . '/1');
        } else {
            $this->form_content = form_content($this->instance);
            $this->load_view_with_layout($this->form_view_for($class));
        }
    }

    /**
     * Muestra una entidad existente
     * @param $class type <entity_class>
     */
    public function show_translation($id, $selected_lang, $success = FALSE) {
        if (!$this->id_is_valid($id)) {
            echo $this->error_code;
            return;
        }

        $class = $this->managed_class;
        $this->current_lang = $selected_lang;
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
    public function edit_translation($id, $selected_lang) {
        if (!$this->id_is_valid($id)) {
            echo $this->error_code;
            return;
        }
        $this->current_lang = $selected_lang;
        $class = $this->managed_class;
        $this->instance = $class::find($id);
        $this->form_content = form_content($this->instance);
        $this->load_view_with_layout($this->form_view_for($class));
    }

    public function show_translations($selected_lang) {
        $class = $this->managed_class;
        $this->current_lang = $selected_lang;
        $this->instances = (new $class())->translate_rows($this->current_lang);

        //para el cartel de success!
        $success = FALSE;

        $this->load_view_with_layout($this->view_list_translations);
    }

    public function get_columns($class) {
        $columns = (new $class())->class_table_columns();
        $languages = [];

        foreach ($columns as $column) {
            if (strpos($column->name, '_translation')) {
                array_push($languages, $column->name);
            }
        }
        return $languages;
    }

    /**
     * Index de la clase
     */
    public function change_language($success = FALSE) {

        $this->url_back = false;
        $this->current_lang = $this->input->post('current_lang');
        $class = $this->managed_class;
        $this->instances = (new $class())->not_translate_rows($this->current_lang);
        $this->languages = $this->get_columns($class);

        //para el cartel de success!
        if ($success !== FALSE) {
            switch ($success) {
                case "1": $this->success[] = 'Cambios Guardados con éxito';
                    break;
                default:
                    break;
            }
        }
        $this->load_view_with_layout($this->list_view_for($class));
    }

}
