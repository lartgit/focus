<?php

if (!defined('BASEPATH'))
   exit('No direct script access allowed');

/**
 * Description of R2_ActionModel
 *    Acciones que realiza una entidad en un determinado momento.
 *
 * @author <NArias>
 * @version <2015-08-23>
 * @package <r2>
 * @abstract
 * 
 */
class R2_ActionModel extends R2_DbObject {
   /* {2015-08-23} */
   /* Variables Static de Configuración - Es responsabilidad de las subclases completarlas o redefinirlas */
   /* Se deben definir funciones static (de clase) para acceder a las mismas udando el prefijo "class_" */
   /* Se deben definir funciones no static (de instancia) para acceder a las mismas udando el prefijo "get_" */

   /* Variables no estaticas de la clase */

   public $entity_id;   // id de la entidad asociada.
   public $action_date; // Registra la fecha y hora de cuando se realizó la acción.

   // Construct

   public function __construct() {
      parent::__construct();
   }

   // Funciones
   function required_variables() {
      //return array('entity_id', 'action_date');
      return array();
   }

   public function referenced_entity_id() {
      return $this->entity_id;
   }

   // To string
   public function __toString() {
      return $this->display_value() . ' (' . static::class_display_name() . ' at: ' . $this->action_date . ')';
   }

   /**
    * Retorna las acciones junto con las entidades.
    * 
    * @return type
    */
   public static function all_with_entities() {

      $results = static::all();
      if (!empty($results)) {
         // Se recopilan las PK de las entidades 
         $actionClass = get_called_class();
         $actionEntityClass = $actionClass::$_entity_class;

         foreach ($results as $each)
            $entitys_to_get[] = $each->referenced_entity_id();

         // Se consultan las entidades
         $entitys = $actionEntityClass::find_ids(array_unique($entitys_to_get));
         $entities_hash = Array();
         foreach ($entities as $each)
            $entities_hash[$each->id()] = $each;

         // Se asignan las entidades a los resultados
         foreach ($results as $eachAction)
            $eachAction->entity = $entities_hash[$eachAction->referenced_entity_id()];
      }

      return $results;
   }

}
