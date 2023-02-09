<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 * @author ARamirez
 * @package Focus
 */
class Process_Image extends R2_DbObject
{

    /**  Variables Static de Configuración del Model */
    protected static $_table_name = 'process_images';
    protected static $_display_name = 'Proceso De Imagenes';
    protected static $_plural_name = 'Procesos De Imagenes';

    /** Variables Públicas del Model */
    // public $client_id;
    // public $project_id;
    // public $subproject_id;
    // public $version_id;

    /** Variables private */
    private $_extension = 'hdf';

    public $procces_run;

    /** Construct */
    public function __construct()
    {
        parent::__construct();
    }

    public function required_variables()
    {
        return array_merge(parent::required_variables(), array('path'));
    }

    public static function references_class()
    {
        return array('set_id' => 'Pixel_set', 'user_id' => 'User');
    }

    public function non_editable_variables()
    {
        return array_merge(parent::non_editable_variables(), array('start_process_at', 'end_process_at', 'path', 'description', 'user_id', 'procces_run'));
    }

    public function validate()
    {
        return parent::validate();
    }

    public function is_deleteable()
    {
        if ($this->procces_run == 't') {
            return false;
        }

        return true;
    }
}
