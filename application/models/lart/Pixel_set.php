<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class Pixel_set extends R2_EntityModel
{

    /**  Variables Static de Configuración del Model */
    protected static $_table_name = 'pixel_sets';
    // Modificacion de la denominacion set=escenas 05-01-2016
    protected static $_display_name = 'Escena';
    protected static $_plural_name = 'Escenas';

    /** Variables Públicas del Model */
    public $name;
    public $imagen_type_id;
    /** Construct */
    public function __construct()
    {
        parent::__construct();
    }

    public function required_variables()
    {
        return array_merge(parent::required_variables(), array('name', 'imagen_type_id'));
    }

    public function non_editable_variables()
    {
        $vars = array_merge(parent::non_editable_variables(), array('width', 'height'));

        return $vars;
    }

    public function related_with()
    {
        return array($this->process_results());
    }

    public static function references_class()
    {
        return array('imagen_type_id' => 'Imagen_type');
    }

    public function is_deleteable()
    {

        if (count($this->process_results()) > 0)
            return false;
        else
            return true;
    }

    public function pixels()
    {
        //  "cuando esté armado el model de pixeles, se debe modificar esta función para que consulte los pixeles del set"
        return array();
    }

    public function process_results()
    {
        if (!isset($this->process_results))
            $this->process_results = Process_Result::where(array('set_id' => $this->id));

        return $this->process_results;
        //  return Array();
    }
}
