<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description of R2_DbObject
 *    Clase Abstracta para representar los modelos persistentes de la aplicación.
 *    La implementación está basada en el pattern de active-records donde los modelos(clases)
 *    tienen escencialmente los datos, comportamiento y además saben como persistirse.
 *
 * Muchas de las diferencias con el patrón de Active-Recors se deben a que la implementación
 *  de Code-Igniter ya es distinta a la del patrón.
 * Los nombres de los métodos se asemejan a los utilizados en la implementación de Rails.
 *
 * @author <NArias>
 * @version <2015-08-23>
 * @package <r2>
 * @abstract
 *
 */
abstract class R2_DbObject extends CI_Model
{
    /* Variables Static de Configuración - Es responsabilidad de las subclases completarlas o redefinirlas */
    /* Se deben definir funciones static (de clase) para acceder a las mismas udando el prefijo "class_" */
    /* Se deben definir funciones no static (de instancia) para acceder a las mismas udando el prefijo "get_" */

    protected static $_table_name = NULL;           // Nombre de la tabla (responsabilidad de las subclases)
    protected static $_primary_key = 'id';          // PK del objeto.
    protected static $_display_column = 'id';       // Columna para display.
    protected static $_ts_column = 'ts';            // Columna que representa la última vez que se modificó.
    protected static $_created_at_column = 'created_at'; // Columna que representa la cuando se creó.
    protected static $_display_name;                // Nombre con el que se muestra la clase (dejar vacío para clases abstractas).
    protected static $_plural_name;                 // Nombre en plural con el que se muestra la clase (dejar vacío para clases abstractas).
    protected static $_table_schema = 'public';     // Nombre schema. Schema en el que se encuentran nuestras tablas.
    protected static $_log_activity = TRUE;         // True: logear acciones a travez de db_action_log

    static $_rest_queryable = FALSE;

    /* Variables no estaticas de la clase */
    public $id;         // id serial autoincremental.
    public $ts;         // Registra la fecha y hora de la última modificacion realizada al objeto.
    public $created_at; // Registra cuando fue creado el el objeto, solo debería inicializarse al insertarse por primera vez.

    /* Variables que contienen datos que no se van a insertar en la db */
    protected $errors = array();
    protected $arr_config = array();

    // Construct
    public function __construct()
    {
        parent::__construct();

        // Se Setea el Timestamp de modificación.
        // $this->initialize_ts();
        // Logs que se inicializó la clase.
        log_message('debug', get_called_class() . " Initialized");
    }

    /* Funcion para convertir la instancia a string */

    public function __toString()
    {
        return $this->get_class_display_name() . " (" . static::class_display_column() . " = " . $this->display_value() . ")";
    }

    /* Propiedades de las variables */

    // Variables no editables
    public function non_editable_variables()
    {
        return array($this->get_primary_key(), $this->get_ts_column(), $this->get_created_at_column());
    }

    // Variables requeridas
    protected function required_variables()
    {
        return array();
    }

    /* --------------------------------------------------- */
    /* ------  Funcioens de timestamps del objeto -------- */
    /* --------------------------------------------------- */

    /**
     * Se inicializa la variable del timestamp.
     */
    protected function initialize_ts()
    {
        if ($column = static::class_ts_column())
            $this->$column = date('Y-m-d, H:i:s');
    }

    /**
     * Se inicializa la variable del timestamp.
     */
    protected function initialize_created_at()
    {
        if ($column = static::class_created_at_column())
            $this->$column = date('Y-m-d, H:i:s');
    }

    /**
     * Devuelve el contenido de la columna de timestamp si la tiene
     */
    public function ts()
    {
        if ($column = static::class_ts_column()) {
            return $this->get_date_time($this->$column)->format('Y-m-d H:i:s');
        } else
            return '';
    }

    /**
     * Devuelve el contenido de la columna de created_at si la tiene
     */
    public function created_at()
    {
        if ($column = static::class_created_at_column()) {
            return $this->get_date_time($this->$column)->format('Y-m-d');
        } else
            return '';
    }

    /* -------------------------------------- */
    /* ------  Relaciones del objeto -------- */
    /* -------------------------------------- */

    // Este array debe devolver un conjuntp de ( 'variable' => 'Clase');
    // Las variables que representan FKs deben seguir la convención de nombres: claseReferenciada_id
    /**
     * @deprecated
     */
    public static function references_class()
    {
        return array();
    }

