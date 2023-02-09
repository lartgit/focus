<?php

defined('BASEPATH') OR exit('No direct script access allowed');

/**
 * Manager class of RESTfull calls.
 *
 * @package r2_framework_rest
 */
class Stats extends Rest {
    public static $rest_model_manager = 'R2_Stats';

    public static $get_method = 'get_rest';
    // public static $post_method = 'create_session';
    // public static $put_method = 'edit_session';
    // public static $delete_method = 'delete_session';

    public static $no_login = TRUE;
}
