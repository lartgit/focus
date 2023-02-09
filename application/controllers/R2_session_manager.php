<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description of Session_manager
 *    Controller para manejar el acceso de los usuarios a la aplicación.
 *
 * @author NArias 2014
 *
 */
class R2_session_manager extends R2_abstract_controller {

    protected $_loginView = 'login/login';
    protected $_registerView = 'login/register';
    protected $_pswRecoverView = 'login/password_recover';
    protected $_pswChangeView = 'login/password_change';
    public $_view_header = 'login/header';
    public $_view_footer = 'login/footer';
    protected $url;
    public $done_change_psw;
    public $url_auth;
    public $url_psw_recover;
    public $url_psw_recover_submit;
    public $url_psw_change;
    public $url_psw_save;
    public $url_send;
    public $url_register;
    public $url_doctor_register;
    public $url_activation;
    public $url_save_register;
    public $url_registration;
    public $url_download_pdf_disclaimer;
    public $url_check_email_ajax;

    function __construct() {
        parent::__construct();
        $this->done_change_psw = NULL;
        // Urls
        $this->url = site_url('R2_session_manager');
        $this->url_auth = $this->url . '/authenticate';
        $this->url_psw_recover = $this->url . '/password_recover';
        $this->url_psw_recover_submit = $this->url . '/password_recover_submit';
        $this->url_register = $this->url . '/register';
        $this->url_save_register = $this->url . '/save_register';
        $this->url_send = $this->url . '/send_link';
        $this->url_psw_change = $this->url . '/password_change';
        $this->url_psw_save = $this->url . '/password_save';
        $this->url_activation = $this->url . '/activate_user';
        $this->url_registration = $this->url . '/register_user';
        $this->url_check_email_ajax = $this->url . '/check_email_ajax';
        
        // Header View
        $this->_header_view_data['url_register'] = $this->url_register;
        $this->_header_view_data['manager'] = $this;
    }

    /**
     * Hook para poder cargar distinto la view del login
     *
     * @param type $view_name
     * @param type $data_array
     */
    public function load_view_method($view_name, $data_array) {
        // Si no viene un valor se le manda $this a la vista.

        $data_array = ( $data_array ? $data_array : $this);

        // Si se tiene un header especificado, se carga antes de la view.
        if ($this->_view_header)
            $this->load->view($this->_view_header, $data_array);

        // Se hace el load de la view.
        if ($view_name)
            $this->load->view($view_name, $data_array);

        // Si tiene un footer especificado, se carga luego de la view.
        if ($this->_view_footer)
            $this->load->view($this->_view_footer, $data_array);

        // Herramienta de debuggin
//        if ($this->is_developing_mode()) {
//            $viewData->view_name = $view_name;
//            $viewData->queries = $this->performed_queries();
//            $this->load->view($this->_view_queries, $viewData);
//        }
    }

    /* --------------------------------- */
    /* ------ Actions Principales ------ */
    /* --------------------------------- */

    public function index() {
        $this->login();
    }

    /**
     * Función principal del controller.
     */
    public function login() {
        //me fijo si hay algo que mostrar de la sesion
        $this->error_string = $this->_user_session->flashdata('error_string');
        if(!$this->_user_session->flashdata('done_change_psw')==NULL){
            $this->done_change_psw = $this->_user_session->flashdata('done_change_psw');
        }
        $this->_user_session->session_destroy();
        
        $this->load_view_method($this->_loginView, $this);
        
    }

    /**
     * Permite registrar un nuevo usuario.
     */
    public function register() {
        $this->load_view_method($this->_registerView, $this);
    }

    /**
     * Permite que al usuario recuperar su password.
     */
    public function password_recover() {
        $this->load_view_method($this->_pswRecoverView, $this);
    }

    public function password_recover_submit() {
        $data = $this->input->post('email');
       
        if ($data) {
            $ret = $this->_user_session->send_password_recovery_email($data, site_url() . "/R2_session_manager/password_change");

            if (!$ret) {
                
                $this->load_invalid_recover_view($this->_user_session->last_error);
            } else {
                
                $this->load_invalid_recover_view('Se ha enviado un mensaje a su casilla de correo.</br>El mensaje puede demorar algunos minutos en llegar a destino.', true);
            }
        } else {
            $this->load_view_method($this->_pswRecoverView, $this);
        }
    }

