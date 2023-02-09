<?php 

/**
* 
*/
class R2_Upload_File extends CI_Model
{
    
    #Variables Publicas
    public $errors;
    function __construct()
    {
        parent::__construct();

        $this->path = $this->config->item('upload_path');
    }

    /**
    * Description: metodo que hace el upload de un archivo
    * requiere el path donde se va almacenar y la extension que permite
    * es una implentacion de Upload de CI
    *
    * @param  $path url de donde se va guardar el archivo
    * @param  $extension permitida en la importacion
    */
    public function file_import($path = NULL, $extension = NULL, $overwrite = false){

        if (!is_null($path) && !is_null($extension)) {
        
            $library_config['upload_path'] = $path;
            $library_config['allowed_types'] = $extension;
            #Cargo la Libreria UPLOAD
            $this->load->library('upload', $library_config);

            // $this->overwrite = $overwrite;
            return $this->upload->do_upload('user_file');
        }
    }

    public function read_import_file(){
        $this->load->library('Php_excel');
        $filename_full_path = $this->upload->data('full_path');
	if(substr($filename_full_path, -4) !== '.xls' && substr($filename_full_path, -5) !== '.xlsx') {
            $this->errors[] = "Solo se aceptan archivos Excel.";
            return;
	}
        $this->data = $this->php_excel->readFile($filename_full_path);              
        
        if (count($this->data[0]) == 1 && $this->data[0][0] == NULL) {
            $this->errors[] = "Archivo vac&iacute;o";
            return;
        }
        
        return $this->data;
    }

    /**
     * Metodo que retorna el arbol del directorio de upload
     *  
     *
     */
    public function read_upload_dir()
    {
        
        return $this->read_folder();
    }


    /**
     * Metodo que retorna el arbol de un dir dentro de uploads
     *  
     *
     */
    public function read_upload_folder($folder = NULL, $exclude_by_extension = true)
    {
        
        return $this->read_folder($folder, $exclude_by_extension);
    }    


    public function read_download_dir()
    {
        $this->download_dir();
    }    


    public function prepare_to_excel($class, $id)
    {
        $this->load->library('php_excel');

        $objrows = $class::all();
        $data_order = array();
        $tmp = array();

        #Necesito decirle que campos no quiero mostar en una instancia previa
        // $tmp = $this->'un array con los campos que no necestito mostrar';

        foreach ($objrows[0] as $key => $value) {
                #quito los campos que no quiero exportar
                if (!in_array($key, $tmp)) {
                    $data_order[] = $key;
                }
        }

        #Le agrego el orden en que quiero mostar los elementos
        $objrows['order'] = $data_order;

        return $objrows;
    }

    /* ------------------------------------------------------------ */
    /* ---------- Protected Metods  ------------------------------- */
    /* ------------------------------------------------------------ */    

    public function read_folder($folder = "", $exclude_by_extension = true){

        $exludes_files = array('dbf','prj','shx','xml','xls','xlsx','qpj','qml','cpg');

        $files = scandir($this->path.$folder);

        $dir = array();

        foreach ($files as $file) {
            if ($exclude_by_extension) {
                $file_ext = $this->get_extension($file);

                if (in_array($file_ext, $exludes_files)) {
                    continue;
                }
            }

            if ($file == '.' || $file == '..' || $file[0] == '.')
                continue;

            if (is_dir($this->path.$folder.$file)) {
                $dir[] = array('name' => $file, 'type' => 'dir');
            }else{
                $dir[] = array('name' => $file, 'type' => 'file');
            }
                
        }

        return $dir;     

    }    

    private function download_dir(){
        return false;   

    }


    /**
     * Extract the file extension
     *
     * @param   string  $filename
     * @return  string
     */
    public function get_extension($filename)
    {
        $x = explode('.', $filename);

        if (count($x) === 1)
            return false;

        $ext = strtolower(end($x));
        return $ext;
    }                

}    
