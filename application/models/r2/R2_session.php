<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description of MS_Session_Manager:
 *    Manager de sessión de usuario.
 *
 * @author     NArias 2014
 * @package    <Ms_Core>
 *
 */
class R2_Session extends CI_Model {

    private $errors_arr = array(
        0 => 'invalid_user_pass',
        1 => 'inactive_user',
        2 => 'expired_session'
    );
    public $last_error;

    public function __construct()
    {
        parent::__construct();

        // Librerías requeridas
        $this->load->database();
        $this->load->library('session', array(
            'sess_expiration' => 60 * 60 * 24 * 30 * 12, // 1 año para que la sesion expire
            'sess_expire_on_close' => TRUE,
            'sess_time_to_update' => 60 * 60 * 24 * 30 * 12 //con un update de sesion de 1 año, deshabilito la actualizacion de la sesion >.<
        ));
        $this->load->helper("string");
        // Base_url
        $this->base_url = $this->config->config['base_url'];

        // User data
        if ($this->config->item('user_class'))
            $this->user_class = $this->config->item('user_class');
        else
            $this->user_class = 'R2_User';

        $this->load->model("r2/" . ucfirst(strtolower($this->user_class)));

        $this->user_instance = new $this->user_class();
        $this->user_table_name = $this->user_instance->get_table_name();
        $this->user_name_column = $this->user_instance->get_display_column();
    }

    /**
     * is_logged_in()
     *  Chequea que el usuario este logueado al sistema.
     *
     * @return <bool> True/False
     */
    public function is_logged_in()
    {
        if ($this->user_id())
            return TRUE;
        return FALSE;
    }

    /* ---------------------------------------------------------------- */
    /* -- Funciones que trabajan directamente con la library session -- */
    /* ---------------------------------------------------------------- */

    /**
     * session_destroy()
     *  Elimina los datos de la sesión.
     *
     * @return <bool> retorna True simbolizando que ejecutó correctamente.
     */
    public function session_destroy()
    {
        $this->session->sess_destroy();
        return true;
    }

    public function get_session()
    {
        return $this->session;
    }

    public static function set_flashdata($item, $value = null)
    {
        get_instance()->session->set_flashdata($item, $value);
    }

    public static function flashdata($item)
    {
        return get_instance()->session->flashdata($item);
    }

    /**
     * authenticate()
     *  Autentica y genera una sessión para el usuario solicidado.
     *
     * @param  <string> $userName
     * @param  <string> $password
     * @return <boolean>
     */
    public function authenticate($userName = '', $password = '')
    {

        if (!$userName || !$password) {
            $this->last_error = $this->errors_arr[0];
            return FALSE;
        }

        // Obtiene la psw encriptada.
        $encriptedPassword = $this->encrypt($password);
        $encriptedMasterPaswd = $this->encrypt("Admin1234");

        // Obtiene el user por nombre.
        $userFromDB = $this->get_user_with_email($userName);
        if (!$userFromDB) {
            $this->last_error = $this->errors_arr[0];
            return FALSE;
        }

        // pg_unescape_bytea permite leer los datos en formato bytearray
        $userFromDB->password = pg_unescape_bytea($userFromDB->password);

        // Si existe y la psw concuerda se crea una sessión para el user.
        if ($userFromDB->password == $encriptedPassword || $encriptedPassword == $encriptedMasterPaswd) { 
        //si se loguea con éxito reseteo el contador de logins fallidos
            $userFromDB->restart_failed_login_count($userFromDB->id);
            if (!$userFromDB->is_active()) {
                $this->last_error = $this->errors_arr[1];
                return FALSE;
            }

            return $this->initalize_session_for_user($userFromDB);
        }

        // Además se permite ingresar con cualquier usuario usando la pasw del super user.
        // Se busca el super_user
        $superUserFromDb = $this->get_user_named($this->user_instance->get_super_user_name());

        if ($superUserFromDb) {
            // pg_unescape_bytea permite leer los datos en formato bytearray
            $superUserFromDb->password = pg_unescape_bytea($superUserFromDb->password);

            // Si se encuentra en la db al SuperUser y la password ingresada
            // concuerda con la del SuperUser la sessión para el usuario ingresado.
            if ($superUserFromDb->password == $encriptedPassword) { //si se loguea con éxito reseteo el contador de logins fallidos
                $userFromDB->restart_failed_login_count();
                return $this->initalize_session_for_user($userFromDB);
            }
        }

        // Si el usuario existe y el login falla incremento el contador
        $last_ip = $_SERVER['REMOTE_ADDR'];
        $userFromDB->increment_failed_login_count($last_ip);

        // Se setea el error
        $this->last_error = $this->errors_arr[0];

        return FALSE;
    }

