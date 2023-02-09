<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class Raster_file extends R2_DbObject
{

    /**  Variables Static de Configuración del Model */
    protected static $_table_name = 'raster_files';
    protected static $_display_name = 'Archivo Raster';
    protected static $_plural_name = 'Archivos Raster';
    protected static $_display_column = 'path';

    /** Variables Públicas del Model */
    public $path;
    public $image_type_id;
    public $image_date;
    public $pixel_set_id;

    /** Construct */
    public function __construct()
    {
        parent::__construct();
    }

    public static function new_from_array($asociativeArray = array())
    {
        $instance = parent::new_from_array($asociativeArray);

        if (isset($instance->image_date)) {
            //por si viene ''
            if ($instance->image_date) {
                $date = DateTime::createFromFormat('d-m-Y', $instance->image_date);
                $instance->image_date = $date->format('Y-m-d');
            }
        }

        return $instance;
    }

    public function non_editable_variables()
    {
        return array_merge(parent::non_editable_variables(), array('path', 'image_date'));
    }

    public function related_with()
    {
        $this->db->order_by("id", "desc");
        $this->db->limit(1);
        $qry = Process_Image::where(array('raster_file_id' => $this->primary_key_value()));

        return $qry;
    }

    public static function references_class()
    {
        return array('image_type_id' => 'Imagen_Type', 'pixel_set_id' => 'Pixel_set');
    }

    public function required_variables()
    {
        return array_merge(parent::required_variables(), array('image_type_id', 'path'));
    }

    public function is_deleteable()
    {
        // Pusco el proceso de este archivo
        $this->db->order_by("id", "desc");
        $this->db->limit(1);
        $qry = Process_Image::where(array('raster_file_id' => $this->primary_key_value()));

        if (count($qry) && $qry[0]->status == 'in_process') {
            return false;
        }
        return true;
    }

    public function after_save()
    {
        parent::after_save();

        Process_Image::new_from_array(array(
            'raster_file_id' => $this->primary_key_value(),
            'user_id' => $this->session->userdata('userid'),
            'status' => 'pending'
        ))->save();
    }

    public static function get_index_data($filters = array())
    {
        $CI = get_instance();

        $CI->db->where($filters);

        $CI->db->select('raster_files.*');
        $CI->db->select("regexp_replace(path, '^.*[/\\\\]', '') as name");
        $CI->db->select("imagen_types.name as image_type");
        $CI->db->select("count(raster_layers.id) as quantity");
        $CI->db->select("process_images.status as status");
        $CI->db->select("date_trunc('second', COALESCE(process_images.end_process_at, NOW()) - process_images.start_process_at) as time", FALSE);

        $CI->db->join('process_images', 'process_images.raster_file_id = raster_files.id', 'LEFT');
        $CI->db->join('raster_layers', 'raster_layers.raster_file_id = raster_files.id', 'LEFT');
        $CI->db->join('imagen_types', 'imagen_types.id = raster_files.image_type_id', 'LEFT');

        $CI->db->group_by('raster_files.id');
        $CI->db->group_by('process_images.id');
        $CI->db->group_by('imagen_types.name');

        $CI->db->order_by('process_images.status = \'in_process\' desc, process_images.id desc');

        return $CI->db->get(static::$_table_name)->result(get_called_class());
    }
}
