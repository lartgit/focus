<?php

if (!defined('BASEPATH'))
   exit('No direct script access allowed');

/**
 * Description:
 *    Clase que permite crear forms a partir una clase que 
 *    herede de MS_DbObject.
 * 
 * @author NArias
 * @package MSoft
 */
class DB_Object_Form_Builder {

   protected $wrappedClass;
   protected $wrappedObject;
   protected $controller;
   protected $columns_metada;
   protected $attributes = '';
   public $html_entity_table_class = '_std_table';
   public $html_entity_form_class = 'admin-form';
   public $admin_input_css_class = 'admin-input';
   public $admin_textarea_css_class = 'admin-textarea';
   public $is_show = FALSE;
   public $form_content = '';
   

   public function __construct(MS_DbObject $aMsDBObject, $controller) {
      //$this->wrappedObject = $aMsDBObject;
      $this->controller = $controller;
      $this->instance = $aMsDBObject;
      $this->wrappedClass = get_class($aMsDBObject);
      $this->controller->load->helper('form');
   }

   public function form_content() {
      $this->build_form();
      return $this->form_content;
   }

   /* ------------------------------------------------------------------------- */
   /* ------- Private --------------------------------------------------------- */
   /* ------------------------------------------------------------------------- */

   /**
    * Por cada columna de la tabla del objeto, arma el formulario del mismo.
    */
   private function build_form() {
      $this->build_primary_key_hidden_input();

      $columns_metadata = $this->columns_metada();

      foreach ($columns_metadata as $each_column) {
         if (!in_array($each_column->name, $this->instance->non_editable_variables()))
            $this->build_input_for($each_column);
      }
   }

   /**
    * Hiden Input con el id del objeto.
    */
   private function build_primary_key_hidden_input() {
      $this->form_content.= form_hidden(array($this->instance->get_primary_key() => $this->instance->primary_key_value()));
   }

   /**
    * Segun el tipo de columna, decide que tipo de input usar para la bariable
    * @param <array> $column_metadata
    */
   private function build_input_for($column_metadata) {

      if (isset($this->show))
         $input_data['disabled'] = 1;
      else
         $input_data = Array();

      $class = $this->wrappedClass;
      $referenced_classes = $class::references_class();
      
      //Modifico lo que va a ser el label name
      $column_metadata->label_name = ucwords(str_replace("_"," ",$column_metadata->name));
      

      if (array_key_exists($column_metadata->name, $referenced_classes)) {
         $this->build_referenced_class_select_input($column_metadata, $referenced_classes[$column_metadata->name], $input_data);
         return;
      }

      if (in_array($column_metadata->type, array('boolean'))) {
         $this->build_checkbox_input($column_metadata, $input_data);
         return;
      }

      if (strpos($column_metadata->name, 'email') !== false) {
         $this->build_email_input($column_metadata, $input_data);
         return;
      }

      if (strpos($column_metadata->name, 'password') !== false) {
         $this->build_password_input($column_metadata, $input_data);
         return;
      }

      if (in_array($column_metadata->type, array('character', 'character varying'))) {
         $this->build_varchar_input($column_metadata, $input_data);
         return;
      }

      if (in_array($column_metadata->type, array('text'))) {
         $this->build_textarea_input($column_metadata, $input_data);
         return;
      }

      if (in_array($column_metadata->type, array('integer', 'bigint', 'smallint'))) {
         $this->build_integer_input($column_metadata, $input_data);
         return;
      }

      if (in_array($column_metadata->type, array('real', 'double precision', 'numeric'))) {
         $this->build_floating_point_input($column_metadata, $input_data);
         return;
      }

      if (in_array($column_metadata->type, array('timestamp without time zone', 'date'))) {
         $this->build_date_input($column_metadata, $input_data);
         return;
      }
   }

   private function build_email_input($metadata, $data = Array()) {

      $column = $metadata->name;
      $data['id'] = $metadata->name;
      $data['name'] = $metadata->name;
      $data['class'] = 'form-control';
      $data['value'] = $this->instance->$column;
      $data['maxlength'] = $metadata->max_length;
      $data['type'] = 'email';

      if ($metadata->is_nulleable == 'f')
         $data['required'] = 1;

      $this->build_input($metadata, $data);
   }

   private function build_password_input($metadata, $data = Array()) {

      $column = $metadata->name;
      $data['id'] = $metadata->name;
      $data['name'] = $metadata->name;
      $data['class'] = 'form-control';
      $data['value'] = $this->instance->$column;
      $data['maxlength'] = $metadata->max_length;
      $data['type'] = 'password';

      if ($metadata->is_nulleable == 'f')
         $data['required'] = 1;

      $this->build_input($metadata, $data);
   }

   private function build_varchar_input($metadata, $data = Array()) {

      if ((isset($metadata->max_length)) and ($metadata->max_length > 100)) {
         $this->build_textarea_input($metadata, $data);
         return;
      }

      $column = $metadata->name;
      $data['id'] = $metadata->name;
      $data['name'] = $metadata->name;
      $data['class'] = 'form-control';
      $data['value'] = $this->instance->$column;
      $data['maxlength'] = $metadata->max_length;

      if ($metadata->is_nulleable == 'f')
         $data['required'] = 1;

      $this->build_input($metadata, $data);
   }

   private function build_floating_point_input($metadata, $data = Array()) {

      $column = $metadata->name;
      $data['id'] = $metadata->name;
      $data['name'] = $metadata->name;
      $data['class'] = 'form-control';
      $data['value'] = $this->instance->$column;
      $data['pattern'] = "\d*.\d*";

      if ($metadata->is_nulleable == 'f')
         $data['required'] = 1;

      $this->build_input($metadata, $data);
   }

