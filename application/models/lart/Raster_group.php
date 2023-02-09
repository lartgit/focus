<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class Raster_group extends R2_DbObject
{

    /**  Variables Static de Configuración del Model */
    protected static $_table_name = 'raster_groups';
    protected static $_display_name = 'Grupo de raster';
    protected static $_plural_name = 'Grupo de rasters';
    protected static $_display_column = 'name';

    /** Variables Públicas del Model */
    public $name;
    public $files_quantity;
    public $layers_quantity;

    /** Variables private */

    /** Construct */
    public function __construct()
    {
        parent::__construct();
    }

    public function required_variables()
    {
        return true;
    }

    //devuelve un array() de arrays de objetos
    public function related_with()
    {
        return true;
    }

    public function non_editable_variables()
    {
        return array_merge(parent::non_editable_variables(), array('files_quantity', 'layers_quantity'));
    }

    public function is_deleteable()
    {

        // if ($this->data_types())
        //     return false;

        return true;
    }


    public static function get_index_data($filters = array())
    {
        $CI = get_instance();

        $query = "
        SELECT ITID as id, count(rf.id) as qt_files , LTC as qt_layers, min(raster_groups.name) as name, min( raster_groups.ts) as ts, min( raster_groups.created_at) as created_at, min(ps.imagen_type_id ) as image_type_id
        FROM (
			SELECT ITID, count(LT) as LTC FROM (
				SELECT distinct it.id ITID, layer_types.id LT--, count(*)
				FROM raster_files rf
                LEFT JOIN pixel_sets ps on ps.id = rf.pixel_set_id
				LEFT JOIN imagen_types it on it.id = rf.image_type_id
				LEFT JOIN layer_types ON layer_types.image_type_id = rf.image_type_id ) a
			GROUP BY ITID ) b
		LEFT JOIN raster_files rf on rf.image_type_id = b.ITID	
        LEFT JOIN pixel_sets ps on ps.id = rf.pixel_set_id
		GROUP BY ITID, LTC	";

        // return $CI->db->get(static::$_table_name)->result(get_called_class());
        return $CI->db->query($query)->result(get_called_class());
    }

}
