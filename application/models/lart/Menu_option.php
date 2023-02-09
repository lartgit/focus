<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 */

class Menu_Option extends R2_DbObject {

   /**  Variables Static de Configuración del Model */
   protected static $_table_name = 'menu_options';
   protected static $_display_name = 'Menu Opciones';
   protected static $_plural_name = 'Menu Opciones';

   /** Variables Públicas del Model */
   public $name;
   public $controller;
   public $action;
   public $description;


   /** Construct */
   public function __construct() {
      parent::__construct();

   }

    /**
    **
    *Metodo que devuelve los rows
    *Del Menu en base al User
    *
    *
    */
    public function get_roots($id){

        if (isset($id)) {
            $list = $this->db->query("SELECT DISTINCT menu_options.id, menu_options.name, menu_options.controller, menu_options.action, menu_options.menu_icon, menu_options.parent_id, menu_options.order
                            FROM users_by_groups
                            join user_groups ON (user_groups.id = users_by_groups.user_group_id AND user_groups.active = TRUE)
                            join groups_by_options ON groups_by_options.user_group_id = users_by_groups.user_group_id
                            join menu_options ON menu_options.id = groups_by_options.menu_option_id
                            WHERE users_by_groups.user_id = $id
                            ORDER BY menu_options.order asc")->result();

            return $this->recursivit($list);
        }

        // return false;
    }

    /**
    *
    *Metodo Recursivo para armar el arbol del menu de opciones.
    */
    public function recursivit($list, $id = null){
        $root = array();

        foreach ($list as $node) {
            if ($node->parent_id === $id) {
                $root[] = $node;
            }

        }

        foreach ($root as $each) {
            $each->childs = $this->recursivit($list, $each->id);
        }

        return $root;
    }

    /*
     * Metodo para buscar el icono del menu en la base de datos.
     * El parametro puede ser el id del menu o el nombre.
     */
    public static function get_icon_for($option)
    {
        if(is_numeric($option))
            return static::find($option);

        $ret = static::where(array('name' => $option));

        if(!$ret || !count($ret)) return '';

        return $ret[0]->menu_icon;
    }
}
