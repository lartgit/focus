<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 */

class Concretes_by_Declared extends R2_DbObject {
   
   /**  Variables Static de Configuración del Model */
   protected static $_table_name = 'concretes_by_declareds';
   protected static $_display_name = 'Usos Concretos por Declarados';
   protected static $_plural_name = '';
   protected static $_ts_column = '';            // Esta tabla no tiene esta columna
   protected static $_created_at_column = '';  // Esta tabla no tiene esta columna.



   /** Variables Públicas del Model */
   public $declared_id;
   public $concrete_id;

   /** Construct */
   public function __construct() {
      parent::__construct();
      
   }
  
}
