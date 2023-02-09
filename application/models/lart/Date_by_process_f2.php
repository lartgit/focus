<?php

if (!defined('BASEPATH'))
   exit('No direct script access allowed');

/**
 * Description:
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class Date_by_process_f2 extends R2_DbObject {

   /**  Variables Static de Configuración del Model */
   protected static $_table_name = 'date_by_process_f2';
   protected static $_display_name = 'Fecha para el proceso';
   protected static $_plural_name = 'Fecha para el proceso';

   /** Variables Públicas del Model */
   public $date;
   public $process_f2_id;
   
   /** Variables private */
   // private $declarations;
   
   /** Construct */
   public function __construct() {
      parent::__construct();
      
   }
   
 //    public function required_variables() {
	// 	return array_merge(parent::required_variables(), array('name'));
	// }   

   
   

}

?>
