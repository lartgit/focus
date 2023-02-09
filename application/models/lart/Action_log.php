<?php

if (!defined('BASEPATH'))
   exit('No direct script access allowed');

/**
 * Description:
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class Action_log extends R2_DbObject {

   /**  Variables Static de Configuración del Model */
   protected static $_table_name = 'db_actions_logs';
   protected static $_display_name = 'Log de Acciones';
   protected static $_plural_name = 'Log de Acciones';
   protected static $_display_column ='';

   /** Variables Públicas del Model */
	public $ts;
        public $event;
        public $user_id;
        public $description;
        public $object_class;
        public $object_id;
        public $object;
        
        
        //public $inactive_reason;
   /** Construct */
   public function __construct() {
      parent::__construct();
      
   }
   
    public function required_variables() {
	return;
    }   
    

   public function related_with(){
       return null;
   }
   
   static public function logs_between($date_from, $date_to){
       $logs = self::where(array('ts >=' => $date_from, 'ts <= ' => $date_to),true,'ts');

       return $logs;
   }
           
   
}