   private function build_integer_input($metadata, $data = Array()) {

      $column = $metadata->name;
      $data['id'] = $metadata->name;
      $data['name'] = $metadata->name;
      $data['class'] = 'form-control';
      $data['value'] = $this->instance->$column;
      $data['type'] = 'number';
      $data['pattern'] = "\d*";

      if ($metadata->is_nulleable == 'f')
         $data['required'] = 1;

      $this->build_input($metadata, $data);
   }

   private function build_input($metadata, $data) {
      
      $this->form_content.='<script></script>';

      $this->attributes = array('class' => 'col-md-4 control-label');

      $this->form_content.='<div class="form-group">';
      $this->form_content.= form_label($metadata->label_name, $metadata->name,$this->attributes);
      $this->form_content.='<div class="col-md-8">';
      $this->form_content.= form_input($data);
      $this->form_content.='</div>';
      $this->form_content.='</div>';
   }

   private function build_textarea_input($metadata, $data = Array()) {

      $column = $metadata->name;
      $data['id'] = $metadata->name;
      $data['name'] = $metadata->name;
      $data['class'] = 'form-control';
      $data['value'] = $this->instance->$column;
      $data['maxlength'] = $metadata->max_length;

      if ($metadata->is_nulleable == 'f')
         $data['required'] = 1;
      $this->attributes = array('class'=>'col-md-4 control-label');
      $this->form_content.='<div class="form-group">';
      $this->form_content.= form_label($metadata->label_name, $metadata->name,$this->attributes);
      $this->form_content.='<div class="col-md-8">';      
      $this->form_content.= form_textarea($data);
      $this->form_content.='</div>';
      $this->form_content.='</div>';      
   }

   private function build_checkbox_input($metadata, $data = Array()) {

      $column = $metadata->name;
      $data['id'] = $metadata->name;
      $data['name'] = $metadata->name;
      $data['value'] = 'true';

      // Uso la técnica de agregar un valor hidden para el false porque sinó el formulario
      // no envía el valor si no está chequeado el checkbox.
      $this->form_content.= form_hidden(array($metadata->name => 'false'));

      if ($this->instance->evaluate_variable_as_boolean($this->instance->$column))
         $data['checked'] = true;


      $this->form_content.='<div class="form-group">';
      $this->form_content.='<label class="col-md-4 control-label">';
      $this->form_content.= '<b>' . $metadata->label_name . '</b>';
      $this->form_content.='</label>';
      $this->form_content.='<div class="col-md-8 checkbox">';
      $this->form_content.= form_checkbox($data);
      $this->form_content.='</div>';
      $this->form_content.='</div>';
   }

   private function build_referenced_class_select_input($metadata, $referenced_class, $input_data = Array()) {

      $column = $metadata->name;
      $extra_string = ' class="form-control" ';
      if (isset($input_data['disabled']))
         $extra_string.= $extra_string . ' disabled';

      foreach ($this->instance->all_of($referenced_class) as $each)
         $values[(string) $each->id] = $each->display_value();


      if (!isset($this->instance->$column)) {
         if ($metadata->is_nulleable == 't')
            $values[null] = 'N/A';
         $this->instance->$column = null;
      }

      $this->form_content.='<div class="form-group">';
      $this->attributes = array('class'=>'col-md-4 control-label');
      $this->form_content.= form_label(ucfirst($referenced_class::class_display_name()), $metadata->name,$this->attributes);
      $this->form_content.='<div class="col-md-8">';
      $this->form_content.= form_dropdown($column, $values, $this->instance->$column, $extra_string);
      $this->form_content.='</div>';
      $this->form_content.='</div>';      
   }

   /**
    * Requiere que este cargado jQuery-UI
    * @param <array> $metadata
    * @param <array> $data
    */
   private function build_date_input($metadata, $data = Array()) {

      $column = $metadata->name;

      $this->form_content.= '
      <script>
   $(function() {
      $( "#' . $metadata->name . '" ).datepicker({dateFormat: "dd-mm-yy"});
      $( "#' . $metadata->name . '" ).datepicker( "option", "dayNamesMin", ["Do", "Lu", "Ma", "Mi", "Ju", "Vi", "Sa"] );
      $( "#' . $metadata->name . '" ).datepicker( "option", "monthNames", ["Enero","Febrero","Marzo","Abril","Mayo","Junio","Julio","Agosto","Septiembre","Octubre","Noviembre","Diciembre"] );
                ';

      if (isset($this->instance->$column)) {
         $date = DateTime::createFromFormat('Y-m-d', $this->instance->$column);

         $this->form_content.= '$( "#' . $metadata->name . '" ).datepicker( "setDate", new Date(';
         $this->form_content.= $date->format('Y');
         $this->form_content.= ',';
         $this->form_content.= $date->format('m') - 1; // AL mes en javascript hay que restarle uno
         $this->form_content.= ',';
         $this->form_content.= $date->format('d');
         $this->form_content.= '));';
      }
      $this->form_content.= '});</script>';

      $data['id'] = $metadata->name;
      $data['name'] = $metadata->name;
      $data['class'] = 'form-control';
      $data['value'] = $this->instance->$column;
      $data['maxlength'] = $metadata->max_length;

      if ($metadata->is_nulleable == 'f')
         $data['required'] = 1;

      $this->build_input($metadata, $data);
   }

   /**
    * Colabora con el controller para obtener la metadata
    *    de las columnas de la clase en cuestión.
    * 
    * @return <mixed>
    */
   private function columns_metada() {
      return $this->controller->table_columns_of($this->wrappedClass);
   }

}

?>
