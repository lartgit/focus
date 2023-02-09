<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class Client extends R2_EntityModel
{

    /**  Variables Static de Configuración del Model */
    protected static $_table_name = 'clients';
    protected static $_display_name = 'cliente';
    protected static $_plural_name = 'clientes';

    /** Variables Públicas del Model */
    public $name;
    public $organization_id;
    public $description;

    /** Variables private */
    private $projects;

    /** Construct */
    public function __construct()
    {
        parent::__construct();
    }

    public function required_variables()
    {
        return array_merge(parent::required_variables(), array('name'));
    }

    public function related_with()
    {
        return array($this->projects());
    }

    public static function references_class()
    {
        return array('organization_id' => 'Organization');
    }

    public function projects()
    {
        if (!isset($this->projects))
            $this->projects = Project::where(array('client_id' => $this->id));

        return $this->projects;
    }

    public static function new_from_array($asociativeArray = array())
    {
        $new_instance = parent::new_from_array($asociativeArray);

        //Tengo que ponerle el mismo organization_id que el usuario logueado
        $CI = get_instance();
        if ($CI->user->id > 0)
            $new_instance->organization_id = $CI->user->organization_id;

        return $new_instance;
    }

    public static function all_permitted()
    {
        $CI = get_instance();

        if (!in_array($CI->user->id, User::$_SuperUsers))
            $CI->db->where('organization_id', $CI->user->organization_id);

        return parent::all_permitted();
    }
}
