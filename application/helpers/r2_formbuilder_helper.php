<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Form Builder 
 * Description:
 *    Clase que permite crear forms a partir una clase que 
 *    herede de MS_DbObject.
 * 
 * @author Peer Programming
 * @package MSoft
 */
#Creo una instancia de CI para cargar el form_helper 
$CI = & get_instance();
$CI->load->helper('form');


/**
 * form_content
 * Este metodo recibe un objeto R2_DbObject y un boolean
 * Arma un formulario con las variables del objeto
 * Si boolean es False Muestra los campos del Form como disabled
 * Si boolean es True se puede editar los campos.
 *
 * @param bool $edit_or_show
 * @param object $aR2DBObject
 *
 * @return string coon el html armado del form
 */
if (!function_exists('form_content')) {

    function form_content(R2_DbObject $aR2DBObject, $edit_or_show = FALSE) {
        global $instance;
        global $form_content;
        global $_wrappedClass;
        global $show;

        $show = $edit_or_show;
        $instance = $aR2DBObject;
        $_wrappedClass = get_class($aR2DBObject);

        _build_form();

        return $form_content;
    }

}
/* ------------------------------------------------------------------------- */
/* ------- Private --------------------------------------------------------- */
/* ------------------------------------------------------------------------- */

/**
 * Por cada columna de la tabla del objeto, arma el formulario del mismo.
 */
if (!function_exists('_build_form')) {

    function _build_form() {
        global $instance;
        global $_wrappedClass;

        _build_primary_key_hidden_input();

        $class = $_wrappedClass;
        $columns_metadata = _columns_metada($class);
        foreach ($columns_metadata as $each_column) {
            if (!in_array($each_column->name, $instance->non_editable_variables()))
                _build_input_for($each_column);
        }
    }

}
/**
 * Hiden Input con el id del objeto.
 */
if (!function_exists('_build_primary_key_hidden_input')) {

    function _build_primary_key_hidden_input() {
        global $instance;
        global $form_content;

        $form_content.= form_hidden(array($instance->get_primary_key() => $instance->primary_key_value()));
    }

}

/**
 * Segun el tipo de columna, decide que tipo de input usar para la bariable
 * @param <array> $column_metadata
 */
if (!function_exists('_build_input_for')) {

    function _build_input_for($column_metadata) {
        global $_wrappedClass;
        global $show;
        if ($show)
            $input_data['disabled'] = 1;
        else
            $input_data = Array();

        $class = $_wrappedClass;
        $referenced_classes = $class::references_class();

        //Modifico lo que va a ser el label name
        $column_metadata->label_name = ucwords(str_replace("_", " ", $column_metadata->name));


        if (array_key_exists($column_metadata->name, $referenced_classes)) {
            _build_referenced_class_select_input($column_metadata, $referenced_classes[$column_metadata->name], $input_data);
            return;
        }

        if (in_array($column_metadata->type, array('boolean'))) {
            _build_checkbox_input($column_metadata, $input_data);
            return;
        }

        if (strpos($column_metadata->name, 'email') !== false) {
            _build_email_input($column_metadata, $input_data);
            return;
        }

        if (strpos($column_metadata->name, 'password') !== false) {
            _build_password_input($column_metadata, $input_data);
            return;
        }

        if (in_array($column_metadata->type, array('character', 'character varying'))) {
            _build_varchar_input($column_metadata, $input_data);
            return;
        }

        if (in_array($column_metadata->type, array('text'))) {
            _build_textarea_input($column_metadata, $input_data);
            return;
        }

        if (in_array($column_metadata->type, array('integer', 'bigint', 'smallint'))) {
            _build_integer_input($column_metadata, $input_data);
            return;
        }

        if (in_array($column_metadata->type, array('real', 'double precision', 'numeric'))) {
            _build_floating_point_input($column_metadata, $input_data);
            return;
        }

        if (in_array($column_metadata->type, array('timestamp without time zone', 'date'))) {
            _build_date_input($column_metadata, $input_data);
            return;
        }
    }

}

if (!function_exists('_build_email_input')) {

    function _build_email_input($metadata, $data = Array()) {
        global $instance;
        $column = $metadata->name;
        $data['id'] = $metadata->name;
        $data['name'] = $metadata->name;
        $data['class'] = 'form-control';
        $data['value'] = $instance->$column;
        $data['maxlength'] = $metadata->max_length;
        $data['type'] = 'email';

        if ($metadata->is_nulleable == 'f')
            $data['required'] = 1;

        _build_input($metadata, $data);
    }

}

