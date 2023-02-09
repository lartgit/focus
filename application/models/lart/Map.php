<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 */

class Map extends R2_DbObject
{

    /**  Variables Static de Configuración del Model */
    protected static $_table_name = 'maps';
    protected static $_display_name = 'Mapa de Regiones / Unidades de vegetación';
    protected static $_plural_name = 'Mapa de Regiones / Unidades de vegetación';
    protected static $_display_column = 'name';

    private $_extension = 'shp';

    /** Variables Públicas del Model */
    public $name;
    public $quantity;
    public $path;
    public $organization_id;

    /** Construct */
    public function __construct()
    {
        parent::__construct();
    }


    public function related_with()
    {
        return array();
    }

    public function required_variables()
    {
        return array_merge(parent::required_variables(), array('name'));
    }

    public function non_editable_variables()
    {
        return array_merge(parent::non_editable_variables(), array('quantity', 'path', 'organization_id'));
    }

    public function after_save()
    {
        $arrMap_proc = array();
        $arrMap_proc['path'] = $this->path;
        $arrMap_proc['map_id'] = $this->id;
        $arrMap_proc['user_id'] = $this->session->userdata('userid');
        $instance_of_procces = Process_region::new_from_array($arrMap_proc);
        $instance_of_procces->save();
        parent::after_save();
    }

    public function validate()
    {

        if (!$this->name || $this->name == '') {
            $this->errors("Debe ingresar un nombre");
        }

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
        }

        if (!$this->id && !$this->map_name_exist()) {
            $this->errors("El nombre {$this->name} ya existe.");
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
     * Methodo description
     * ....
     * Retorna la cantidad de regiones
     *  Sugerencia: refactorizar y hacer la query para que se resuelva en un solo paso
     * Y no hacer la peticion por cada row
     * Lo implemento aasi para la reunion de LART 2016-12-23
     * 
     * @author CAR <ariel.ramirez@r2soft>
     * @package Map.php
     */
    public function get_regions_quantity()
    {
        // insert code
        $ret = $this->db->query("SELECT count(*) qt FROM regions WHERE map_id = {$this->id}")->result();

        if (!empty($ret)) {
            return $ret[0]->qt;
        }

        return 0;
    }

    /**
     * devuelve el estado del procesio
     */
    public function get_last_process_status()
    {
        // insert code
        $ret = $this->db->query("SELECT description FROM process_regions WHERE map_id = {$this->id} order by ts desc ")->result();

        if (!empty($ret)) {
            return $ret[0]->description;
        }

        return 0;
    }

    /*
     * Esto se podria habaer evitado creando una nueva columna >.<
     * Antes de mostrar el objeto reemplazo el path para mostrarlo relativo
     */

    public static function new_from_array($asociativeArray = array())
    {
        $new_instance = parent::new_from_array($asociativeArray);

        $new_instance->organization_id = get_instance()->user->organization_id;

        if (isset($new_instance->path))
            $new_instance->path = str_replace(get_instance()->config->item('upload_path'), '', $new_instance->path);

        return $new_instance;
    }

    public function map_name_exist()
    {
        $db_ret = $this->where(array('name' => $this->name));
        if (!empty($db_ret)) {
            return false;
        }

        return true;
    }


    public function region_map_to_shp($folder, $map_id)
    {

        $folder = trim($folder, '/');

        $output = array();
        $return = '';
        $file_name = $this->user->name . uniqid('-');

        #Traemos los datos del archivo Config y Database para correr el proceso en el pgsql2shp
        $path = $this->config->item('upload_path') . $folder;
        $dbname = $this->db->database;
        $dbusername = $this->db->username;
        $dbpassword = $this->db->password;
        $dbhost = $this->db->hostname;

        $where = '';
        if ($map_id !== FALSE)
            $where .= " map_id = $map_id";


        #Ejecutamos el comando pgsql2shp
        exec("cd $path && pgsql2shp -u $dbusername -h $dbhost -P $dbpassword -p 5432 -f \"$file_name\" $dbname \"SELECT name, the_geom FROM regions WHERE $where\"", $output, $return);

        #Retorno true o false y el error lo manejo en la view, para no pasar la salida standar de la terminal
        if ($return == 0) {
            return true;
        } else
            return false;
    }

    public static function all_permitted()
    {
        $CI = get_instance();

        if (!in_array($CI->user->id, User::$_SuperUsers)) {
            $CI->db->where('organization_id', $CI->user->organization_id);
        }

        return parent::all_permitted();
    }
}
