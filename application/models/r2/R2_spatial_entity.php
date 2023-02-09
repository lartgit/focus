<?php

if (!defined('BASEPATH'))
   exit('No direct script access allowed');

/**
 * Description of R2_Spatial_Entitity
 *    Model para las entidades geográficas.
 *
 * @package <r2>
 *
 */
class R2_Spatial_Entity extends R2_EntityModel {

   //Vars
   public $the_geom;

   // Construct
   public function __construct() {
      parent::__construct();
   }

}
