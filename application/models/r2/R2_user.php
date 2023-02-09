<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description of R2_User
 *    Model para los usuarios del sistema.
 *
 * @author <NArias>
 * @package <r2>
 *
 */
class R2_User extends R2_EntityModel
{
    /* {2015-08-23} */

    protected static $_table_name = 'users';        // Nombre de la tabla (responsabilidad de las subclases)
    protected static $_display_name = 'Usuario';    // Nombre con el que se muestra la clase (dejar vacío para clases abstractas).
    protected static $_plural_name = 'Usuarios';    // Nombre en plural con el que se muestra la clase (dejar vacío para clases abstractas).
    protected static $_super_user_name = 'r2admin';

    /* Public Vars */
    public $email;
    public $is_admin;
    public $active;
    public $last_login;
    public $last_ip;
    public $id;
    public $failed_login_attempts;
    protected $_admin = '';

    /* ---------- */
    /* Construct  */
    /* ---------- */

    public function __construct()
    {
        parent::__construct();
        date_default_timezone_set('UTC');
        $this->last_login = date('Y-m-d, h:m:s');

        $this->_admin = static::$_super_user_name;
    }

    /* ---------------------------------------------------------------------------------- */
    /* -- Permisos ---------------------------------------------------------------------- */
    /* ---------------------------------------------------------------------------------- */

    //Esto debemos mejorarlo al establecer como van a funcionar los permisos

    public function can_add($aClass)
    {
        return ($this->is_admin() or true);
    }

    public function can_edit($aClass)
    {
        return ($this->is_admin() or true);
    }

    public function can_delete($aClass)
    {
        return ($this->is_admin() or true);
    }

    public function can_send_pass($aClass)
    {
        return ($this->is_admin() or true);
    }

    /* ---------------------------------------------------------------------------------- */
    /* -- Busqueda ---------------------------------------------------------------------- */
    /* ---------------------------------------------------------------------------------- */

    /**
     * Devuelve el primer user que encuentre con el email solicitado
     *
     * @param type $anEmail
     * @return boolean
     */
    public static function find_by_email($anEmail = '')
    {
        if (!$anEmail)
            return false;

        $instances = static::where(array('lower(email)' => strtolower($anEmail)));

        if (empty($instances))
            return false;

        return $instances[0];
    }

    /**
     * Consulta la db y retorna NULL o una instancia de la clase a partir de un id.
     * Subclaseado de R2_EntityModel para la busqueda de user_name case insensitive
     *
     * @param   $name string
     * @static
     * @return  Entity
     */
    static function find_named($name = NULL)
    {
        return static::where(array('lower(name)' => strtolower($name)));
    }

    /* ---------------------------------------------------------------------------------- */
    /* -- Getters Static de Variables Static de Clase - deben tener prefijo class_xxxx -- */
    /* ---------------------------------------------------------------------------------- */

    public static function class_super_user_name()
    {
        return static::$_super_user_name;
    }

    /* ----------------------------------------------------------------------------------- */
    /* -- Getters NO Static de Variables Static de Clase - deben tener prefijo get_xxxx -- */
    /* ----------------------------------------------------------------------------------- */

    public function get_super_user_name()
    {
        return static::class_super_user_name();
    }

    /* ---------------- */
    /* Public Functions */
    /* ---------------- */

    public function __toString()
    {
        return "(" . get_class() . ") " . $this->name;
    }

    public function is_admin()
    {
        return $this->evaluate_variable_as_boolean($this->is_admin);
    }

    public function required_variables()
    {
        return array_merge(parent::required_variables());
    }

    /**
     * Variables no editables.
     * @return <array>
     */
    public function non_editable_variables()
    {
        return array_merge(parent::non_editable_variables(), array(
            'password',
            'last_login',
            'last_ip',
            'activation_code',
            'password_sent_at',
            'failed_login_count'
        ));
    }

    /* --------------------- */
    /* Modify User Functions */
    /* --------------------- */

    // Función para controlar los intentos fallidos de login del usuario
    public function increment_failed_login_count($last_ip)
    {
        $data_update = array(
            'failed_login_count' => ($this->failed_login_attempts + 1),
            'last_ip' => $last_ip,
            'last_login' => date('Y-m-d, h:m:s')
        );
        $this->db->where('id', $this->id);
        $this->db->update(self::$_table_name, $data_update);
    }

    // Función para resetear el contador de login fallidos
    public function restart_failed_login_count()
    {
        $this->db->where('id', $this->id);
        $this->db->update(self::$_table_name, array('failed_login_count' => 0));
    }

    // Función para obtener la contraseña del usuario administrador del sistema
    public function get_admin_password()
    {
        if (empty($this->_admin))
            return NULL;

        $this->db->select('password');
        $this->db->from(self::$_table_name);
        $this->db->where('username', $this->_admin);
        $query = $this->db->get();
        return $query->row();
    }
}
