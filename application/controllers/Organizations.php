<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 *    Controller de Clients
 * 
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class Organizations extends Entity_Admin {

    public function __construct() {

        // Le mandamos al controller padre el nombre del controller y de la clase que administra
        parent::__construct('organizations', 'Organization');
        $this->url_index = $this->url . '/organizations/index';
        // $this->list_view = 'entities/list_users';

        $this->success = R2_session::flashdata('messages');
        $this->errors = R2_session::flashdata('err_messages');
    }

    public function index($success = FALSE) {
        $this->url_back = NULL;
        $class = $this->managed_class;
        $this->instances = $this->get_instances();

        $this->load_view_with_layout($this->list_view);
    }

}