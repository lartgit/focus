<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class Date extends R2_DbObject {

    /**  Variables Static de Configuración del Model */
    protected static $_table_name = 'dates';
    protected static $_display_name = 'Fecha';
    protected static $_plural_name = 'Fechas';
    protected static $_display_column = 'date';

    /** Variables Públicas del Model */
    public $date;
    public $set_id;

    /** Variables private */
    // public $versions;

    /** Construct */
    public function __construct() {
        parent::__construct();
    }

    public static function new_from_array($asociativeArray = array()) {
        $new_instance = parent::new_from_array($asociativeArray);


        if (isset($new_instance->date))
            $new_instance->date = date('Y-m-d', strtotime($new_instance->date));

        return $new_instance;
    }

   public function related_with(){
       return NULL;
   }
//   
    public static function references_class() {
        return Array('set_id' => 'Pixel_set');
    }

    public function required_variables() {
        return array_merge(parent::required_variables(),array('date', 'set_id'));
    }

    public function is_deleteable() {
     //    if ( issempty( $this->pixels_field_use() ) )
            return true;
     //   else
     //       return false;
    }
    
    public function validate(){
      
        $old_date = $this->where(Array('set_id'=>$this->set_id,'date'=>  $this->date));
        
        if(count($old_date)!== 0){
            $this->errors("Ya existe esa fecha para ese set");
        }
        
        return parent::validate();
        
        
    }
    
    public function pixels_field_use(){
        
        //Falta definir el modelo de pixels_field_use
        return Array();
    }
    
    public static function dates_by_set($set_id) {
        $dates = Date::where(array('set_id' => $set_id));

        return $dates;
    }
    
    

}
