<?php

if (!defined('BASEPATH'))
   exit('No direct script access allowed');

/**
 * Description:
 *    Controller de Sub_Projects
 * 
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class Sub_Projects extends Entity_Admin {
    
   public function __construct() {
      // Le mandamos al controller padre el nombre del controller y de la clase que administra
      parent::__construct('sub_projects','Sub_Project');
   }
   
   

}

?>
