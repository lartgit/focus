<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 * @author ARamirez
 * @package Focus
 */
class Process_Pixel extends R2_DbObject
{

    /**  Variables Static de Configuración del Model */
    protected static $_table_name = 'process_pixels';
    protected static $_display_name = 'Carga de Grilla';
    protected static $_plural_name = 'Carga de Grilla';

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

        if (!$this->path) {
            $this->errors("Debe seleccionar un Archivo");
        }

        #Validacion del path que me envian a traves del form
        if ($this->path && $this->path[0] == '/') {

            #valido que empiece con barra.
            $valid_path = str_replace(array('/', '\\'), DIRECTORY_SEPARATOR, $this->path);

            #Exploto el path y valido la extension  
            $files_folder = explode('/', $valid_path);

            #Validamos la extension
            // if (!$this->validate_extension(end($files_folder), $this->_extension)) {
            //     $this->errors("La extension del archivo no es valida");
            // }

            #chequeo que exista en el directrio
            // if(file_exists($path))
            //     $this->errors("La extension del archivo no es valida");
        }


        return parent::validate();
    }


    /**
     * Extract the file extension
     *
     * @param   string  $filename
     * @param   string  $extension
     * @return  string
     */
    public function validate_extension($filename, $extension)
    {
        $x = explode('.', $filename);

        if (count($x) === 1) {
            return false;
        }

        $ext = strtolower(end($x));

        if ($ext != $extension) {
            return false;
        }

        return true;
    }



    /*
    * Antes de guardar el objeto le añadimos el path 
    * completo.
    *
    */
    public function before_save()
    {

        parent::before_save();

        $valid_path = trim($this->path, '/');

        $this->path = $this->config->item('upload_path') . $valid_path;

        return true;
    }

    /**
     * Metodo que retorna el path relativo.
     */
    public function path_name()
    {

        $tmp_path_name = str_replace(get_instance()->config->item('upload_path'), '', $this->path);

        return $tmp_path_name;
    }

    /*
    *Esto se podria habaer evitado creando una nueva columna >.<
    * Antes de mostrar el objeto reemplazo el path para mostrarlo relativo
    */
    public static function new_from_array($asociativeArray = array())
    {
        $new_instance = parent::new_from_array($asociativeArray);
        $new_instance->user_id = get_instance()->user->id;

        if (isset($new_instance->path))
            $new_instance->path = str_replace(get_instance()->config->item('upload_path'), '', $new_instance->path);

        return $new_instance;
    }

    /*
    * Esto se podria habaer evitado creando una nueva columna >.<
    * Antes de mostrar el objeto reemplazo el path para mostrarlo relativo
    */
    public static function find($primary_key_value = NULL)
    {

        $obj = parent::find($primary_key_value);

        if (!is_null($obj)) {

            $obj->path = str_replace(get_instance()->config->item('upload_path'), '', $obj->path);

            return $obj;
        }
    }

    public function set_name()
    {
        if (!isset($this->set_name))
            $this->set_name = Pixel_set::where(array('id' => $this->set_id));

        if(!count($this->set_name))
            return "Autodetectar";
        return $this->set_name[0]->name;
    }

    public function imagen_type_name()
    {
        if (!isset($this->imagen_type))
            $this->imagen_type = Imagen_Type::where(array('id' => $this->imagen_type_id));
        return $this->imagen_type[0]->name;
    }

    public function is_deleteable()
    {
        if ($this->procces_run == 't') {
            return false;
        }

        return true;
    }
}
