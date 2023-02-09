<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description of ms_abstract_controller
 *    Controller abstracto para nuestras aplicaciones
 *
 * @author NArias 2014
 *
 */
class R2_abstract_controller extends CI_Controller {
    /* {2014-12-15} */

    /** El "_" previo a los nombres de variable denota que son variables base y no del cliente * */

    /** Variables Protegidas del controller. * */
    protected $_user_session;
    protected $_track_activity = FALSE;

    /** Variables para configurar los nombres por default de vistas. Se deben redefinir en el controller del cliente * */
    public $_view_header;
    public $_view_footer;
    public $_view_side_menu;
    public $_view_layout;
    public $_view_queries = 'r2_debug_queries';

    /** Variables públicas usadas para el routing. * */
    public $_url_site;
    public $_url_login;
    public $_url_logout;
    public $_url_ms_admin;
    public $_url_user_profile;

    /** Construct * */
    public function __construct() {
        parent::__construct();
        // Librerías requeridas
        $this->load->helper('url');

        // 2014-07-18 - NGA => Estas podrian abstraerse aún mas si usaramos sinónimos cortos
        //  y luego los especificaramos en el archivo /config/routes.php
        // (ej: $route['logout'] = '/index.php/ms_session_manager/logout';)
        // Inicializacion de rutas de acceso.
        $this->_url_site = site_url();
        $this->_url_login = site_url('/R2_session_manager');
        $this->_url_logout = site_url('/R2_session_manager/logout');
        $this->_url_user_profile = site_url('/R2_session_manager/profile');
        $this->_url_password_recover = site_url('/R2_session_manager/password_recover');

        // Inicializacion de ruta de nuestro Admin.
        $this->_url_ms_admin = $this->_url_site . '/R2_admin/admin';

        // Inicializado de la Sesión
        $this->_user_session = new R2_Session();

        // Debug Message.
        log_message('debug', get_called_class() . " Initialized");

        // Magic Hooks -> Permiten usar $this o $controller (con el scope del controller) en las Views.
        $this->controller = $this;
        $this->this = $this;

        // Hook -> Permite acceder diréctamente al objeto de CI
        $this->ci = & get_instance();
    }

    /**
     * 
     */
    function __destruct() {
        if ($this->_track_activity) {

            $RTR =& load_class('Router', 'core');

            $post_data = $_POST;
            // Si el metodo es autenticate me tengo que asegurar de borrar la pass del user...
            if($RTR->fetch_method() === 'authenticate')
                $post_data['password'] = '*hidden*';

            $data = array(
                'ip' => $_SERVER['REMOTE_ADDR'],
                'post_data' => json_encode($post_data),
                'get_data' => json_encode($_GET),
                'uri' => uri_string(),
                'controller' => $RTR->fetch_class(),
                'method' => $RTR->fetch_method(),
                'http_response_code' => http_response_code()
            );
            $data['user_id'] = $this->session->userdata('user_id');

            $log_instance = Log_activity::new_from_array($data);
            $log_instance->save();
        }
    }

    /**
     * Chequea los permisos de usuario.
     *  Se debe redefinir en las subclases.
     *
     * @return boolean
     */
    public function check_user_access() {
        return $this->check_user_logued();
    }

    /**
     * Chequea que el usuario este logueado, sino lo redirecciona al login page.
     *
     * @return boolean
     */
    public function check_user_logued() {
        if (!isset($this->_user_session))
            return(FALSE);

        if ($this->_user_session->is_logged_in() == FALSE) {
            $this->redirect_to_login_page();


            if ($this->_user_session->is_active() === FALSE) {
                $this->_user_session->set_flashdata('error_string', 'La sesion ha expirado, vuelva a logearse al sistema.');
                $this->redirect_to_login_page();
            }

            return(TRUE);
        }
    }