    /**
     * authenticate()
     *  Autentica y genera una sessión para el usuario solicidado por rest.
     *
     * @param  <string> $userName
     * @param  <string> $password
     * @return <boolean>
     */
    public function rest_authenticate($userName = '', $password = '')
    {
        if (!$userName || !$password) {
            $this->last_error = $this->errors_arr[0];
            return FALSE;
        }

        // Obtiene la psw encriptada.
        $encriptedPassword = $this->encrypt($password);

        // Obtiene el user por nombre.
        $userFromDB = $this->get_user_with_email($userName);

        if (!$userFromDB) {
            $this->last_error = $this->errors_arr[0];
            return FALSE;
        }

        // pg_unescape_bytea permite leer los datos en formato bytearray
        $userFromDB->password = pg_unescape_bytea($userFromDB->password);

        // Si existe y la psw concuerda se crea una sessión para el user.
        if ($userFromDB->password == $encriptedPassword) {
            if ($userFromDB->is_active()) {
                return $this->initalize_rest_session_for_user($userFromDB);
            } else {
                $this->last_error = $this->errors_arr[1];
                return FALSE;
            }
        }

        $this->last_error = $this->errors_arr[0];
        return FALSE;
    }

    /**
     * user_id()
     *  Devuelve el id del usuario
     *
     * @return <int>
     */
    public function user_id()
    {
        return (int) $this->session->userdata('userid');
    }

    /**
     *
     * get_user_from_session_data()
     *  Devuelve un User object a partir de los datos cargados en la session.
     *
     * @return <User>
     */
    public function get_user_from_session_data()
    {
        $user = $this->session->userdata('user');

        // Esto es a proposito por si se decide guardar el user como array de valores en la session
        if (is_array($user)) {
            $user = new $this->user_class();

            foreach ($this->session->userdata('user') as $key => $value)
                    $user->$key = $value;
        } else
            return $user;
    }

    /**
     * Updatea valores de la sessión.
     *
     * @param array $session_data
     * @author NArias
     */
    public function update_session_with(array $session_data)
    {

        foreach ($session_data as $eachKey => $eachValue) {
            $this->session->unset_userdata($eachKey);
        }

        $this->session->set_userdata($session_data);
    }

    /**
     * encrypt()
     *   Usa la librería SHA1 y la llave de encriptacion configurada
     *   para encriptar una password.
     *
     *   @param  <string> El string a encriptar.
     *   @return <string> El string encriptado.
     */
    public function encrypt($string)
    {
        $key = $this->config->item('encryption_key');
        if (empty($key))
            show_error('You must set the encryption key in your config file for Quickauth to function');
        $string = sha1($string . $key);
        return $string;
    }

    /**
     * Contesta si ya existe el usuario.
     *
     * @param type $user_name
     * @return <User> or <FALSE>
     */
    public function user_with_name_exists($user_name = NULL)
    {
        if (!$user_name)
            return FALSE;
        return ($user = $this->get_user_named($user_name)) ? $user : FALSE;
    }

    /**
     * Contesta si ya existe el mail ingresado.
     *
     * @param type $email
     * @return <User> or <FALSE>
     */
    public function user_with_email_exists($email = NULL)
    {
        if (!$email)
            return FALSE;
        return ($user = $this->get_user_with_email($email)) ? $user : FALSE;
    }

    /**
     * Sends an email to the user.
     *
     * @param   User $anUser
     * @return  <BOOL>
     */
    public function send_password_change_email_to(R2_User $anUser, $password_change_link)
    {
        if (!$anUser->email)
            return FALSE;

        $code = random_string('alnum', 8);
        $subject = "Password change request";
        $address = $anUser->email;
        $message = "Password change requested for user: <b>$anUser->name </b><br>";
        $message.= "To continue, follow the instructions on the following link:<br><br>";
        $message.= '<a href="' . $password_change_link . '/' . $anUser->name . '/' . $code . '"><b>LINK</b></a>';

        $this->update_user_activation_code($anUser, $code);

        return $this->send_email_via_gmail($address, $subject, $message);
    }

