<?php

/**
 * Description of R2_EntityModel
 *    Clase abstracta para las entidades persistentes del sistema.
 *    La Idea original del modelo entidad<->acción proviene del sistema InfoProd.
 *
 * @author <NArias>
 * @version <2015-08-23>
 * @package <r2>
 * @abstract
 *
 */
class R2_EntityModel extends R2_DbObject {
    /* {2014-07-23} */
    /* Variables Static de Configuración - Es responsabilidad de las subclases completarlas o redefinirlas */
    /* Se deben definir funciones static (de clase) para acceder a las mismas udando el prefijo "class_" */
    /* Se deben definir funciones no static (de instancia) para acceder a las mismas udando el prefijo "get_" */

    protected static $_display_column = 'name';     // Columna para display.
    protected static $_active_column = 'active';    // Columna boolean que determina si el objeto está activo
    protected static $_default_active = FALSE;      // Variable para indicar si un nuevo objeto que no setea la columna active deberia ser TRUE o FALSE

    /* Variables no estaticas de la clase */
    public $name;       // Las entidades deben tener un nombre
    public $active;     // Las entidades tienen un campo boolean que denota el estado: activo/inactivo

    // Construct

    public function __construct()
    {
        parent::__construct();
        if(!isset($this->active))
            $this->set_active();
    }

    // To string
    public function __toString()
    {
        return $this->display_value() . ' (' . static::class_display_name() . ')';
    }

    /* ---------------------------------------------------------------------------------- */
    /* -- Getters Static de Variables Static de Clase - deben tener prefijo class_xxxx -- */
    /* ---------------------------------------------------------------------------------- */

    public static function class_active_column()
    {
        return static::$_active_column;
    }

    /* ----------------------------------------------------------------------------------- */
    /* -- Getters NO Static de Variables Static de Clase - deben tener prefijo get_xxxx -- */
    /* ----------------------------------------------------------------------------------- */

    public function get_active_column()
    {
        return static::class_active_column();
    }

    /* -------------------------------------- */
    /* ----------- Validaciones ------------- */
    /* -------------------------------------- */

    /**
     * Realizan las validaciones del objeto.
     *
     * @return boolean
     */
    public function is_valid()
    {
        return parent::is_valid();
    }

    protected function validate()
    {
        $this->validate_name_already_used();

        return parent::validate();
    }

    protected function validate_name_already_used()
    {
        $tmp = static::find_named($this->name);

        //Caso nuevo reg
        if (!$this->id && !empty($tmp)) {
            $this->errors[] = "El nombre $this->name ya está siendo utilizado";
        }

        //Caso edit
        foreach ($tmp as $each) {
            if ($this->id && ($each->id !== $this->id)) {
                $this->errors[] = "El nombre $this->name ya está siendo utilizado";
            }
        }
    }

    /* ---------------------- */
    /* -- Public Functions -- */
    /* ---------------------- */

    public function name(){
       return $this->name;
    }

    public function required_variables()
    {
        return array_merge(parent::required_variables(), array('name'));
    }

    // Inicializa la columna de activo/inactivo si tiene.
    public function initialize_active()
    {
        $var = $this->get_active_column();
        if ($var and $this->$var == NULL)
            $this->set_active();
    }

    // Setea al objeto como inactivo.
    public function set_inactive()
    {
        $this->set_active_var_to(FALSE);
    }

    // Setea al objeto como activo.
    public function set_active()
    {
        $this->set_active_var_to(TRUE);
    }

    // Setea al objeto como inactivo.
    public function set_inactive_and_store()
    {
        $this->set_inactive();
        $this->save();
    }

    // Setea al objeto como activo.
    public function set_active_and_store()
    {
        $this->set_active();
        $this->save();
    }

    // Setea un valor a la columna de activo/inactivo
    private function set_active_var_to($boolean = TRUE)
    {
        $variable = $this->get_active_column();
        $this->$variable = $boolean;
    }

    /**
     * Devuelve una boolean dependiendo del valor seteado de la columna de
     *  activo/inactivo.
     * En caso de ser un valor no reconocido, genera un error.
     *
     * @return  <boolean>
     */
    public function is_active()
    {
        $var = $this->get_active_column();
        return $this->evaluate_variable_as_boolean($this->$var);
    }

    /**
     * Devuelve el boolean de activo / inactivo pasado a String.
     * @return string
     */
    public function active_to_string()
    {
        if ($this->is_active())
            return "Si";
        return "No";
    }

    /* -------------------------------------------------------------------------------- */
    /* --- Funciones static de Instanciación de Etntidades desde la base de datos ----- */
    /* -------------------------------------------------------------------------------- */

    /**
     * Consulta la db y retorna NULL o una instancia de la clase a partir de un id
     *
     * @param   $name string
     * @static
     * @return  Entity
     */
    static function find_named($name = NULL)
    {
        return static::where(array('name' => $name));
    }

    /**
     * Retorna un las instancias de la clase persistidas, marcadas como activas.
     * @static
     * @return  mixed
     */
    static function all_active()
    {
        $CI = get_instance();
        $CI->db->where(static::class_table_name() .'.'. static::class_active_column(), 'TRUE');
        return parent::all_active();
    }

    /**
     * compare($a,$b)
     *  Funcion utilizada para comprar dos objetos por su columna principal.
     *  Muy utilizada al usar usort($arrayConObjetos,'funcion_comparadora')
     *
     * @param type $left
     * @param type $right
     */
    static function compare($left, $right)
    {
        $class = get_called_class();
        $columm = $class::$_display_column;
        return strcmp($left->$columm, $right->$columm);
    }

    /**
     * displayCompare($a,$b)
     *  Funcion utilizada para comprar dos objetos por su columna principal.
     *  Muy utilizada al usar usort($arrayConObjetos,'funcion_comparadora')
     *
     * @param type $left
     * @param type $right
     */
    static function displayCompare($left, $right)
    {
        return strcmp($left->_display_column, $right->_display_column);
    }

    /* ---------------------------------------------------------------------------------- */
    /* --------- Metodos de Creación de una nueva entidad  ------------------------------ */
    /* ---------------------------------------------------------------------------------- */

    /**
     * Devuelve una nueva entidad a partir de un array de valores.
     *
     * @access     public
     * @static
     * @return     <obj>
     */
    public static function new_from_array($asociativeArray = Array())
    {

        $new_instance = parent::new_from_array($asociativeArray);

        // Fuerzo el pasaje a BOOLEAN del contenido de la columna de activo/inactivo dependiendo de si viene o no seteada la variable en
        // el array asociativo.
        // Esto podría generalizarlo a todas las columnas boolean del objeto;

        $active_column = static::class_active_column();

        if (isset($asociativeArray[$active_column]))
            $new_instance->$active_column = static::evaluate_variable_as_boolean($new_instance->$active_column);
//        else
//            $new_instance->$active_column = static::$_default_active;

        return $new_instance;
    }

}