    /* Array de clases que hacen referencia a esta clase */

    /**
     * @deprecated
     */
    protected function is_referecended_by()
    {
        return array();
    }

    /**
     * @deprecated
     */
    public static function relations_n_n()
    {
        return array();
    }

    /* -------------------------------------- */
    /* ----------- Conversiones ------------- */
    /* -------------------------------------- */

    // Evalua una variable como boolean, usamos esto para evitar falsos TRUE
    // cuando $var contiene por ejemplo 'f'
    public static function evaluate_variable_as_boolean($value)
    {
        if (($value === TRUE)
            or ($value === 'True')
            or ($value === 'On')
            or ($value === 'TRUE')
            or ($value === 'T')
            or ($value === '.T.')
            or ($value === 'ON')
            or ($value === 'true')
            or ($value === 't')
            or ($value === '.t.')
            or ($value === 'on')
            or ($value === 1)
        )
            return TRUE;

        if (($value === FALSE)
            or ($value === 'False')
            or ($value === 'Off')
            or ($value === 'FALSE')
            or ($value === 'F')
            or ($value === '.F.')
            or ($value === 'OFF')
            or ($value === 'false')
            or ($value === 'f')
            or ($value === '.f.')
            or ($value === 'off')
            or ($value === 0)
        )
            return FALSE;

        if (is_null($value))
            return NULL;

        throw new Exception('El valor: ' . $value . ' no es un boolean soportado.');
    }

    /**
     * No entiendo porque me viene en 2 formatos dinstintos la fecha desde la base de datos.
     *
     * @param type $an_string
     * @return <DateTime>
     */
    public function get_date_time($an_string)
    {


        $date_time = new DateTime($an_string);

        if (!$date_time)
            throw new Exception('El valor: ' . $an_string . ' no es un DateTeime soportado.');

        return $date_time;
    }

    /* -------------------------------------- */
    /* ----------- Validaciones ------------- */
    /* -------------------------------------- */

    /**
     * Funcion para manejar el array de errores.
     */
    public function errors($anError = NULL)
    {
        if (!isset($this->errors))
            $this->errors = array();

        if ($anError)
            $this->errors[] = $anError;

        return $this->errors;
    }

    /**
     * Realizan las validaciones del objeto.
     *    Como el objeto puede ir cambiando ya que no usamos setters
     *    cada vez que se le pregunta is_valid() se hace la validación de nuevo.
     *
     * @return boolean
     */
    public function is_valid()
    {
        $this->errors = $this->validate();
        return (empty($this->errors));
    }

    /**
     * Valida la instancia llenando $this->errors con los errores encontrados
     *
     */
    protected function validate()
    {
        $this->validate_required_variables();
        $this->validate_required_datatabase_columns();
        return $this->errors();
    }

    /*
     * Valida que las variables configuradas en el objeto como requeridas se encuentren seteadas.
     */

    protected function validate_required_variables()
    {
        foreach ($this->required_variables() as $each_var)
            if (!isset($this->$each_var) || $this->$each_var === '')
                $this->errors("Required variable '$each_var' is not set");
    }

    protected function validate_required_datatabase_columns()
    {
        // To be defined
        // $dbColumns = $aClass::class_table_columns();

        return true;
    }

    /**
     * Para que sea compatible con Entity
     *
     */
    public function is_active()
    {
        return true;
    }

    /* ---------------------------------------------------------------------------------- */
    /* -- Getters Static de Variables Static de Clase - deben tener prefijo class_xxxx -- */
    /* ---------------------------------------------------------------------------------- */

    public static function class_table_name()
    {
        if (!isset(static::$_table_name))
            throw new Exception('La clase: ' . get_called_class() . ' no tiene tabla seteada.');
        return static::$_table_name;
    }

    public static function class_primary_key()
    {
        if (!isset(static::$_primary_key))
            throw new Exception('La clase: ' . get_called_class() . ' no tiene Primary Key seteada.');
        return static::$_primary_key;
    }

    public static function class_schema_name()
    {
        if (!isset(static::$_table_schema))
            throw new Exception('La clase: ' . get_called_class() . ' no tiene schema seteada.');
        return static::$_table_schema;
    }

    public static function class_display_column()
    {
        return (static::$_display_column != NULL) ? static::$_display_column : static::class_primary_key();
    }

    public static function class_display_name()
    {
        return (static::$_display_name != NULL) ? static::$_display_name : get_called_class();
    }

