<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 * @author ARamirez
 * @package Focus
 */
class Process_Field extends R2_DbObject
{

    /**  Variables Static de Configuración del Model */
    protected static $_table_name = 'process_fields';
    protected static $_display_name = 'Carga de Shape Files';
    protected static $_plural_name = 'Carga de Shape Files';

    /** Variables Públicas del Model */
    // public $client_id;
    // public $project_id;
    // public $subproject_id;
    // public $version_id;

    /** Variables private */
    private $_extension = 'shp';
    public $procces_run;
    public $qt_errors;
    public $import_from;

    /*******************************************************************
     * TENER EN CUENTA ESTO PARA LA COLUMNA import_from
     * MINIAGRI = 1
     * CREA = 2
     ********************************************************************/

    /** Construct */
    public function __construct()
    {
        parent::__construct();
    }

    public function required_variables()
    {
        return array_merge(parent::required_variables(), array('path', 'client_id', 'project_id', 'version_id'));
    }

    public static function references_class()
    {
        return array('client_id' => 'Client', 'project_id' => 'Project', 'version_id' => 'Version', 'user_id' => 'User');
    }

    public function non_editable_variables()
    {
        return array_merge(parent::non_editable_variables(), array('start_process_at', 'end_process_at', 'path', 'description', 'user_id', 'procces_run', 'qt_errors', 'check_run', 'import_from'));
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
            if (!$this->validate_extension(end($files_folder), $this->_extension)) {
                $this->errors("La extension del archivo no es valida");
            }

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
        unset($asociativeArray['is_validate']);

        $new_instance = parent::new_from_array($asociativeArray);

        if (isset($new_instance->path))
            $new_instance->path = str_replace(get_instance()->config->item('upload_path'), '', $new_instance->path);

        if (!isset($new_instance->user_id))
            $new_instance->user_id = get_instance()->user->id;

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


    public function version_name()
    {
        if (!isset($this->version_name))
            $this->version_name = Version::where(array('id' => $this->version_id));
        return $this->version_name[0]->name;
    }
    public function client_name()
    {
        if (!isset($this->client_name))
            $this->client_name = Client::where(array('id' => $this->client_id));
        return $this->client_name[0]->name;
    }
    public function project_name()
    {
        if (!isset($this->project_name))
            $this->project_name = Project::where(array('id' => $this->project_id));
        return $this->project_name[0]->name;
    }

    public function is_deleteable()
    {

        if ($this->procces_run == 't') {
            return false;
        }

        return true;
    }

    public static function all_permitted()
    {
        $CI = get_instance();

        if (!in_array($CI->user->id, User::$_SuperUsers)) {
            $CI->db->join('users', 'users.id = user_id');
            $CI->db->where('organization_id', $CI->user->organization_id);
        }

        return parent::all_permitted();
    }
}