    /**
     * Realiza la acción de desloguear al usuario del sistema destruyendo la sesión.
     */
    public function logout() {
        $this->_user_session->session_destroy();
        redirect($this->url);
    }

    /* --------------------------------- */
    /* ------ Actions Complejas -------- */
    /* --------------------------------- */

    /**
     * Realiza la accion de autenticar y crea la session del usuario en el sistema.
     *
     */
    public function authenticate() {
        $this->_track_activity = TRUE;

        $this->_user_session->set_flashdata('done_change_psw',NULL);
        $this->_user_session->set_flashdata('error_string',NULL);
        $userName = $this->input->post('email');
        $password = $this->input->post('password');
        $keep_user_logued_in = ($this->input->post('remember') == "on") ? TRUE : FALSE;

        if (!$userName || !$password) {
           
            $this->load_invalid_login_view('Debe ingresar un usuario y una contraseña');
            return;
        }

        $isCorrect = $this->_user_session->authenticate($userName, $password, $keep_user_logued_in);

        if ($isCorrect) {
           
            $user = $this->_user_session->get_user_from_session_data();
            redirect($this->_user_session->user_base_page());
        } elseif ($this->_user_session->last_error === 'password_reset') {
            $error_text = $this->disclaimer_text->get_text('password_reset');
            $this->load_invalid_recover_view($error_text);
            return;
        } else {

            $this->load_invalid_login_view($this->_user_session->last_error);
        }
    }

    /**
     * load_invalid_login_view()
     *  Muestra el mensaje de error y carga la vista de login.
     *
     */
    public function load_invalid_login_view($error_string) {
        $this->_header_view_data['error_string'] = $error_string;
        $this->_header_view_data['done_change_psw'] = NULL;
        $this->_header_view_data['url_auth'] = $this->url_auth;
        $this->_header_view_data['url_psw_recover'] = $this->url_psw_recover;
        $this->_header_view_data['url_psw_recover_submit'] = $this->url_psw_recover_submit;
        $this->_header_view_data['url_doctor_register'] = $this->url_doctor_register;
        $this->load_view_method($this->_loginView, $this->_header_view_data);
    }

    public function load_invalid_recover_view($error_string, $disabled_all = NULL) {
        $this->_header_view_data['error_string'] = $error_string;
        $this->_header_view_data['disabled_all'] = $disabled_all;
        $this->_header_view_data['_url_login'] = $this->_url_login;
        $this->_header_view_data['url_auth'] = $this->url_auth;
        $this->_header_view_data['url_psw_recover'] = $this->url_psw_recover;
        $this->_header_view_data['url_psw_recover_submit'] = $this->url_psw_recover_submit;
        $this->_header_view_data['url_doctor_register'] = $this->url_doctor_register;
        $this->load_view_method($this->_pswRecoverView, $this->_header_view_data);
    }

    /**
     * Se encarga de validar los datos del registro y crear un nuevo usuario.
     *
     * @return type
     */
    public function save_register() {
        $this->name = trim($this->input->post('name'));
        $this->password = $this->input->post('password');
        $this->password_confirm = $this->input->post('password_confirm');
        $this->email = trim($this->input->post('email'));

        if (!$this->name || !$this->password || !$this->password_confirm || !$this->email) {
            $this->error_string = "Debe llenar todos los campos";
            $this->load_view_method($this->_registerView, $this);
            return;
        }

        if ($this->password != $this->password_confirm) {
            $this->error_string = "Los contraseñas ingresados no concuerdan";
            $this->load_view_method($this->_registerView, $this);
            return;
        }

        if ($this->_user_session->user_with_name_exists($this->name)) {
            $this->error_string = "El nombre de usuario ingresado ya existe";
            $this->load_view_method($this->_registerView, $this);
            return;
        }

        $this->_user_session->create_user($this->name, $this->password, $this->email);
        $this->_user_session->send_activation_email($this->name, $this->email, $this->url_activation);

        $this->email_sent = TRUE;
        $this->success[] = "Se ha enviado un email a su cuenta.";
        $this->load_view_method($this->_registerView, $this);
    }