    public static function class_plural_name()
    {
        return (static::$_plural_name != NULL) ? static::$_plural_name : get_called_class();
    }

    public static function class_ts_column()
    {
        return (static::$_ts_column);
    }

    public static function class_created_at_column()
    {
        return (static::$_created_at_column);
    }

    /* ----------------------------------------------------------------------------------- */
    /* -- Getters NO Static de Variables Static de Clase - deben tener prefijo get_xxxx -- */
    /* ----------------------------------------------------------------------------------- */

    public function get_table_name()
    {
        return static::class_schema_name() . '.' . static::class_table_name();
    }

    public function get_primary_key()
    {
        return static::class_primary_key();
    }

    public function get_display_column()
    {
        return static::class_display_column();
    }

    public function get_ts_column()
    {
        return static::class_ts_column();
    }

    public function get_created_at_column()
    {
        return static::class_created_at_column();
    }

    public function get_class_display_name()
    {
        return static::class_display_name();
    }

    public function get_class_plural_name()
    {
        return static::class_plural_name();
    }

    /* Accesors de los valores correspondientes a las columnas seteadas Static de la clase */

    /**
     * Devuelve el VALOR de la primary_key
     *
     * @return mixed
     */
    public function primary_key_value()
    {
        $primary_key_column_name = $this->get_primary_key();
        return $this->$primary_key_column_name;
    }

    /**
     * Shortcut.
     *
     * @alias primary_key_value
     */
    public function id()
    {
        return $this->primary_key_value();
    }

    /**
     * Permite setear el valor de la primary_key
     *
     * @param mixed $value Valor a setear como primary key
     */
    private function set_primary_key_value($value)
    {
        $primary_key_column_name = $this->get_primary_key();
        $this->$primary_key_column_name = $value;
    }

    /**
     * Devuelve el VALOR de la columna seteada como de display_column.
     *
     * @return mixed
     */
    public function display_value()
    {
        $display_column_name = $this->get_display_column();
        return $this->$display_column_name;
    }

    /**
     * Devuelve el nombre de la clase
     *
     * @return mixed
     */
    public static function class_name()
    {
        return get_called_class();
    }

    /**
     * Esto permite redefinir en las subclasses la manera que se obtienen todas
     *  las instancias de una clase relacionada
     *
     * @param mixed $class Clase a la que pedirle todos los elementos
     * @return mixed
     */
    public function all_of($class)
    {
        return $class::all();
    }

    /**
     * Esto permite redefinir en las subclasses la manera que se obtienen todas
     *  las instancias de una clase relacionada
     *
     * @param mixed $class Clase a la que hay que pedirle todos los elementos activos
     * @return mixed
     */
    public function all_active_of($class)
    {

        return $class::all_active();
    }

    /*
     * Hook con entity
     */

    public static function all_active()
    {
        return static::all_permitted();
    }

    /* -------------------------------------------------------------------------------- */
    /* ---- Funciones static de Instanciación de DbObjects desde la base de datos ----- */
    /* -------------------------------------------------------------------------------- */

    /**
     * Devuelve todos los objetos persistidos de la clase.
     *
     * @return mixed
     */
    public static function all()
    {
        return static::all_orderby(static::class_display_column());
    }

    /**
     * Devuelve todos los objetos persistidos de la clase, que puedan ser accedidos por el usuario actual, 
     * por defecto el usuario puede ver todo. Cada clase deberia redefinir este metodo y aplicar los filtros pertinentes.
     *
     * @return mixed
     */
    public static function all_permitted()
    {
        $CI = get_instance();
        $CI->db->select(static::class_table_name() . '.*');
        return static::all_orderby(static::class_table_name() . "." . static::class_display_column());
    }

    /**
     * Consulta la DB y devuelve un array con todos los objetos de la clase ordenados
     *    por una columna.
     *
     * @access  public
     * @static
     * @return  mixed
     */
    public static function all_orderby($column = NULL)
    {
        $column_for_order_by = $column ? $column : (static::class_table_name() . "." . static::class_display_column());

        $ciObj = &get_instance();
        return $ciObj->db
            ->order_by($column_for_order_by)
            ->get(static::class_schema_name() . '.' . static::class_table_name())
            ->result(get_called_class());
    }

