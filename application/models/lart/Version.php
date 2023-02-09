<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class Version extends R2_EntityModel
{

    /**  Variables Static de Configuración del Model */
    protected static $_table_name = 'versions';
    protected static $_display_name = 'Version';
    protected static $_plural_name = 'Versiones';

    /** Variables Públicas del Model */
    public $name;
    public $project_id;

    /** Variables private */
    private $farms;

    /** Construct */
    public function __construct()
    {
        parent::__construct();
    }

    public function related_with()
    {
        return array($this->farms());
    }

    public static function references_class()
    {
        return array('project_id' => 'Project');
    }

    public function required_variables()
    {
        return array_merge(parent::required_variables(), array('name', 'project_id'));
    }

    // public function non_editable_variables() {
    //     return array_merge(parent::non_editable_variables(), array('project_id'));
    // }


    public function farms()
    {
        if (!isset($this->farms))
            $this->farms = Farm::where(array('version_id' => $this->id));

        return $this->farms;
    }

    public function cli_proy_name()
    {
        if (isset($this->cli_proy_name)) {

            return $this->cli_proy_name;
        } else {
            // Hago esto aunque queda un poco feo para armar el nombre completo 
            // Cliente Proyecto Version
            $clients = $this->client($this->project()->client_id);
            return $clients->name . '/' . $this->project()->name . '/' . $this->name;
        }
    }

    public function project()
    {
        return Project::find($this->project_id);
    }

    public function client($client_id)
    {
        return Client::find($client_id);
    }

    public function project_name()
    {
        if (isset($this->project_name))
            return $this->project_name;
        else
            return $this->project()->name;
    }

    public static function all_permitted()
    {
        $CI = get_instance();

        if (!in_array($CI->user->id, User::$_SuperUsers)) {
            $CI->db->join('projects', 'projects.id = project_id');
            $CI->db->join('clients', 'clients.id = client_id');
            $CI->db->where('organization_id', $CI->user->organization_id);
        }

        return parent::all_permitted();
    }
}
