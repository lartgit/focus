<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 */

class Organization extends R2_DbObject
{

    /**  Variables Static de Configuración del Model */
    protected static $_table_name = 'organizations';
    protected static $_display_name = 'Organizacion';
    protected static $_plural_name = 'Organizaciones';
    protected static $_display_column = 'name';

    /** Variables Públicas del Model */
    public $name;

    /** Construct */
    public function __construct()
    {
        parent::__construct();
    }

    public function related_with()
    {
        return NULL;
    }

    public function is_deleteable()
    {
        return true;
    }

    public static function all_permitted()
    {
        $CI = get_instance();

        if (!in_array($CI->user->id, User::$_SuperUsers)) {
            $CI->db->where('id', $CI->user->organization_id);
        }

        return parent::all_permitted();
    }
}
