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
class MS_HTML_Class_Wrapper {

   protected $wrappedClass;
   protected $controller;
   public $html_entity_table_class = '_std_table';
   public $html_entity_form_class = 'admin-form';

   public function __construct($objectClass, CI_Controller $controller) {
      $this->wrappedClass = $objectClass;
      $this->controller = $controller;
   }

   public function show() {
      $class = $this->wrappedClass;

      $html = "<table class='$this->html_entity_table_class'>";
      $html.= "<tbody>";
      $html.= "<tr><th>Nombre:</th><td>" . $class::class_display_name() . "</td></tr>";
      $html.= "<tr><th>Instancias:</th><td>" . $class::count() . "</td></tr>";
      $html.= "<tr><th>Columnas:</th>";
      $html.= "<td><ul>";
      foreach ($class::class_table_columns() as $each)
         $html.= "<li>" . $each->name . "</li>";
      $html.= "</ul></td></tr>";
      $html.= "<tr><th>Última Modificación:</th><td>" . $class::last_modified() . "</td></tr>";
      
      $class_references = $class::references_class();
      
      if(! empty($class_references)){
         $html.= "<tr><th>Referencia a:</th><td><ul>";
         
         foreach ($class_references as $column => $class )
            $html .= '<li>
                        <a style="color:blue" href="'.$this->controller->url_show_class_for($class).'">'.$class.'</a>
                     </li>';
         
            $html.= "</ul></td></tr>";
      }
      
      $html.= "</tbody>";
      $html.= "</table>";
      return $html;
   }

}

?>
