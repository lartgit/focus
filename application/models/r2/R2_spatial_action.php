<?php

if (!defined('BASEPATH'))
   exit('No direct script access allowed');

/**
 * Description of ms_spatial_action
 *    Model para las acciones que suceden en un punto geográfico.
 *
 * @author Yuri
 * @package Ms_Core
 *
 */
class R2_Spatial_Action extends R2_ActionModel {

   //Vars
   public $the_geom;

   // Construct
   public function __construct() {
      parent::__construct();
   }

}
