<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class Region extends R2_DbObject
{

    /**  Variables Static de Configuración del Model */
    protected static $_table_name = 'regions';
    protected static $_display_name = 'region';
    protected static $_plural_name = 'regiones';
    protected static $_display_column = 'name';

    /** Variables Públicas del Model */
    public $name;
    public $map_id;
    public $process_id;

    /** Construct */
    public function __construct()
    {
        parent::__construct();
    }

    public function related_with()
    {
        return array($this->temporal_expansion_rules());
    }

    public static function references_class()
    {
        return array();
    }

    public function required_variables()
    {
        return array_merge(parent::required_variables(), array('name'));
    }

    public function non_editable_variables()
    {
        return array_merge(parent::non_editable_variables(), array('map_id', 'process_id'));
    }

    //

    public function temporal_expansion_rules()
    {
        if (!isset($this->tmporal_expansion_rules))
            $this->temporal_expansion_rules = Temporal_expansion_rule::where(array('region_id' => $this->id));

        return $this->temporal_expansion_rules;
    }

    public function is_deleteable()
    {
        return true;
    }


    public function filtered_regions_by_map_id($map_id = array())
    {
        $where = array();

        if (count($map_id)) {
            $where = array_merge($where, array('map_id IN' => '(' . join(',', $map_id) . ')'));
        }

        if (count($where))
            return $this->where($where, FALSE);

        return $this->all_permitted();
    }

    public static function all_permitted()
    {
        $CI = get_instance();

        if (!in_array($CI->user->id, User::$_SuperUsers)) {
            $CI->db->join('maps', 'maps.id = map_id');
            $CI->db->where('organization_id', $CI->user->organization_id);
        }

        $CI = get_instance();
        return static::all_orderby(static::class_table_name() . "." . static::class_display_column());
    }
}