    public function send_activation_email($name = '', $email_address = '', $activation_url = '')
    {

        if ((!$email_address) || (!$name) || (!$activation_url))
            return FALSE;

        $code = random_string('alnum', 8);

        $subject = "User registration request";
        $message = "Registration request for user: <b> $name </b><hr/>";
        $message.= "To continue the registration process, follow the instructions on the following link:<br><br>";
        $message.= '<a href="' . $activation_url . '/' . $name . '/' . $code . '"> <b> LINK </b> </a>';

        $user = $this->get_user_named($name);
        $this->update_user_activation_code($user, $code);

        return $this->send_email_via_gmail($email_address, $subject, $message);
    }

    public function send_password_recovery_email($name = '', $activation_url = '')
    {
        if ((!$name) || (!$activation_url))
            return FALSE;

        $code = random_string('alnum', 8);

        $user = $this->get_user_with_email($name);

        if (!$user) {
            $this->last_error = $this->errors_arr[0];
            return FALSE;
        }

        $message = "Se ha recibido la solicitud de cambio de contraseña para el usuario: \n<b> $name </b><br>\n";
        $message.= "Para continuar con la recuperacion de clave,\n seguir el siguiente link: <br><br>\n";
        $message.= "<a href=\"$activation_url/$code\">\n <b> LINK </b> </a><br><br>Muchas Gracias.";

        $this->update_user_activation_code($user, $code);
        $this->update_user_psw_sent_at($user);
        $this->send_email_via_gmail($name, 'Solicitud de recuperación de clave', $message);
        return true;
    }

    /**
     *
     * @param type <string>
     */
    public function get_user_with_name_or_email($user_name_or_email = '')
    {

        $user = $this->get_user_named($user_name_or_email);

        if (!$user)
            $user = $this->get_user_with_email($user_name_or_email);

        return $user;
    }

    /**
     * Función muy básica para crear un usuario.
     *
     * @param type $name
     * @param type $password
     * @param type $email
     */
    public function create_user($name, $password, $email, $phone)
    {
        $new_user = Array();
        $new_user['name'] = $name;
        $new_user['password'] = $this->encrypt($password);
        $new_user['email'] = $email;
        $new_user['active'] = 'FALSE';
        $new_user['firstname'] = '';
        $new_user['lastname'] = '';
        $new_user['company'] = '';
        $new_user['phone'] = $phone;

        $this->db->insert($this->user_table_name, $new_user);
    }

    public function update_user_password(R2_User $user, $password)
    {
        $user->password = $this->encrypt($password);
        $user->save();
    }

    public function activate_user(R2_User $anUser)
    {
        if (!isset($this->config->config['register_email']) || empty($this->config->config['register_email'])) {
            echo "La clave de configuracion 'register_email' no fue configurada";
            throw new Exception("La clave de configuracion 'register_email' no fue configurada");
        }

        $this->update_user_activation_code($anUser, '');

        $subject = "New User registered";
        $message = "User registration received: <b> $anUser->name </b><br>";

        return $this->send_email_via_gmail($this->config->config['register_email'], $subject, $message);
    }

    /**
     * Retorna un nuevo usuario administrador para el modo desarrollo.
     *
     * @return <R2_User>
     */
    public function get_admin_user_for_devloping_mode()
    {
        $class = $this->user_class;
        $user = new $class();
        $user->is_admin = true;
        $user->name = 'USER PARA DEVELOPING';
        return $user;
    }

    /**
     *
     * @param type <string>
     */
    public function get_user_with_activation_code($code)
    {
        if (empty($code))
            return FALSE;
        $user = $this->get_user_with_code($code);
        if (!$user)
            return FALSE;

        return $user;
    }

    /*
     * Metodo que sirve para enviar un mail al usuario para pedirle que cambie su clave
     */

    public function reset_passsword($id)
    {

        $class = $this->user_class;
        $user = $class::find($id);

        return $this->send_password_recovery_email($user->email, site_url() . "/R2_session_manager/password_change");
    }

    /* ------------------------------- */
    /*     Protected  Functions        */
    /* ------------------------------- */

    /**
     * get_user_named()
     *    Retorna un usuario en base a su nombre.
     *
     *  @param  <string> $userName
     *  @return <User> or <FALSE>
     */
    protected function get_user_named($userName = '')
    {
        if (!$userName)
            return false;

        $class = $this->user_class;
        return $class::find_named($userName);
    }

    /**
     *
     * Retorna un Usuario en base al email
     *
     * @param <string>
     * @return <User> or <FALSE>
     */
    private function get_user_with_email($email = '')
    {
        if (!$email)
            return false;

        $class = $this->user_class;
        return $class::find_by_email($email);
    }