    /**
     * Consulta la DB y devuelve un array con todos los objetos de la clase ordenados
     *    por una columna.
     *
     * @access  public
     * @static
     * @return  mixed
     */
    public static function index($from = 0, $limit = 100)
    {
        $ciObj = &get_instance();
        $limit = min(array(100, $limit));
        return $ciObj->db
            ->limit($limit, $from)
            ->order_by(static::class_display_column())
            ->get(static::class_schema_name() . '.' . static::class_table_name())
            ->result(get_called_class());
    }

    /**
     * Devuelve todos los objetos persistidos de la clase que cumplan con las condiciones del array.
     *
     * @param   Array array con clave => valor para filtrar los datos de entrada
     * @param   boolean $escape Si hay que escapar los elementos del array
     * @param   string $column_for_order Por que columna hay que ordenar
     * @return  mixed
     */
    public static function where(array $conditions_array = NULL, $escape = TRUE, $column_for_order = NULL)
    {
        $column_for_order_by = $column_for_order ? $column_for_order : static::class_display_column();

        if ((!$conditions_array) or (!is_array($conditions_array)))
            return array();

        $ciObj = &get_instance();
        return $ciObj->db
            ->where($conditions_array, NULL, $escape)
            ->order_by(static::class_table_name() . "." . $column_for_order_by)
            ->get(static::class_schema_name() . '.' . static::class_table_name())
            ->result(get_called_class());
    }

    /**
     * Devuelve todos los objetos persistidos de la clase que tengan el valor en values
     *
     * @param   string columna donde fijarse los valores
     * @param   Array valores a comprobar
     * @return  mixed
     */
    public static function where_in($column, $values)
    {

        if (empty($values))
            return static::all();

        $ciObj = &get_instance();
        return $ciObj->db
            ->where_in($column, $values)
            ->order_by(static::class_table_name() . "." . static::class_display_column())
            ->get(static::class_table_name())
            ->result(get_called_class());
    }

    /**
     * Devuelve todos los objetos persistidos de la clase que no tengan el valor en values
     *
     * @param   string columna donde fijarse los valores
     * @param   Array valores a comprobar
     * @return  mixed
     */
    public static function where_not_in($column, $values)
    {

        if (empty($values))
            return static::all();

        $ciObj = &get_instance();
        return $ciObj->db
            ->where_not_in($column, $values)
            ->order_by(static::class_display_column())
            ->get(static::class_schema_name() . '.' . static::class_table_name())
            ->result(get_called_class());
    }

    /**
     * Consulta la db y retorna NULL o una instancia de la clase a partir de
     *    una clave primaria (la cual generalmente es un id)
     *
     * @access	public
     * @param   mixed $primary_key_value  El valor de la PK del objeto.
     * @static
     * @return	DbObject
     */
    public static function find($primary_key_value = NULL)
    {
        if (!$primary_key_value)
            return NULL;

        $found = static::where(array(static::class_primary_key() => $primary_key_value));

        if (!empty($found))
            return $found[0];
        else
            return NULL;
    }

    /**
     * Consulta la db y retorna una instancia de la clase a partir de
     *   una clave primaria (la cual generalmente es un id)
     *   o una nueva instancia si no existe el valor
     *
     * @access	public
     * @param   mixed $primary_key_value  El valor de la PK del objeto.
     * @static
     * @return	DbObject
     */
    public static function find_or_new($primary_key_value)
    {
        $instance = static::find($primary_key_value);

        if ($instance == NULL)
            return new static();

        return $instance;
    }

    /**
     * Consulta la db y retorna un array vacío o un array de instancias
     *    de la clase a partir de un array de claves primarias.
     *
     * @access  public
     * @param   Array()
     * @static
     * @return  mixed
     */
    public static function find_ids(array $primary_key_values = NULL)
    {

        if ((!$primary_key_values) or (!is_array($primary_key_values)))
            return array();

        $ciObj = &get_instance();
        return $ciObj->db
            ->where_in(static::class_primary_key(), $primary_key_values)
            ->order_by(static::class_display_column())
            ->get(static::class_schema_name() . '.' . static::class_table_name())
            ->result(get_called_class());
    }

    /**
     * Consulta la db y retorna un array vacío o un array de instancias
     *    de la clase a partir de un array de claves primarias.
     *
     * @access  public
     * @param   Array()
     * @static
     * @return  mixed
     */
    public static function find_not_ids(array $primary_key_values = NULL)
    {

        if ((!$primary_key_values) or (!is_array($primary_key_values)))
            return array();

        $ciObj = &get_instance();
        return $ciObj->db
            ->where_not_in(static::class_primary_key(), $primary_key_values)
            ->order_by(static::class_display_column())
            ->get(static::class_schema_name() . '.' . static::class_table_name())
            ->result(get_called_class());
    }

