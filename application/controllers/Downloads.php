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
class Downloads extends Focus_base_controller {
       
   public function __construct() {
        parent::__construct();
        //urls
        $this->url_dowdload_process = $this->url_downloads .'/download_results';
        //views
        $this->main_view = '/donwloads';

   }
   
   
       /**
      * Index de la clase
      */
    public function index($success = FALSE) {
        //$this->url_back = NULL;
       // $class = $this->managed_class;
        $this->instance = new Process_Result;
        
        //para el cartel de success!
        if ($success !== FALSE) {
            switch ($success) {
                case "1": $this->success[] = 'Descarga realizada con éxito';
                    break;
                default:
                    break;
            }
        }
        $this->load_view_with_layout($this->main_view );
    }
   
    /**
      * Index de la clase
      */
    public function download_results() {
        
        $this->instance = Process_Result::find($this->input->post('process_id'));
        $result = $this->instance->donwload_processed_results();

        if ($this->input->post('input_file_format') == 'xls')
            $this->export_to_excel();
        else
            $this->export_to_shp();
        
        //redirect($this->url_downloads . '/1');
    }
    
    public function export_to_excel( )
    {
        $this->load->library('php_excel');

        // $data_xls = $this->export_files_xls->prepare_to_excel($class, $budget_id);

        #En el ultimo elemento del array tengo los nombres de columna
        #y el orden de los campos.
        // $orden = array_pop($data_xls);        

        // $this->php_excel->loadTemplate($templates);
        // $this->php_excel->setActiveSheetIndexByName('datos');

        //Escribir datos de un array, desde que fila, desde que columna
        // $this->php_excel->writeArray(array($orden), 0, 0);

        // $this->php_excel->writeObjects($data_xls, $orden, 1, 0);

        // $this->php_excel->save("output.xlsx");
        
                $templates = APPPATH . "template_temporal_expansion_rules.xlsx";
        $this->load->library('php_excel');

        $data_xls = $this->get_instances();
        
        foreach ($data_xls as $row) {
            $region = Region::find($row->region_id);
            $row->region_id = $region->name;
            $use_declaration = Use_declared::find($row->use_declared_id);
            
            $row->use_declared_id = $use_declaration->name;
            $use_concrete = Use_concret::find($row->use_concrete_id);
            $row->use_concrete_id = $use_concrete->name;
        }
           
//        #En el ultimo elemento del array tengo los nombres de columna
//        #y el orden de los campos.
        $orden = array('region_id', 'use_declared_id', 'use_concrete_id', 'declaration_month', 'month_from','month_to');

        $this->php_excel->loadTemplate($templates);

        //Escribir datos de un array, desde que fila, desde que columna
//
        $this->php_excel->writeObjects($data_xls, $orden, 1, 0);
//
        $this->php_excel->save("output.xlsx");
    }
    
    public function export_to_shp( )
    {
    }   
    
    

}

?>
