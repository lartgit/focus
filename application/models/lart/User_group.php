<?php

if (!defined('BASEPATH'))
   exit('No direct script access allowed');

/**
 * Description:
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class User_group extends R2_EntityModel {

   /**  Variables Static de Configuración del Model */
   protected static $_table_name = 'user_groups';
   protected static $_display_name = 'grupo_de_usuarios';
   protected static $_plural_name = 'grupos_de_usuarios';

   /** Variables Públicas del Model */
   public $name;
   public $description;

   /** Variables private */
   //private $projects;

   /** Construct */
   public function __construct() {
      parent::__construct();

   }
   public function required_variables() {
    return array_merge(parent::required_variables(), array('name'));
   }

   public function related_with(){
       return array($this->users(),$this->menus() );
   }

   public function is_deleteable() {

      if ($this->users())
         return false;

      if ($this->menus())
         return false;

      return true;
   }

    public function available_users() {
      if (!isset($this->available_users))
         $this->available_users = $this->db->query(
                         "SELECT * FROM users WHERE id NOT IN
                    (SELECT user_id FROM users_by_groups WHERE user_group_id = $this->id) ORDER BY name"
                 )->result('User');
         //$this->available_users = users_by_groups::where(Array('user_group_id'=>$this->id));

      return $this->available_users;
   }

   public function users() {
      if (!isset($this->users))
         $this->users = $this->db->query(
                         "SELECT * FROM users WHERE id IN
                        (SELECT user_id FROM users_by_groups WHERE user_group_id = $this->id) ORDER BY name"
                 )->result('User');


      return $this->users;
   }

   public function add_or_remove_user_by_id($user_id){
      foreach($this->users() as $each)
         if($each->id == $user_id)
            $user = $each;

      if(isset($user)){
            $this->instance = Users_by_Group::where(Array('user_group_id'=>$this->id, 'user_id'=>$user_id));
           //es un array
            $this->instance[0]->destroy();
      }
      else{
        $values = array('user_group_id' => $this->id,
                         'user_id' => $user_id);

        $this->instance = Users_by_Group::new_from_array($values);
        if ($this->instance->is_valid())
            $this->instance->save();
      }

   }
   //refactorizar
    public function available_menus() {
      if (!isset($this->available_menus))
         $this->available_menus = $this->db->query(
                         "SELECT * FROM menu_options WHERE id NOT IN
                    (SELECT menu_option_id FROM groups_by_options WHERE user_group_id = $this->id) ORDER BY name"
                 )->result('Menu_option');
         //$this->available_menus = groups_by_options::where(Array('user_group_id'=>$this->id));

      return $this->available_menus;
   }

   public function menus() {
      if (!isset($this->menus))
         $this->menus = $this->db->query(
                         "SELECT * FROM menu_options WHERE id IN
                        (SELECT menu_option_id FROM groups_by_options WHERE user_group_id = $this->id) ORDER BY name"
                 )->result('Menu_option');


      return $this->menus;
   }

   public function add_or_remove_menu_by_id($menu_id){
      foreach($this->menus() as $each)
         if($each->id == $menu_id)
            $menu = $each;

      if(isset($menu)){
            $this->instance = Groups_by_Option::where(Array('user_group_id'=>$this->id, 'menu_option_id'=>$menu_id));
           //es un array
            $this->instance[0]->destroy();
      }
      else{
            $values = array('user_group_id' => $this->id,
                             'menu_option_id' => $menu_id);

            $this->instance = Groups_by_Option::new_from_array($values);
            if ($this->instance->is_valid())
                $this->instance->save();
      }
   }

}
