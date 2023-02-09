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
class MS_HTML_Object_Wrapper {

   protected $wrappedClass;
   protected $wrappedObject;
   protected $controller;
   protected $columns_metada;
   public $html_entity_table_class = '_std_table';
   public $html_entity_form_class = 'admin-form';
   public $admin_input_css_class = 'admin-input';
   public $admin_textarea_css_class = 'admin-textarea';

   public function __construct(MS_DbObject $aMsDBObject, CI_Controller $controller) {
      $this->wrappedObject = $aMsDBObject;
      $this->controller = $controller;
      $this->wrappedClass = get_class($aMsDBObject);

      $this->controller->load->helper('form');
   }

   public function show() {
      return $this->build_form(array('disabled' => 1));
   }

   public function edit() {
      return $this->build_form(NULL, TRUE);
   }

   /* ------------------------------------------------------------------------- */
   /* ------- Private --------------------------------------------------------- */
   /* ------------------------------------------------------------------------- */

   /**
    * Colabora con el controller para obtener la metadata
    *    de las columnas de la clase en cuestión.
    * 
    * @return <mixed>
    */
   private function columns_metada() {
      return $this->controller->table_columns_postgres_of($this->wrappedClass);
   }

   /**
    * Funcion encargada de armar el form.
    * 
    * @param type $aditional_input_attributes
    * @param type $showSubmitButton
    * @return type
    */
   private function build_form($aditional_input_attributes = NULL, $showSubmitButton = FALSE) {
      $metadata = $this->columns_metada();

      $formAttribs = Array('id' => '1234');

      $form = '<br>';
      $form .= form_open($this->controller->url_save_edit_for($this->wrappedObject), $formAttribs);
      $form .= form_fieldset('', array('class' => $this->html_entity_form_class, 'style' => 'width:100%;'));
      $form .= form_hidden(array($this->wrappedObject->get_primary_key() => $this->wrappedObject->primary_key_value()));
      $form .= "<table><tbody>";

      foreach ($metadata as $each) {
         $form .="<tr><td>";
         $form .="<label> $each->name :</label>";
         $form .="</td><td>";
         $form .= $this->form_input_for($each, $aditional_input_attributes);
         $form .="</td></tr>";
      }

      $form .= '</tbody></table>';

      if ($showSubmitButton)
         $form .= '<br>' . form_submit(array(), 'Guardar');
      else
         $form .= '<br><br>';

      $form .= form_fieldset_close();
      $form .= form_close();
      return $form;
   }

   private function form_input_for($metadata, $aditional_attributes = NULL) {

      $html = '';
      $column = $metadata->name;

      $data = array(
          'name' => $metadata->name,
          'id' => $metadata->name,
          'class' => $this->admin_input_css_class,
          'value' => $this->wrappedObject->$column
      );

      $non_editable_vars = $this->wrappedObject->non_editable_variables();

      // Si le mando atributios adicionales los agrego atodos los inputs
      if ($aditional_attributes) {
         $data = array_merge($data, $aditional_attributes);
      }

      // Si es primary key o está rotulada en la clase como no editable:
      if (($metadata->name == $this->wrappedObject->get_primary_key())
              or (in_array($metadata->name, $non_editable_vars))) {
         $data['disabled'] = 1;
         return form_input($data);
      }

      // Si es boolean tiene un comportamiento diferencial
      if ($metadata->type == 'boolean') {
         $data2 = $data;
         $data2['value'] = 'TRUE';
         $data2['type'] = 'hidden';
         $data2['value'] = 'FALSE';
         $data2['checked'] = 'checked';


         $html .= form_checkbox($data2);
         $data['value'] = 'TRUE';
         $data['class'] = 'admin-checkbox';

         if ($this->wrappedObject->$column == 't')
            $data['checked'] = 'checked';

         $html .= form_checkbox($data);
         return $html;
      }
      else {
         if ($metadata->is_nulleable == 'f')
            $data['required'] = 1;
      }


      // Si es de campo texto o varchar muy grande se usa un textarea
      if (($metadata->type == 'text')
              or (($metadata->type = 'character varying') and ($metadata->max_length > 100))) {

         $data['class'] = $this->admin_textarea_css_class;
         return form_textarea($data);
      }

      // Si no cumplió con estos casos se revisan las relaciones de la clase.
      $class = $this->wrappedClass;
      $class_references = $class::references_class();
      foreach ($class_references as $each_column => $each_class) {
         //echo '<br>'.$each_column. ' y '.$column;
         if ($column == $each_column) {

            $values = Array();
            $object = $each_class::find($this->wrappedObject->$each_column);
            
            if (isset($data['disabled'])) {
               $values[$object->primary_key_value()] = $object;
               return form_dropdown($column, $values, $object->display_value(), 'class="admin-select" disabled=1');
            } else {

               foreach ($each_class::all() as $eachObject)
                  $values[$eachObject->primary_key_value()] = $eachObject;
            }
            return form_dropdown($column, $values, $object->display_value(), 'class="admin-select"');
         }
      }


      return form_input($data);
   }

}

?>
