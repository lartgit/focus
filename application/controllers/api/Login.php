<?php

defined('BASEPATH') OR exit('No direct script access allowed');

/**
 * Manager class of RESTfull calls.
 *
 * @package r2_framework_rest
 */
class Login extends Rest {
    public static $rest_model_manager = 'R2_Rest_Session';

    public static $get_method = 'get_sessions';
    public static $post_method = 'create_session';
    public static $put_method = 'edit_session';
    public static $delete_method = 'delete_session';

    public static $no_login = TRUE;
}
