<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * CodeIgniter -> MS_Languag Helper
 * @author		NArias(MSoft)//Aramirez(R2Soft)
 */
// ------------------------------------------------------------------------

/**
 * Lang Function
 *
 * Usa el soporte de lenguagje de CI para poder traducir
 *
 * @access	public
 * @param	string	the language line
 * @param	string	the id of the form element
 * @return	string
 */
$ms_bo_traductions = array();

if (!function_exists('lang')) {

    function lang($index)
    {
        global $ms_bo_traductions;
        $CI =& get_instance();

        #Busco en el Archivo de language
        $line = $CI->lang->line($index);

        if (($line != '' ) AND ( $line != NULL))
            return $line;


        if (!$ms_bo_traductions || !count($ms_bo_traductions)) {
            #Levantamos la tabla
            _load_ms_bo_traductions_from_db();
        }

        $line = _bo_line($index);

        if (!empty($line)) {
            return $line;
        } elseif ($line === FALSE) {
            #Si no lo encontramos en la tabla hacemos el update
            _update_ms_bo_traductions($index);
        }

        return "@" . $index;
    }

}

if (!function_exists('_bo_line')) {

    function _bo_line($index = '')
    {
        global $ms_bo_traductions;

        if ($index === '' OR ( isset($ms_bo_traductions[$index]) AND empty($ms_bo_traductions[$index])))
            return '';

        if (!isset($ms_bo_traductions[$index]))
            return FALSE;

        return $ms_bo_traductions[$index];
    }

}

if (!function_exists('_update_ms_bo_traductions')) {

    function _update_ms_bo_traductions($index)
    {
        global $ms_bo_traductions;
        $CI =& get_instance();

        $CI->load->database();
        $CI->load->model('r2/r2_business_objects_translations');
        $CI->r2_business_objects_translations->new_from_array(array('current_name' => $index))->save();
        $ms_bo_traductions[$index] = '';
    }

}

if (!function_exists('_load_ms_bo_traductions_from_db')) {

    function _load_ms_bo_traductions_from_db()
    {
        global $ms_bo_traductions;
        $CI =& get_instance();
        $CI->load->database();
        $CI->load->model('r2/r2_business_objects_translations');

        $CI->db->start_cache();
        $translations = $CI->r2_business_objects_translations->all();
        $CI->db->stop_cache();

        $CI->db->flush_cache();

        $language = $CI->session->userdata('site_lang');
        $translation_column = $language . '_translation';

        foreach ($translations as $row) {
            $ms_bo_traductions[$row->current_name] = $row->$translation_column;
        }
    }

}