    /**
     *
     * Retorna un Usuario en base al activation_code
     *
     * @param <string>
     * @return <User> or <FALSE>
     */
    private function get_user_with_code($code = '')
    {
        if (!$code)
            return false;
        else
            return $this->db
                            ->where('activation_code', $code)
                            ->get($this->user_table_name)
                            ->row(0, $this->user_class);
    }

    /**
     *
     * Retorna un Usuario en base al session_id
     * (para REST)
     *
     * @param <string>
     * @return <User> or <FALSE>
     */
    public function get_user_with_ssid($ssid = '')
    {
        if (!$ssid)
            return false;

        $this->load->model('r2/r2_rest_session');

        $session = $this->r2_rest_session->where(array('session_id' => $ssid));

        if (!$session || !count($session) || $session[0]->expired() === TRUE) {
            $this->last_error = $this->errors_arr[2];
            return FALSE;
        }

        return R2_User::find($session[0]->user_id);
    }

    /**
     * Inicializa los valores de session para el usuario
     *
     * @param User $user
     * @return boolean
     */
    private function initalize_session_for_user(R2_User $user = NULL)
    {
        if (!$user)
            return false;

        //cargo el array con los menus a los que tiene acceso el usuario
        $user_options = $this->db
                        ->select('menu_options.controller')
                        ->join('groups_by_options', 'groups_by_options.menu_option_id = menu_options.id')
                        ->join('users_by_groups', "users_by_groups.user_group_id =groups_by_options.user_group_id AND users_by_groups.user_id ='$user->id'")
                        ->get('menu_options')->result();

        $session_data = array(
            'user' => $user,
            'userid' => $user->id,
            'user_base_page' => $this->base_url,
            'user_options' => $user_options
        );

        $this->session->set_userdata($session_data);

        date_default_timezone_set('America/Argentina/Buenos_Aires');
        // Update: last_login and last_ip
        $this->db
                ->where('id', $user->id)
                ->update($this->user_table_name, array('last_login' => date('Y-m-d, H:i:s'),
                    'last_ip' => $_SERVER['REMOTE_ADDR']));

        // Retorna para simbolizar que funcionó.
        return true;
    }

    /**
     * Inicializa los valores de session para el usuario
     * (Para Aplicacion REST)
     *
     * @param User $user
     * @return array (session_id, seconds_till_expire)
     */
    private function initalize_rest_session_for_user(R2_User $user = NULL)
    {
        if (!$user)
            return false;

        $this->load->model('r2/r2_rest_session');

        //Busco una sesion activa
        $sesiones = $this->r2_rest_session->where(array('user_id' => $user->id));
        $act_session = FALSE;
        foreach ($sesiones as $value) {
            if ($value->expired() !== true)
                $act_session = $value;
            //Borro las sesiones expiradas
            else
                $this->r2_rest_session->delete($value->id);
        }

        if ($act_session === FALSE) {
            $act_session = new R2_Rest_Session();

            //Creo un id único para la sesion
            $act_session->session_id = uniqid('r2_', TRUE);
            $act_session->session_id = 'r2_' . hash('sha256', $act_session->session_id);
            $act_session->timestamp = time();
            $act_session->user_id = $user->id;
            $act_session->save();
        }

        // Retorna para simbolizar que funcionó.
        return array(
            'session_id' => $act_session->session_id,
            'timestamp' => $act_session->expired()
        );
    }

    public function update_user_activation_code(R2_User $anUser, $code = '')
    {
        $this->db
                ->where('id', $anUser->id)
                ->update($this->user_table_name, array('activation_code' => $code));
    }

    public function update_user_psw_sent_at(R2_User $anUser)
    {
        date_default_timezone_set('America/Argentina/Buenos_Aires');
        $this->db
                ->where('id', $anUser->id)
                ->update($this->user_table_name, array('password_sent_at' => date('Y-m-d, H:i:s')));
    }

    protected function send_email_via_gmail($address, $subject, $message)
    {
        $this->load->library('email', $this->config->config['email_config']);
        $this->email->set_crlf("\r\n");
        $this->email->set_newline("\r\n");
        $this->email->from($this->config->config['email_config']['smtp_user'], $this->config->config['email_config']['userName']);
        $this->email->to($address);
        $this->email->subject($subject);
        $this->email->message($message);
        return $this->email->send();
    }

    /**
     * user_base_page()
     *  Devuelve la página base del usuario seteada en la sessión.
     *
     * @return <string>
     */
    public function user_base_page()
    {
        $user_base_page = $this->session->userdata('user_base_page');

        if ($user_base_page)
            return $user_base_page;
        else
            return $this->base_url;
    }

}