    /**
     * Consulta la DB y devuelve la cantidad de rows que tiene la tabla.
     *
     * @access	public
     * @static
     * @return	integer
     */
    public static function count()
    {
        $ciObj = &get_instance();
        return $ciObj->db->count_all(static::class_schema_name() . '.' . static::class_table_name());
    }

    /**
     * Consulta la DB y devuelve el ts del último modificado.
     *
     * @access	public
     * @static
     * @return	integer
     */
    public static function last_modified()
    {
        $ts_column = static::class_ts_column();

        $ciObj = &get_instance();
        $result = $ciObj->db
            ->select_max($ts_column)
            ->get(static::class_schema_name() . '.' . static::class_table_name())->row();
        if ($result)
            return $result->$ts_column;
        else
            NULL;
    }

    /**
     * Elimina de la db un objeto a partir de primary_key_value.
     *    Devuelve un boolean dependiendo si tuvo exito.
     *
     * @access     public
     * @param      $primary_key_value Id del objeto a borrar
     * @static
     * @return     <boolean>
     */
    public static function delete($primary_key_value)
    {
        if (!$primary_key_value)
            return FALSE;

        $ciObj = &get_instance();
        $ciObj->db
            ->where(static::class_primary_key(), $primary_key_value)
            ->delete(static::class_schema_name() . '.' . static::class_table_name());

        if ($ciObj->db->affected_rows() > 0)
            return TRUE;
        else
            return FALSE;
    }

    /**
     * Devuelve un array con las columnas de la tabla de la clase dependiendo del driver.
     * @access     public
     * @static
     * @return     <array>
     */
    public static function class_table_columns()
    {
        $ciObj = &get_instance();
        if ($ciObj->db->dbdriver == 'postgre')
            return static::class_table_columns_postgres();
        else
            return static::class_table_columns_basic();
    }

    /**
     * Devuelve un array con las columnas de la tabla de la clase, usa la función básica de CI.
     * @access     public
     * @static
     * @return     <array>
     */
    public static function class_table_columns_basic()
    {
        $ciObj = &get_instance();
        return $ciObj->db->field_data(static::class_schema_name() . '.' . static::class_table_name());
    }

