<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 */

class Map_region extends R2_DbObject {
   
   	/**  Variables Static de Configuración del Model */
	protected static $_table_name = 'map_regions';
	protected static $_display_name = 'Regiones';
	protected static $_plural_name = 'Regiones';



   /** Variables Públicas del Model */
	public $name;
	public $map_id;
	public $process_id;

   /** Construct */
	public function __construct() {
	  parent::__construct();
	  
	}
	
	public function related_with(){
	   return array();
	}
    
    public function required_variables()
    {
        return array_merge(parent::required_variables(), array('name'));
    }   

    public function non_editable_variables()
    {
        return array_merge(parent::non_editable_variables(),array('map_id','process_id'));
    }    

    public function filtered_regions_by_map_id($map_id = array())
    {
        $where = array();

        if(count($map_id)) {
            $where = array_merge($where, array('map_id IN' => '('.join(',',$map_id).')' ));
        }

        if(count($where))
            return $this->where($where, FALSE);

        return $this->all_permitted();
    }

    public function is_deleteable() {
    	return true;
    }
  
}
