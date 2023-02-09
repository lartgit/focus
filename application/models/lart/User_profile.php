<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class User_profile extends User
{

    /**  Variables Static de Configuración del Model */
    protected static $_table_name = 'users';
    protected static $_display_name = 'Perfil';
    protected static $_plural_name = 'Perfil';

    /** Variables Públicas del Model */
    public $name;
    public $inactive_reason;
    /** Construct */
    public function __construct()
    {
        parent::__construct();
    }


    public static function new_from_array($asociativeArray = array())
    {
        $pass_conf = $pass = '';
        if (isset($asociativeArray['password'])) {
            $pass = $asociativeArray['password'];
            unset($asociativeArray['password']);
        }

        if (isset($asociativeArray['password_confirm'])) {
            $pass_conf = $asociativeArray['password_confirm'];
            unset($asociativeArray['password_confirm']);
        }

        $obj = parent::new_from_array($asociativeArray);

        $obj->add_config('password', $pass);
        $obj->add_config('password_confirm', $pass_conf);
        return $obj;
    }

    public function validate()
    {
        if ($this->get_config('password') !== $this->get_config('password_confirm'))
            $this->errors('Las claves no coinciden');

        return parent::validate();
    }

    public function before_save()
    {
        $pass = $this->get_config('password');

        if (!empty($pass)) {
            $this->load->model('r2/r2_session');
            $this->password = $this->r2_session->encrypt($pass);
        }

        return parent::before_save();
    }
    //    public function required_variables() {
    //		return array_merge(parent::required_variables(), array('name'));
    //    }   

    public function is_deleteable()
    {
        $referenced_id = User::where(array('is_admin' => TRUE, 'id' =>  $this->id));

        if (empty($referenced_id)) {
            return true;
        }

        return false;
    }

    public function related_with()
    {
        return NULL;
    }

    /**
     * Variables no editables.
     * @return <array>
     */
    public function non_editable_variables()
    {
        $vars = array_merge(parent::non_editable_variables(), array(
            'active',
            'is_admin',
            'last_login',
            'last_ip',
            'activation_code',
            'password_sent_at',
            'failed_login_count',
            'inactive_reason'
        ));

        foreach ($vars as $key => $value) if ($value === 'password') unset($vars[$key]);
        //      $this->password = NULL;

        return $vars;
    }

    public static function all_permitted()
    {
        $CI = get_instance();

        $CI->db->where('id !=', '-1');
        $CI->db->where('id !=', $CI->user->id);

        if (!in_array($CI->user->id, User::$_SuperUsers)) {
            $CI->db->where('organization_id', $CI->user->organization_id);
        }

        return parent::all_permitted();
    }
}