    /**
     * Devuelve un array con las columnas de la tabla de la clase.
     *    Implementada específicamente para postgres.
     *
     * @access     public
     * @static
     * @return     <array>
     */
    public static function class_table_columns_postgres()
    {

        $ciObj = &get_instance();
        return $ciObj->db
            ->query("SELECT column_name as name,
                data_type as type,
                (is_nullable='YES') is_nulleable,
                character_maximum_length as max_length
                FROM INFORMATION_SCHEMA.COLUMNS
                WHERE table_name = '" . static::class_table_name() . "'
                AND table_schema = '" . static::class_schema_name() . "'")
            ->result();
    }

    /* ---------------------------------------------------------------------------------- */
    /* --------- Metodos de Creación de una nueva entidad  ------------------------------ */
    /* ---------------------------------------------------------------------------------- */

    /**
     * Devuelve una nueva entidad a partir de un array de valores.
     *
     * @access     public
     * @param Array $asociativeArray Array que contiene los valores de las columnas del nuevo objeto
     * @static
     * @return     <obj>
     */
    public static function new_from_array($asociativeArray = array())
    {

        $new_instance = new static();

        foreach ($asociativeArray as $key => $value)
            $new_instance->$key = $value;

        return $new_instance;
    }

    /* ----------------------------------- */
    /* ------ Métodos de Instancia ------- */
    /* ----------------------------------- */

    /**
     * Se Elimina la instancia de la DB.
     *
     * @access	public
     * @return	boolean
     */
    public function destroy()
    {
        $this->add_config("last_action", "DELETE");
        if (static::$_log_activity)
            $this->log_action();

        return static::delete($this->primary_key_value());
    }

    /**
     * Contiene la lógica para preguntar si se puede borrar la instancia.
     *    Se debe redefinir en las clases hijas.
     *
     * @access	public
     * @return	boolean
     */
    public function is_deleteable()
    {
        return true;
    }

    /**/

    public function add_config($key, $val)
    {
        $this->arr_config[$key] = $val;
    }

    public function get_config($key)
    {
        if (isset($this->arr_config[$key])) {
            return $this->arr_config[$key];
        }

        return false;
    }

    //Si esta funcion decide no salvar el registro, debería devolver FALSE
    protected function before_save()
    {

        $this->validate();

        return TRUE;
    }

    //Acciones a hacer despues de guardar el objeto
    protected function after_save()
    {
        if (static::$_log_activity)
            $this->log_action();
    }

    /*
     * Funcion por defecto para logear acciones a la db.
     */

    protected function log_action()
    {
        $this->load->model('r2/r2_db_action_log');

        $action = $this->get_config("last_action");
        if (!$action)
            $action = "UNKNOWN";

        $descr = $this->get_config("log_description");
        if (!$descr)
            $descr = "";

        /*Modifique la linea de user_id porque si lo corro desde linea de comando me tira un error porque no tengo session. Ariel*/
        $this->r2_db_action_log->new_from_array(array(
            'event' => $action,
            'user_id' => (isset(get_instance()->session) ? $this->session->userdata("userid") : null),
            'description' => $descr,
            'object_class' => get_class($this),
            'object_id' => $this->id,
            'object' => json_encode($this)
        ))->save();
    }

    /*
     * Funcion por defecto para logear acciones a la db.
     */

    protected function log_accion_exclusive($action)
    {
        $this->load->model('r2/r2_db_action_log');

        $descr = $this->get_config("log_description");
        if (!$descr)
            $descr = "";

        $this->r2_db_action_log->new_from_array(array(
            'event' => $action,
            'user_id' => $this->session->userdata("userid"),
            'description' => $descr,
            'object_class' => $this->get_class_display_name(),
            'object_id' => $this->id,
            'object' => json_encode($this)
        ))->save();
    }

    /**
     * Realiza el proceso de guardar el objeto en la base de datos.
     *
     * Se valida el y realizan acctiones previas en before_save();
     * Se guarda en la base.
     * Se realizan acciones posteriores al guardado en after_save();
     *
     * @access	public
     * @return	boolean
     */
    public function save()
    {

        if (!$this->before_save())
            return FALSE;

        $this->basic_save();

        $this->after_save();
        return TRUE;
    }

    /**
     * Esta función no realiza las validaciones del objeto ni las acciones previas ni posteriores.
     * NO SE DEBERIA UTILIZAR excepto en tests.
     *
     * @return boolean
     */
    public function basic_save()
    {

        $this->initialize_ts();

        $values_to_store = $this->values_to_store();

        $ciObj = &get_instance();

        if ($this->primary_key_value()) {

            $ciObj->db
                ->where(static::class_primary_key(), $this->primary_key_value())
                ->update(static::class_schema_name() . '.' . static::class_table_name(), $values_to_store);

            $this->add_config("last_action", "UPDATE");

            if ($ciObj->db->affected_rows() == 0)
                return FALSE;
        } else {
            $this->initialize_created_at();

            $ciObj->db->insert(static::class_schema_name() . '.' . static::class_table_name(), $values_to_store);

            $this->add_config("last_action", "INSERT");

            $this->set_primary_key_value($ciObj->db->insert_id());
        }
    }

    /**
     * Arma los valores a guardarse en la base de datos.
     */
    protected function values_to_store()
    {

        $values = array();

        foreach ((array) $this as $each_variable => $each_value) {
            if ($each_variable !== $this->get_primary_key())
                if (isset($this->$each_variable) and (!is_array($each_value)))
                    $values[$each_variable] = ($each_value === '') ? NULL : $each_value;
        }

        // Si la PK está en el array como null la removemos. DIRECTAMENTE NO SE ASIGNA AHORA si es primary_key
        //  if(isset($values[$this->get_primary_key()] ) && $values[$this->get_primary_key()] === 'NULL') {
        //     unset($values[$this->get_primary_key()]);
        //  }
        // Convierto las boolean a true/false de postgres para salvar el error de que el driver
        // Está mandando un 0 o un 1
        $ciObj = &get_instance();

        if ($ciObj->db->dbdriver == 'postgre') {
            foreach ($values as $each_key => $each_value) {
                if ($each_value === TRUE)
                    $values[$each_key] = 'TRUE';
                if ($each_value === FALSE)
                    $values[$each_key] = 'FALSE';
            }
        }
        return $values;
    }
}
