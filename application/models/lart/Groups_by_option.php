<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 */

class Groups_by_Option extends R2_DbObject {
   
   /**  Variables Static de Configuración del Model */
   protected static $_table_name = 'groups_by_options';
   protected static $_display_name = 'Opciones por Grupo';
   protected static $_plural_name = '';
   protected static $_ts_column = '';            // Esta tabla no tiene esta columna
   protected static $_created_at_column = '';  // Esta tabla no tiene esta columna.



   /** Variables Públicas del Model */
   public $user_group_id;
   public $menu_option_id;

   /** Construct */
   public function __construct() {
      parent::__construct();
      
   }
  
}
