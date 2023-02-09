<?php

if (!defined('BASEPATH'))
   exit('No direct script access allowed');

/**
 * Description:
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class Declaration extends R2_DbObject {

   /**  Variables Static de Configuración del Model */
   protected static $_table_name = 'declarations';
   protected static $_display_name = 'Declaracion';
   protected static $_plural_name = 'Declaraciones';

   /** Variables Públicas del Model */
   public $name;
   public $date_from;
   public $date_to;
   public $the_geom;
   
   /** Variables private */
   private $declarations;
   
   /** Construct */
   public function __construct() {
      parent::__construct();
      
   }
   
    public function required_variables() {
		return array_merge(parent::required_variables(), array('name'));
	}   

   
   

}
