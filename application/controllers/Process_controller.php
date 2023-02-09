<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 *    Controller que Amdinistra los Procesos de
 *      Uploads/Downloads
 * @author ARamirez
 * @package Focus
 */
class Process_Controller extends Focus_base_controller {


    /**
     * Variables Publicas
     */
    #En el Caso de necesitas un tipo especifico redeclarar en la Subclase.
    public $extension = 'csv|xls|xlsx';
    #Vista por defecto
    public $_view_uploads = 'uploads/upload_files';
    public $overwrite = FALSE;
    public $upFile;
    public $templates = 'assets/templates/template.xlsx';

    /** Construct * */
    public function __construct(){
        parent::__construct();
        $this->upFile = New R2_Upload_File();
    // Form builder
        $this->load->helper('r2_formbuilder');        
    }


    /* ------------------------------------------------------------ */
    /* ---------- Public Functions  ------------------------------- */
    /* ------------------------------------------------------------ */

    public function index(){
        $this->load_view_with_layout('uploads/upload_files');

    }

    /**
     * Metodo para importar archivos
     * Description: Sube el archivo al server en el path que especiquemos y valida el tipo de dato que estamos  
     * importando Extension
     *
     */
    public function upload_file()
    {
        // Se intenta realizar el upload del archivo.
        $this->upFile->file_import($this->config->item('upload_path'),$this->extension,$this->overwrite);
    }   


    public function export_to_excel( )
    {

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
    }   

}
