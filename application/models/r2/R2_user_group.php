<?php

if (!defined('BASEPATH'))
   exit('No direct script access allowed');

/**
 * Description of R2_User_group
 *    Model para los grupos de usuarios del sistema.
 *
 * @author <NArias>
 * @package <r2>
 *
 */
class R2_User_group extends R2_EntityModel {
   /* {2015-08-23} */

   protected static $_table_name = 'user_groups';            // Nombre de la tabla (responsabilidad de las subclases)
   protected static $_display_name = 'Grupo de Usuarios';    // Nombre con el que se muestra la clase (dejar vacío para clases abstractas).
   protected static $_plural_name = 'Grupos de usuarios';    // Nombre en plural con el que se muestra la clase (dejar vacío para clases abstractas).
   
   /* Public Vars */

   /* ---------- */
   /* Construct  */
   /* ---------- */

   public function __construct() {
      parent::__construct();
   }

 

}