    /**
     * Verifica accesos a la pagina que se desea ver, sino redirecciona al login page.
     *
     * @return boolean
     */
    public function check_user_permission($role) {
        if (!$this->access_model->user_has_permission($this->user, $role))
            redirect(base_url()); //esto me estaba dando error de loop

        return(TRUE);
    }

    /**
     * Cada controller que no redefina la función index, redireccionará al login page.
     */
    public function index() {
        $this->redirect_to_login_page();
    }

    /**
     * Redirecciona al login page.
     */
    protected function redirect_to_login_page($url_login = '') {
        //var_dump($url_login);

        $url = ($url_login) ? $url_login : $this->_url_login;

        //var_dump($url);

        redirect($url);
        return;
    }

    /**
     * Carga una vista en base a la view del layout.
     *
     * @param type $aViewFileName   Nombre de la vista.
     * @param type $viewData        Data a cargarle.
     */
    public function load_view_with_layout($viewFileName = null, $viewData = null) {
        // Si no viene un valor se le manda $this a la vista.
        $viewData = ( $viewData ? ((object) $viewData) : $this);
        // Menu_Options
        /* Aca le pasamos a la vista las opciones que tiene disponible el User */
        $viewData->menu_options = New Menu_Option();
        $viewData->options = $viewData->menu_options->get_roots($this->_user_session->user_id());
        // $this->_user_session->user_id();
        // Magic
        $viewData->viewData = $viewData;
        $viewData->view_file_name = $viewFileName;
        $this->load->view($this->_view_layout, $viewData);
    }

    /**
     * La dejo como función legacy, deberíamos usar ahora el load_view_with_layout.
     * 
     * @deprecated since 2015-08-22
     * @param null $aViewFileName
     * @param null $viewData
     */
    public function loadViewWithHeaderAndFooter($viewFileName = null, $viewData = null) {

        // Si no viene un valor se le manda $this a la vista.
        $viewData = ( $viewData ? $viewData : $this);

        // Si se tiene un header especificado, se carga antes de la view.
        if ($this->_view_header)
            $this->load->view($this->_view_header, $viewData);

        // Se realiza el load de la view
        if ($viewFileName)
            $this->load->view($viewFileName, $viewData);

        // Si tiene un footer especificado, se carga luego de la view.
        if ($this->_view_footer)
            $this->load->view($this->_view_footer, $viewData);

        // Herramienta de debuggin
        if ($this->is_developing_mode()) {
            $viewData->view_name = $viewFileName;
            $viewData->queries = $this->performed_queries();
            $this->load->view($this->_view_queries, $viewData);
        }
    }

    /**
     * Devuelve la sesión del usuario.
     */
    public function get_session() {
        return $this->_user_session;
    }

    /**
     * Devuelve el nombre de la clase;
     */
    public static function class_name() {
        return get_called_class();
    }

    /**
     * Devuelve si está configurado como develping mode
     */
    public function is_developing_mode() {
        return ($this->config->item('developing_mode') == true );
    }

    /* ---------------------------------------------------------------------------------- */
    /* -- Hooks con R2_DBObject --------------------------------------------------------- */
    /* ---------------------------------------------------------------------------------- */

    /**
     * Delega en la clase encontrar un objecto.
     *
     * @param class
     * @param primary_key
     * @return <R2_DbObject>
     */
    protected function find($ms_class, $primary_key) {
        return $ms_class::find($primary_key);
    }

    /**
     * Delega en la clase encontrar todas las instancias de la clase.
     *
     * @param class
     * @return array of <R2_DbObject>
     */
    protected function all_of($ms_class) {
        return $ms_class::all_permitted();
    }

    /**
     * Delega en la clase devolver el nombre a visualizar de la misma.
     *
     * @param class
     * @param primary_key
     * @return <string>
     */
    protected function class_display_name_of($ms_class) {
        return $ms_class::class_display_name();
    }

    /**
     * Delega en la clase devolver la metadata de las columnas de su tabla.
     *
     * @param class
     * @param primary_key
     * @return <string>
     */
    public function table_columns_postgres_of($ms_class) {
        return $ms_class::class_table_columns();
    }

