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
class R2_Stats extends CI_Model {

    static function get_rest($user, $data, &$error_string) {
        $CI = get_instance();

        $CI->db->select("count(*) as count");
        $CI->db->where("controller", "R2_session_manager");
        $CI->db->where("method", "authenticate");
        $CI->db->where("http_response_code", "303");
        $CI->db->where("created_at >", "(now() - '1 month'::interval)", false);
        $login_count_last_month = $CI->db->get('r2_log_activity')->result()[0]->count;

        $res = array(
            'login_count_last_month' => $login_count_last_month,
        );

        return array($res, 200);
    }

}
