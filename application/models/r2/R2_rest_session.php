<?php

/**
 * Description of R2_Db_Action_Log
 *
 * @author ABayerl
 * @abstract   Model para Acciones sobre la DB
 * @package    r2_core
 *
 */
class R2_Rest_Session extends R2_DbObject {

    protected static $_table_name = 'r2_rest_sessions';
    protected static $_display_column = 'timestamp';
    protected static $_display_name = 'Sesion REST';
    protected static $_plural_name = 'Sesiones REST';
    protected static $_table_schema = 'public';
    protected static $_log_activity = FALSE;

    public $timestamp;
    public $session_id;
    public $user_id;

    //Validez de la sesion rest en segundos
    protected static $_valid_session = 3600;

    // Construct
    public function __construct()
    {
        parent::__construct();
    }

    /*
     * funcion que devuelve si la session expiro o cuanto falta para que lo haga
     */
    public function expired()
    {
        if((time() - $this->timestamp) >= static::$_valid_session )
            return true;

        return static::$_valid_session - (time() - $this->timestamp);
    }

}
