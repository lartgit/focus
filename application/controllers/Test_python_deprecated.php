<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 *    Controller de Downloads
 * 
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class Test_python extends Focus_base_controller
{
    public function __construct()
    {
        parent::__construct();

        $this->url_ajax = base_url('index.php') . '/Test_python/set_python_file_tmp_to_valid';
        $this->url_ajax_python_save = base_url('index.php') . '/Test_python/save_python_valid_python_file';
        $this->url_ajax_get_python_file = base_url('index.php') . '/Test_python/get_python_data';

        $this->basic_template_url =  "./scripts/focus2_process/basic_template.py";
    }

    public function index()
    {
        $this->get_data = $this->input->get();

        $this->basic_template_data = file_get_contents($this->basic_template_url);
        $this->instances = array();
        if (isset($this->get_data['fx_id'])) {
            $this->function_id = $this->get_data['fx_id'];
        }

        $this->load_view_with_layout('test_python/index');
    }

    public function check_python_validity()
    {
        // Escapamos los comandos que le vamos a enviar al bash
        $command = escapeshellcmd('./uploads/tests_py/test.py');
        $output = shell_exec("python $command");

        return $output;
    }

    public function set_python_file_tmp_to_valid()
    {
        $data =  $this->input->post('prm1');

        $file  = './uploads/tests_py/test_tmp.py';

        $txt = $data;

        file_put_contents($file, $txt);

        $ret = $this->check_python_validity();
        $string = trim(preg_replace('/\s\s+/', ' ', $ret));
        echo $string;
    }

    public function get_python_data()
    {
        $data =  $this->input->post();

        $fx_row = Function_creator::find($data['fx_id']);

        $file_data = file_get_contents($fx_row->path);

        echo $file_data;
    }

    /**
     * Guarda el
     */
    public function save_python_valid_python_file()
    {
        $data =  $this->input->post();
        $file  = '';
        $txt = '';
        if (isset($data['prm1']) && $data['prm1'] != '') {
            $txt = $data['prm1'];
        }

        if (isset($data['fx_id']) && $data['fx_id'] != '') {
            $file = Function_creator::find($data['fx_id'])->path;
        }

        file_put_contents($file, $txt);

        echo "true";
    }
}
