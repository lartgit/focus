<?php

/**
 * Description of R2_Db_Action_Log
 *
 * @author ABayerl
 * @abstract   Model para Acciones sobre la DB
 * @package    r2_core
 *
 */
class R2_Db_Action_Log extends R2_DbObject {

    protected static $_table_name = 'db_actions_logs';
    protected static $_primary_key = 'id';
    protected static $_display_column = 'action';
    protected static $_ts_column = 'ts';
    protected static $_display_name = 'Accion sobre la DB';
    protected static $_plural_name = 'Acciones sobre la DB';
    protected static $_table_schema = 'public';
    protected static $_log_activity = FALSE;

    public $action;
    public $user_id;
    public $affected_entity;
    public $full_query;
    public $description;

    // Construct
    public function __construct()
    {
        parent::__construct();
    }

}
