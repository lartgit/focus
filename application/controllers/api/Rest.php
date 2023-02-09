<?php

defined('BASEPATH') OR exit('No direct script access allowed');

require APPPATH . '/libraries/REST_Controller.php';

class Rest extends REST_Controller {

    function __construct()
    {
        parent::__construct();

        $this->load->helper('r2_language');
    }

    private function send_response($status, $message)
    {
        return $this->response(array(
                    $this->config->item('rest_status_field_name') => $status,
                    $this->config->item('rest_message_field_name') => $message
        ));
    }

    function login_post()
    {
        $data = file_get_contents('php://input');

        if (trim($data) === '')
            return $this->send_response('WARNING', 'server_error_try_again');

        $data = json_decode($data);

        if (is_null($data) || !isset($data->user_name) || !isset($data->password))
            return $this->send_response('ERROR', 'invalid_request');

        $session = new R2_Session();
        $ssid = $session->rest_authenticate($data->user_name, $data->password);

        if ($ssid !== FALSE) {
            $ret[$this->config->item('rest_status_field_name')] = 'OK';
            $ret['session_id'] = $ssid['session_id'];
            $ret['expiration'] = $ssid['timestamp'];
        } else {
            $ret[$this->config->item('rest_status_field_name')] = 'ERROR';
        }
        $ret[$this->config->item('rest_message_field_name')] = $session->last_error;

        $this->response($ret);
    }

    function get_data_post()
    {
        //Tengo que ver a que usuario le tengo que buscar la info
        $data = file_get_contents('php://input');
        if (trim($data) === '')
            return $this->send_response('WARNING', 'server_error_try_again');

        $data = json_decode($data);
        if (is_null($data) || !isset($data->session_id))
            return $this->send_response('ERROR', 'invalid_request');

        //Me fijo si la session es valida.
        $session = new R2_Session();
        $this->user = $session->get_user_with_ssid($data->session_id);

        if (!$this->user)
            return $this->send_response('ERROR', $session->last_error);

        $error_string = '';
        $result = R2_Rest_Handler::rest_query($this->user, $data, $error_string);

        if ($result === FALSE) {
            if (!empty($error_string))
                return $this->send_response('ERROR', $error_string);
            else
                return $this->send_response('ERROR', 'error_getting_data');
        }

        $ret[$this->config->item('rest_status_field_name')] = 'OK';
        $ret[$this->config->item('rest_message_field_name')] = '';
        $ret['result'] = $result;
        return $this->response($ret);
    }
}