    /**
     * Devuelve un objeto de la clase a patir del array de datos.
     *
     * @param  <className>
     * @param  <array data>
     * @return <MS_DdObject>
     */
    public function new_from_post_array($className, $data) {
        return $className::new_from_array($data);
    }

    /* ---------------------------------------------------------------------------------- */
    /* -- Funciones para mostrar las queries realizadas --------------------------------- */
    /* ---------------------------------------------------------------------------------- */

    /**
     * Permite mostrar las Queries realizadas durante el request
     */
    public function performed_queries() {

        $styled_queries = Array();
        foreach ($this->db->queries as $each_query)
            $styled_queries[] = $this->add_style_to_sql($each_query);
        return $styled_queries;
    }

    /**
     * Modifica codigo sql para ser visualizado como html agregando colores.
     * @param  <string> $sql_string
     * @return add_style_to_sql
     */
    private function add_style_to_sql($sql_string = '') {
        $styled_sql = $sql_string;

        $styled_sql = str_replace('select ', 'SELECT ', $styled_sql);
        $styled_sql = str_replace('SELECT ', '<b style="color:darkblue">SELECT </b>', $styled_sql);

        $styled_sql = str_replace('where ', 'WHERE ', $styled_sql);
        $styled_sql = str_replace('WHERE ', '<b style="color:green">WHERE </b>', $styled_sql);

        $styled_sql = str_replace('and ', 'AND ', $styled_sql);
        $styled_sql = str_replace('AND ', '<b style="color:green">AND </b>', $styled_sql);

        $styled_sql = str_replace('from', 'FROM ', $styled_sql);
        $styled_sql = str_replace('FROM', '<b style="color:darkblue">FROM </b>', $styled_sql);

        return $styled_sql;
    }

    /**
     * Chequea que el usuario tenga acceso a la seccion al a que desea ingresar
     *
     * @return boolean / redirect
     */
    public function check_menu_acces() {
        if (!isset($this->_user_session))
            return(FALSE);

        $controller_name = $this->uri->segment(1);
        //si no viene nada est{a en Focus/, todos tienen acceso a esa pantalla mientras esten logueados
        if (!$controller_name)
            return (TRUE);

        $user_menu_options = $this->session->userdata('user_options');
        foreach ($user_menu_options as $option) {
            if ($option->controller == $controller_name || $controller_name == 'user_profiles')
                return (TRUE);
        }
        redirect(base_url());
        return true;
    }

/*
* Funcion que devulve el ultimo commit hecho en git David Eduardo 30/06/2017
*/
    public static function get_last_commit(){
        $output = Array();
        $return_var = 0;
        $command = "git rev-list --format=format:'%ci' --max-count=1 `git rev-parse HEAD`";
        exec ($command , $output , $return_var);
        //Si el valor de retorno es !=0 devuelvo la fecha del ultimo commit, sino null
        return ($return_var == 0)?'Commit: '.substr($output[0],7,7)." - ".substr($output[1],0,-5):null;
    }


    /**
     * Funcion para poder leer un archivo grande sin que php se quede sin memoria
     *
     * @param <String> nombre del archivo a leer
     * @param <Integer> tamaño de la porcion a obtener
     * @param <function> funcion(array,handle,iteracion) se usa para hacer algo con esa porcion del archivo
     * @return <Boolean>
     */
    protected function file_get_contents_chunked($file,$chunk_size,$callback)
    {
        try
        {
            $handle = fopen($file, "r");
            $i = 0;
            while (!feof($handle))
            {
                call_user_func_array($callback,array(fread($handle,$chunk_size),&$handle,$i));
                $i++;
            }

            fclose($handle);

        }
        catch(Exception $e)
        {
             trigger_error("file_get_contents_chunked::" . $e->getMessage(),E_USER_NOTICE);
             return false;
        }

        return true;
    }


}
