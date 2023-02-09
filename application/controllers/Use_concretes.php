<?php

if (!defined('BASEPATH'))
   exit('No direct script access allowed');

/**
 * Description:
 *    Controller de Clients
 * 
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class Use_concretes extends Entity_Admin {

   public function __construct() {
      
      // Le mandamos al controller padre el nombre del controller y de la clase que administra
      parent::__construct('use_concretes','Use_concret');
   }

}


