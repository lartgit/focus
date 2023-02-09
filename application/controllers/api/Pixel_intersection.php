<?php

defined('BASEPATH') OR exit('No direct script access allowed');

/**
 * Manager class of RESTfull calls.
 *
 * @package r2_framework_rest
 */
class Pixel_Intersection extends Rest {
    public static $rest_model_manager = 'Pixel';

    // public static $get_method = 'get_rest';
    public static $post_method = 'post_rest';
    // public static $put_method = 'edit_rest';
    // public static $delete_method = 'delete_rest';
}