if (!function_exists('_build_password_input')) {

    function _build_password_input($metadata, $data = Array()) {
        global $instance;

        $column = $metadata->name;
        $data['id'] = $metadata->name;
        $data['name'] = $metadata->name;
        $data['class'] = 'form-control';
        $data['value'] = ''; //El password encriptado no se deberia mostrar NUNCA!
        $data['maxlength'] = $metadata->max_length;
        $data['type'] = 'password';

        if ($metadata->is_nulleable == 'f')
            $data['required'] = 1;

        _build_input($metadata, $data);

        $metadata->label_name = 'Password Confirm';
        $data['id'] = 'password_confirm';
        $data['name'] = 'password_confirm';
        $data['class'] = 'form-control';
        $data['value'] = ''; //El password encriptado no se deberia mostrar NUNCA!
        $data['maxlength'] = $metadata->max_length;
        $data['type'] = 'password';

        if ($metadata->is_nulleable == 'f')
            $data['required'] = 1;

        _build_input($metadata, $data);
    }

}

if (!function_exists('_build_varchar_input')) {

    function _build_varchar_input($metadata, $data = Array()) {
        global $instance;

        if ((isset($metadata->max_length)) and ( $metadata->max_length > 100)) {
            _build_textarea_input($metadata, $data);
            return;
        }

        $column = $metadata->name;
        $data['id'] = $metadata->name;
        $data['name'] = $metadata->name;
        $data['class'] = 'form-control';
        $data['value'] = $instance->$column;
        $data['maxlength'] = $metadata->max_length;

        if ($metadata->is_nulleable == 'f')
            $data['required'] = 1;

        _build_input($metadata, $data);
    }

}

if (!function_exists('_build_floating_point_input')) {

    function _build_floating_point_input($metadata, $data = Array()) {
        global $instance;

        $column = $metadata->name;
        $data['id'] = $metadata->name;
        $data['name'] = $metadata->name;
        $data['class'] = 'form-control';
        $data['value'] = $instance->$column;
        $data['pattern'] = "\d*.\d*";

        if ($metadata->is_nulleable == 'f')
            $data['required'] = 1;

        _build_input($metadata, $data);
    }

}

if (!function_exists('_build_integer_input')) {

    function _build_integer_input($metadata, $data = Array()) {
        global $instance;
        $column = $metadata->name;
        $data['id'] = $metadata->name;
        $data['name'] = $metadata->name;
        $data['class'] = 'form-control';
        $data['value'] = $instance->$column;
        $data['type'] = 'number';
        $data['pattern'] = "\d*";

        //Busca en la instancia valores maximos y minimos para la columna
        if ($instance->get_config($metadata->name . '_max') !== FALSE) {
            $data['max'] = $instance->get_config($metadata->name . '_max');
        }

        if ($instance->get_config($metadata->name . '_min') !== FALSE) {
            $data['min'] = $instance->get_config($metadata->name . '_min');
        }

        if ($metadata->is_nulleable == 'f')
            $data['required'] = 1;

        _build_input($metadata, $data);
    }

}

if (!function_exists('_build_input')) {

    function _build_input($metadata, $data) {
        global $form_content;
        $attributes = array('class' => 'col-md-4 control-label');

        $form_content.='<div class="form-group">';
        $form_content.= form_label($metadata->label_name, $metadata->name, $attributes);
        $form_content.='<div class="col-md-8">';
        $form_content.= form_input($data);
        $form_content.='</div>';
        $form_content.='</div>';
    }

}

if (!function_exists('_build_textarea_input')) {

    function _build_textarea_input($metadata, $data = Array()) {
        global $instance;
        global $form_content;

        $column = $metadata->name;
        $data['id'] = $metadata->name;
        $data['name'] = $metadata->name;
        $data['class'] = 'form-control';
        $data['value'] = $instance->$column;
        $data['maxlength'] = $metadata->max_length;

        if ($metadata->is_nulleable == 'f')
            $data['required'] = 1;
        $attributes = array('class' => 'col-md-4 control-label');
        $form_content.='<div class="form-group">';
        $form_content.= form_label($metadata->label_name, $metadata->name, $attributes);
        $form_content.='<div class="col-md-8">';
        $form_content.= form_textarea($data);
        $form_content.='</div>';
        $form_content.='</div>';
    }

}

