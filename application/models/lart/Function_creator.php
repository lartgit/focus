<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class Function_creator extends R2_DbObject {

    /**  Variables Static de Configuración del Model */
    protected static $_table_name = 'functions';
    protected static $_display_name = 'funcion';
    protected static $_plural_name = 'funciones';
    protected static $_display_column = 'name';

    /** Variables Públicas del Model */
    public $name;
    public $path;
    public $description;
    public $column_name;
   	private $_extension = 'py';

   	public static $create_python_view_title = "Crear y validar codigo Python";

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
        return array('user_id' => 'User');
    }

    public function non_editable_variables()
    {
        return array_merge(parent::non_editable_variables(), array('path', 'user_id','fx_saved_name'));
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
        }

        if (isset($this->column_name[0]) && empty($this->column_name[0])) {
			$this->errors("Al menos un nombre de columna es requerido.");
        }

        if (!$this->check_name_exist()) {
            $this->errors("El nombre ya existe.");
        }


        return parent::validate();
    }

	/**
	 * Methodo description
	 * ....
	 * 
	 * 
	 * @author CAR <ariel.ramirez@r2soft>
	 * @package Function_creator.php
	 */
	public function check_name_exist(){
		$ret = '';
		if (isset($this->id) && $this->id != '') {
			$ret = $this->where(array('name' => $this->name, 'id !=' => $this->id));
		}

		if (!isset($this->id) || is_null($this->id)) {
			$ret = $this->where(array('name' => $this->name));
		}


		if (!empty($ret)) {
			return false;
		}

		return true;
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
        $valid_path = str_replace(get_instance()->config->item('upload_path'),"",$this->path);
        $this->path = get_instance()->config->item('upload_path') . $valid_path;


		// Antes de guardar el dato hacemos el join por commas para leerlo posteriormete desde python
        if (!$this->get_config("check")) {
	        $tmp = '';
	        $this->column_name = $this->input->post('column_name');
	        for ($i=0; $i < count($this->column_name); $i++) { 
	        	if (empty($this->column_name[$i]))
	        		continue;

	        	$tmp .= $this->column_name[$i] . ',';
	        }
	        
			$this->column_name = substr($tmp,0,-1);
        }


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
     * Esto se podria habaer evitado creando una nueva columna >.<
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

    public static function all_permitted() {
        $CI = get_instance();

        if (!in_array($CI->user->id, User::$_SuperUsers)) {
            $CI->db->join('users', 'users.id = user_id');
            $CI->db->where('organization_id', $CI->user->organization_id);
        }

        return parent::all_permitted();
    }
}
