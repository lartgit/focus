<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class User extends R2_User
{

    /**  Variables Static de Configuración del Model */
    protected static $_table_name = 'users';
    protected static $_display_name = 'Usuario';
    //protected static $_display_column = 'name';
    protected static $_plural_name = 'Usuarios';

    // -2 Dolores Arocena
    // -1 admin
    // 14 Gonzalo Irisarri
    // 11 Luca Scenna
    // 23 Mariano Oyarzabal
    public static $_SuperUsers = [-2, -1, 14, 11, 23];

    static $_rest_queryable = TRUE;

    /** Variables Públicas del Model */
    public $name;
    public $email;
    public $inactive_reason;
    public $organization_id;

    /** Construct */
    public function __construct()
    {
        parent::__construct();
    }

    public function validate()
    {
        $old_email = $this->find_by_email($this->email);

        if ($old_email) {
            if ($old_email->id !== $this->id)
                $this->errors('Ya se encuentra registrado ese email');
        }

        return parent::validate();
    }

    public function is_deleteable()
    {
        $referenced_id = User::where(array('is_admin' => TRUE, 'id' => $this->id));

        if (empty($referenced_id)) {
            return true;
        }
        //
        return false;
    }

    public function related_with()
    {
        return NULL;
    }

    public static function references_class()
    {
        return array('organization_id' => 'Organization');
    }

    protected function after_save()
    {
        $group = User_group::find(1); //Id:1 === grupo admin

        //Si se crea (o modifica) un usuario y se establece el is_admin se comprueba si perenece al grupo Admin.
        if (static::evaluate_variable_as_boolean($this->is_admin)) {
            foreach ($group->users() as $each)
                if ($each->id === $this->id)
                    return parent::after_save();

            $group->add_or_remove_user_by_id($this->id);
        } else {
            foreach ($group->users() as $each)
                if ($each->id === $this->id)
                    $group->add_or_remove_user_by_id($this->id);
        }

        parent::after_save();
    }

    public static function all_permitted()
    {
        $CI = get_instance();

        $CI->db->where('id !=', '-1');
        $CI->db->where('id !=', $CI->user->id);

        if (!in_array($CI->user->id, static::$_SuperUsers))
            $CI->db->where('organization_id', $CI->user->organization_id);

        return parent::all_permitted();
    }
}