    /**
     * send_link()
     *
     */
    public function send_link() {
        $user_or_email = $this->input->post('user_or_email');

        $user = $this->_user_session->get_user_with_name_or_email($user_or_email);

        if ($user) {
            $this->_user_session->send_password_change_email_to($user, $this->url_psw_change);
            $this->_header_view_data['error_string'] = 'Se ha enviado el email';
            $this->_header_view_data['mail_sent'] = TRUE;
            $this->_header_view_data['user_or_email'] = $user_or_email;
            $this->_header_view_data['url_send'] = $this->url;
        } else {
            $this->_header_view_data['error_string'] = 'Nombre de usuario o email inválidos';
            $this->_header_view_data['url_send'] = $this->url_send;
        }

        $this->load_view_method($this->_pswRecoverView, $this->_header_view_data);
    }

    public function password_save() {
        $data = $this->input->post();
        $user = $this->_user_session->get_user_with_activation_code($data['code']);
        
        if (!$data['password'] || !$data['password_confirm']){
          
            $this->_header_view_data['code'] = $data['code'];
            //$this->_header_view_data['email'] = $user->email;
            $this->_header_view_data['url_psw_save'] = $this->url_psw_save;
            $this->_header_view_data['error_string'] = 'Complete los campos';
            $this->load_view_method($this->_pswChangeView, $this->_header_view_data);
            return;
        }
       
        if ($data['password'] != $data['password_confirm']) {
           
            $this->_header_view_data['code'] = $data['code'];
            //$this->_header_view_data['email'] = $user->email;
            $this->_header_view_data['url_psw_save'] = $this->url_psw_save;
            $this->_header_view_data['error_string'] = 'Las contraseñas ingresadas no concuerdan';
            $this->load_view_method($this->_pswChangeView, $this->_header_view_data);
            return;
        }
        
        $this->_user_session->update_user_password($user, $data['password']);
        $this->_user_session->update_user_activation_code($user, '');
       
        $this->_user_session->set_flashdata('done_change_psw',TRUE);
        redirect($this->url);
    }

    public function password_change() {

        $code = $this->uri->segment(3);

        $user = $this->_user_session->get_user_with_activation_code($code);

        if ((!$user) || (!($user->activation_code == $code)))
            redirect($this->url);

        $this->_header_view_data['code'] = $code;
        $this->_header_view_data['url_psw_save'] = $this->url_psw_save;
        $this->load_view_method($this->_pswChangeView, $this->_header_view_data);
    }

    public function activate_user() {
        $user_name = $this->uri->segment(3);
        $code = $this->uri->segment(4);

        $user = $this->_user_session->get_user_with_name_or_email($user_name);

        if ((!$user) || (!($user->activation_code == $code)))
            redirect($this->url);

        $this->_user_session->activate_user($user);

        $this->_header_view_data['email_sent'] = TRUE;
        $this->_header_view_data['url'] = $this->url;
        $this->_header_view_data['error_string'] = "Se ha activado el usuario: $user_name";
        $this->_header_view_data['url_save_register'] = $this->url_save_register;
        $this->load_view_method($this->_registerView, $this->_header_view_data);
    }

    public function register_user() {
        $code = $this->uri->segment(3);

        $user = $this->_user_session->get_user_with_activation_code($code);

        if ((!$user) || (!($user->activation_code === $code)))
            redirect($this->url);

        $this->_header_view_data['code'] = $code;
        $this->_header_view_data['email'] = $user->email;
        $this->_header_view_data['url_psw_save'] = $this->url_psw_save;
        $this->load_view_method($this->_pswChangeView, $this->_header_view_data);
    }

    /**
     * recibe por post el el form y chequea si el email ya existe en la base
     *
     * @return string
     *
     */
    public function check_email_ajax() {

        $email = $this->input->post('email');
        $user = $this->_user_session->get_user_with_name_or_email($email);
        if (!empty($user)) {
            // $this->form_validation->set_message('comprobar_email_ajax', '%s: ya existe en la base de datos');
            echo 'El e-mail ya existe en el sistema';
            return FALSE;
        } else {
            return TRUE;
        }
    }

}
