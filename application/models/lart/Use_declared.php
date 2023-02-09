<?php

if (!defined('BASEPATH'))
   exit('No direct script access allowed');

/**
 * Description:
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class Use_declared extends R2_DbObject {

   /**  Variables Static de Configuración del Model */
   protected static $_table_name = 'use_declareds';
   protected static $_display_name = 'uso_declarado';
   protected static $_plural_name = 'usos_declarado';
   protected static $_display_column = 'name';     // Columna para display.

   /** Variables Públicas del Model */
   public $name;
   public $description;

   /** Variables private */

   /** Construct */
   public function __construct() {
      parent::__construct();

   }
   public function required_variables() {
    return array_merge(parent::required_variables(), array('name'));
   }

   //devuelve un array() de arrays de objetos
   public function related_with(){
       return array($this->use_concretes(),$this->declarations(),$this->temporal_expansion_rules());
   }

   public function is_deleteable() {
      // if ($this->use_concretes())
      //    return false;
      return true;
   }


   //ESTO NO ESTA APLICADO TODAVÍA, no hay tabla de relacion entre estas tablas

    public function available_use_concretes() {
      if (!isset($this->available_use_concretes))
         $this->available_use_concretes = $this->db->query(
                         "SELECT * FROM use_concretes WHERE id NOT IN
                    (SELECT concrete_id FROM concretes_by_declareds WHERE declared_id = $this->id) ORDER BY name"
                 )->result('Use_concret');
         //$this->available_use_concretes = use_concretes_by_groups::where(Array('user_group_id'=>$this->id));

      return $this->available_use_concretes;
   }

   public function use_concretes() {
      if (!isset($this->use_concretes))
         $this->use_concretes = $this->db->query(
                         "SELECT * FROM use_concretes WHERE id IN
                        (SELECT concrete_id FROM concretes_by_declareds WHERE declared_id = $this->id) ORDER BY name"
                 )->result('Use_concret');


      return $this->use_concretes;
   }

   //capaz esto convenga refactorizarlo instanciando groups_by_options y haciendo un save
   // y agregandole la posibilidad de hacer delete
   public function add_or_remove_concrete_by_id($concrete_id){
      foreach($this->use_concretes() as $each)
         if($each->id == $concrete_id)
            $concrete = $each;

      if(isset($concrete)){
            $this->instance = Concretes_by_Declared::where(Array('declared_id'=>$this->id, 'concrete_id'=>$concrete_id));
           //es un array
            $this->instance[0]->destroy();
      }
      else{
        $values = array('declared_id' => $this->id,
                         'concrete_id' => $concrete_id);

        $this->instance = Concretes_by_Declared::new_from_array($values);
        if ($this->instance->is_valid())
            $this->instance->save();
      }

   }

   public function declarations() {
      if (!isset($this->declarations))
         $this->declarations = Declaration::where(Array('use_declared_id' => $this->id));


      return $this->declarations;
   }

   public function temporal_expansion_rules() {
      if (!isset($this->temporal_expansion_rules))
         $this->temporal_expansion_rules = Temporal_expansion_rule::where(Array('use_declared_id' => $this->id));


      return $this->temporal_expansion_rules;
   }

}
