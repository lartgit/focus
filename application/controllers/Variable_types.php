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
class Variable_types extends Entity_Admin {

    public function __construct() {
        // Le mandamos al controller padre el nombre del controller y de la clase que administra
        parent::__construct('variable_types', 'Variable_type');

        $this->success = R2_session::flashdata('messages');
        $this->errors = R2_session::flashdata('err_messages');
    }

    /**
     * Index de la clase
     */
    public function index($_ = false) {
        $this->url_back = NULL;
        $class = $this->managed_class;
        $this->instances = Variable_type::get_index_data();
        $this->load_view_with_layout($this->list_view_for($class));
    }
}
