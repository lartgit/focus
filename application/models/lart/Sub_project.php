<?php

if (!defined('BASEPATH'))
   exit('No direct script access allowed');

/**
 * Description:
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class Sub_Project extends R2_EntityModel {

   /**  Variables Static de Configuración del Model */
   protected static $_table_name = 'sub_projects';
   protected static $_display_name = 'Sub Proyecto';
   protected static $_plural_name = 'Sub Proyectos';

   /** Variables Públicas del Model */
   public $name;
   public $project_id;

   
   /** Variables private */
   private $versions;
   
   /** Construct */
   public function __construct() {
      parent::__construct();
      
   }
   
   public function related_with(){
       return array($this->versions());
   }
   
   public static function references_class() {
      return Array('project_id' => 'Project');
   }
   
    public function required_variables() {
		return array_merge(parent::required_variables(), array('name','project_id'));
	}   

   
   public function versions(){
      if(!isset($this->versions))
         $this->versions = Version::where(Array('sub_project_id'=>$this->id));
      
      return $this->versions;
   }
}
