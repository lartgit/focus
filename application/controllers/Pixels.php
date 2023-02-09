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
class Pixels extends Entity_Admin {

    public $list_view = 'entities/list_pixel';

    // public $date;

    public function __construct()
    {
        // Le mandamos al controller padre el nombre del controller y de la clase que administra
        parent::__construct('Pixels', 'Pixel');

        $this->url_action = $this->_url_site . '/Pixels/download_as_shp/';

        $this->model = new $this->managed_class;
    }

    public function index($success = FALSE) {
        $this->pixel_sets = Pixel_set::all_permitted();
        $this->load_view_with_layout($this->list_view_for($this->managed_class));
    }

    public function download_as_shp()
    {
        $record_limit = $this->input->post('record_limit');
        $set_id = $this->input->post('set_id');

        $ret = $this->model->download_as_shp($record_limit, $set_id);

        if ($ret) {
            echo 0;
        } else {
            echo 1;
        }
    }

}