if (!function_exists('_build_checkbox_input')) {

    function _build_checkbox_input($metadata, $data = Array()) {
        global $instance;
        global $form_content;

        $column = $metadata->name;
        $data['id'] = $metadata->name;
        $data['name'] = $metadata->name;
        $data['value'] = 'true';

        // Uso la técnica de agregar un valor hidden para el false porque sinó el formulario
        // no envía el valor si no está chequeado el checkbox.
        $form_content.= form_hidden(array($metadata->name => 'false'));

        if ($instance->evaluate_variable_as_boolean($instance->$column))
            $data['checked'] = true;


        $form_content.='<div class="form-group">';
        $form_content.='<label class="col-md-4 control-label" for="' . $metadata->name . '">';
        $form_content.= '<b>' . $metadata->label_name . '</b>';
        $form_content.='</label>';
        $form_content.='<div class="col-md-8 checkbox">';
        $form_content.= form_checkbox($data);
        $form_content.='</div>';
        $form_content.='</div>';
    }

}

if (!function_exists('_build_referenced_class_select_input')) {

    function _build_referenced_class_select_input($metadata, $referenced_class, $input_data = Array()) {
        global $instance;
        global $form_content;
        $values = array();

        $column = $metadata->name;
        $extra_string = ' class="form-control" ';
        if (isset($input_data['disabled']))
            $extra_string.= $extra_string . ' disabled';

        foreach ($instance->all_active_of($referenced_class) as $each) // cargo el combo con las entities activas
            $values[(string) $each->id] = $each->display_value();

        if (!isset($instance->$column)) {
            if ($metadata->is_nulleable == 't')
                $values[null] = 'N/A';
            $instance->$column = null;
        }

        $form_content.='<div class="form-group">';
        $attributes = array('class' => 'col-md-4 control-label');
        $form_content.= form_label(ucfirst($referenced_class::class_display_name()), $metadata->name, $attributes);
        $form_content.='<div class="col-md-8">';
        $form_content.= form_dropdown($column, $values, $instance->$column, $extra_string);
        $form_content.='</div>';
        $form_content.='</div>';
    }

}
/**
 * Requiere que este cargado jQuery-UI
 * @param <array> $metadata
 * @param <array> $data
 */
if (!function_exists('_build_date_input')) {

    function _build_date_input($metadata, $data = Array()) {
        global $instance;
        global $form_content;

        $column = $metadata->name;

        $form_content.= '
		<script>
		$(function() {
		$( "#' . $metadata->name . '" ).datepicker({dateFormat: "dd-mm-yy"});
		$( "#' . $metadata->name . '" ).datepicker( "option", "dayNamesMin", ["Do", "Lu", "Ma", "Mi", "Ju", "Vi", "Sa"] );
		$( "#' . $metadata->name . '" ).datepicker( "option", "monthNames", ["Enero","Febrero","Marzo","Abril","Mayo","Junio","Julio","Agosto","Septiembre","Octubre","Noviembre","Diciembre"] );
		';

        if (isset($instance->$column)) {

            $date = ($instance->$column != '' ? DateTime::createFromFormat('Y-m-d', $instance->$column) : DateTime::createFromFormat('Y-m-d',date('Y-m-d')));
                     
            $form_content.= '$( "#' . $metadata->name . '" ).datepicker( "setDate", new Date(';
            $form_content.= $date->format('Y');
            $form_content.= ',';
            $form_content.= $date->format('m') - 1; // AL mes en javascript hay que restarle uno
            $form_content.= ',';
            $form_content.= $date->format('d');
            $form_content.= '));';
        }

        $form_content.= '});</script>';

        $data['id'] = $metadata->name;
        $data['name'] = $metadata->name;
        $data['class'] = 'form-control';
        $data['value'] = $instance->$column;
        $data['maxlength'] = $metadata->max_length;

        if ($metadata->is_nulleable == 'f')
            $data['required'] = 1;

        _build_input($metadata, $data);
    }

}

/**
 * Colabora con el controller para obtener la metadata
 *    de las columnas de la clase en cuestión.
 * 
 * @return <mixed>
 */
if (!function_exists('_columns_metada')) {

    function _columns_metada($class) {
        return $class::class_table_columns_postgres();
    }

}




/* End of file formbuilder_helper.php */
/* Location: ./application/helpers/formbuilder_helper.php */