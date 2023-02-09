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
class Actions_log extends Entity_Admin {

    public $downFile;
    public $form_view;
    public $class_name;
    public $dateFrom;
    public $dateTo;
    public $instances;
    public $event;

    public function __construct() {

        // Le mandamos al controller padre el nombre del controller y de la clase que administra
        parent::__construct('actions_log', 'Action_log');
        $this->url_download = $this->url . "/download";
        $this->edit_view = 'entities/list_action_log';
        $this->url_show = $this->url . "/show_obj/";
        $this->url_filter = $this->url . "/filter_logs_action/";
        $this->downFile = new R2_Upload_File();
        $this->form_view = 'entities/form_modal';
    }

    public function download($data_xls = null) {

        $dateFrom = $this->build_date_from($this->uri->segment(3));
        $dateTo = $this->build_date_to($this->uri->segment(4));
        
        $is_valid = $this->check_from_to($dateFrom, $dateTo);
        $class = $this->managed_class;

        if (!$is_valid) {
           $data_xls = $class::all_orderby('ts');
        }else{
           $data_xls = $class::logs_between($dateFrom,$dateTo);
        }  
        
        $templates = "assets/templates/template_logs.xlsx";
        $this->load->library('php_excel');      

        foreach ($data_xls as $row) {
            $object_class = $row->object_class;
            $row->object_class = $object_class::class_display_name();

            if (!is_null($row->user_id)) {
                $user = $this->user->find($row->user_id);
                $row->user_id = $user->name;
            } else {
                $row->user_id = 'Desconocido';
            }
        }

//        #En el ultimo elemento del array tengo los nombres de columna
//        #y el orden de los campos.
        $orden = array('object_class', 'object_id', 'event', 'ts', 'user_id');

        $this->php_excel->loadTemplate($templates);

        //Escribir datos de un array, desde que fila, desde que columna
//
        $this->php_excel->writeObjects($data_xls, $orden, 1, 0);
//
        $this->php_excel->save("logs.xlsx");

    }

    /**
     * Index de la clase
     */
    public function index($success = FALSE) {
        $this->url_back = NULL;
        //$class = $this->managed_class;
        //$this->instances = $class::all_orderby('ts');

        $this->date_from_to_show =  date('d/m/Y');
        $datetime = new DateTime('tomorrow');
        $_POST['dateFrom'] = date('d/m/Y');;
        $_POST['dateTo'] = $datetime->format('d/m/Y');;
        $this->filter_logs_action();
    }

    public function show_obj($id) {

        $log = Action_log::find($id);
        $objects_array = json_decode($log->object);
        $obj_class = $log->object_class;
        $object = $obj_class::new_from_array((array) $objects_array);

        $this->show = TRUE;
        $this->instance = $object;

        $this->form_content = form_content($this->instance, $this->show);

        //para el cartel de success!
        $success = false;

        $this->class_name = $obj_class::class_display_name();
        echo "<h3>" . $this->class_name . "</h3> <br/>";
        echo $this->form_content;
    }

    public function filter_logs_action() {
        $this->url_back = NULL;
                    
        $this->date_from_to_show = $this->input->post('dateFrom');
        $this->date_to_to_show = $this->input->post('dateTo');
        
        $this->dateFrom = $this->build_date_from($this->input->post('dateFrom'));
        $this->dateTo = $this->build_date_to($this->input->post('dateTo'));

        $is_valid = $this->check_from_to($this->dateFrom, $this->dateTo);
        if (!$is_valid) {
            $this->error_string = true;
            $this->instances = $this->get_instances();

        }else{
            $class = $this->managed_class;
            $this->instances = $class::logs_between($this->dateFrom,$this->dateTo);
        }

        foreach ($this->instances as $row) {
            $class = $row->object_class;
            $row->object_class = $class::class_display_name();

            if (!is_null($row->user_id)) {
                $user = $this->user->find($row->user_id);
                $row->user_id = $user->name;
            } else {
                $row->user_id = 'Desconocido';
            }
        }

        $this->load_view_with_layout($this->edit_view);
    }

    /**
     * Le da el formate a cualquier fecha que venga por parámetro, si viene vacio se setea con la fecha de hoy -30 dias
     * Para from o cualquier fecha
     */
    protected function build_date_from($datepicker_date) {        
        if ($datepicker_date == false || (!$this->validate_date_format($datepicker_date))) {
            $date_epoch = date("Y-m-d H:i:s", mktime(0, 0, 0, date("m"), date("d") - 30, date("Y")));
        } else {
            $date = $datepicker_date;
            $dmy = explode('-', $date);
            $date_epoch = date("Y-m-d H:i:s", mktime(0, 0, 0, $dmy[1], $dmy[0], $dmy[2]));
        }
        return $date_epoch;
    }

    /**
     * Le da el formate a cualquier fecha que venga por parámetro, si viene vacio le asigna la fecha de hoy
     * para to
     */
    protected function build_date_to($datepicker_to) {                
        if ($datepicker_to == false || (!$this->validate_date_format($datepicker_to))) {
            $to_epoch = date("Y-m-d H:i:s", mktime(23, 59, 59, date("m"), date("d"), date("Y")));
        } else {
            $to = $datepicker_to;
            $dmy_to = explode('-', $to);
            //  $to_epoch = mktime(23, 59, 59, $dmy_to[1], $dmy_to[0], $dmy_to[2]);
            $to_epoch = date("Y-m-d H:i:s", mktime(23, 59, 59, $dmy_to[1], $dmy_to[0], $dmy_to[2]));
        }
        return $to_epoch;
    }
    /*
     *validate_date_format
     * funcion que valida el formato de entrada de las fechas, debería estar en el focus base
     * input $date
     * return boolean
     *       */
    protected function validate_date_format($date){
        $new_date = DateTime::createFromFormat('d-m-Y', $date);
        if ($new_date)
            return true;
        else
            return false;
    }

    /**
     * check_from_to($from_epoch,$to_epoch):
     * Se encarga de corroboar que la fecha from sea más grande que el to
     * Hay que pasarle los datos del post ya procesados por mktime, idealmente utilizando las funciones build_date_from/to
     * @author Yuri Zoolander - 2015
     */
    public function check_from_to($from_epoch, $to_epoch) {
        if ($from_epoch > $to_epoch) {
            $this->errors[] = 'La fecha desde debe ser anterior a la hasta.';
            return;
        }
        return true;
    }

    public function form_view_for($class) {
        if (file_exists($this->_views_files_location . $this->form_view . "_" . strtolower($class) . ".php"))
            return $this->form_view . "_" . strtolower($class);
        else
            return $this->form_view;
    }

}
